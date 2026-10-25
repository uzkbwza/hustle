// Godot 3.5.1's WAV importer (editor/import/resource_importer_wav.cpp),
// ported so char loader can turn a mod's .wav into the same AudioStreamSample
// the editor would have made from it, with that file's own import options.
//
// Kept as close to the C++ as possible, including its float/double math and
// its quirks (no RIFF chunk padding, 24/32-bit PCM cut to 16 bits, trim only
// when looping). Returns Err wherever the editor's importer fails.

pub const FORMAT_8_BITS: i64 = 0;
pub const FORMAT_16_BITS: i64 = 1;
pub const FORMAT_IMA_ADPCM: i64 = 2;

// AudioStreamSample::LoopMode
const LOOP_DISABLED: i64 = 0;
const LOOP_FORWARD: i64 = 1;
const LOOP_PING_PONG: i64 = 2;
const LOOP_BACKWARD: i64 = 3;

const TRIM_DB_LIMIT: f32 = -50.0;
const TRIM_FADE_OUT_FRAMES: i32 = 500;

/// The importer's options, defaults as in ResourceImporterWAV::get_import_options.
#[derive(Debug, Clone)]
pub struct WavOptions {
    pub force_8_bit: bool,
    pub force_mono: bool,
    pub force_max_rate: bool,
    pub force_max_rate_hz: i32,
    pub edit_trim: bool,
    pub edit_normalize: bool,
    pub edit_loop_mode: i64,
    pub edit_loop_begin: i32,
    pub edit_loop_end: i32,
    pub compress_mode: i64,
}

impl Default for WavOptions {
    fn default() -> Self {
        WavOptions {
            force_8_bit: false,
            force_mono: false,
            force_max_rate: false,
            force_max_rate_hz: 44100,
            edit_trim: false,
            edit_normalize: false,
            edit_loop_mode: 0,
            edit_loop_begin: 0,
            edit_loop_end: -1,
            compress_mode: 0,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct Sample {
    pub data: Vec<u8>,
    pub format: i64,
    pub mix_rate: i32,
    pub loop_mode: i64,
    pub loop_begin: i32,
    pub loop_end: i32,
    pub stereo: bool,
}

/// Reads like Godot's FileAccess: reading past the end gives zeros and sets
/// eof, seeking clears it.
struct Reader<'a> {
    b: &'a [u8],
    pos: u64,
    eof: bool,
}

impl Reader<'_> {
    fn get_8(&mut self) -> u8 {
        match self.b.get(self.pos as usize) {
            Some(&v) if self.pos < self.b.len() as u64 => {
                self.pos += 1;
                v
            }
            _ => {
                self.eof = true;
                0
            }
        }
    }
    fn get_16(&mut self) -> u16 {
        let a = self.get_8() as u16;
        let b = self.get_8() as u16;
        a | b << 8
    }
    fn get_32(&mut self) -> u32 {
        let a = self.get_16() as u32;
        let b = self.get_16() as u32;
        a | b << 16
    }
    fn get_64(&mut self) -> u64 {
        let a = self.get_32() as u64;
        let b = self.get_32() as u64;
        a | b << 32
    }
    fn get_buffer4(&mut self) -> [u8; 4] {
        // get_buffer reads what's there; a short read sets eof
        let mut out = [0u8; 4];
        for o in out.iter_mut() {
            if (self.pos as usize) < self.b.len() {
                *o = self.b[self.pos as usize];
                self.pos += 1;
            } else {
                self.eof = true;
                break;
            }
        }
        out
    }
    fn seek(&mut self, p: u64) {
        self.pos = p;
        self.eof = false;
    }
}

pub fn import_wav(bytes: &[u8], o: &WavOptions) -> Result<Sample, &'static str> {
    // STEP 1, READ WAVE FILE
    let mut file = Reader { b: bytes, pos: 0, eof: false };
    if &file.get_buffer4() != b"RIFF" {
        return Err("not RIFF");
    }
    file.get_32();
    if &file.get_buffer4() != b"WAVE" {
        return Err("not WAVE");
    }

    let import_loop_mode = o.edit_loop_mode;
    let mut format_bits: i32 = 0;
    let mut format_channels: i32 = 0;
    let mut loop_mode = LOOP_DISABLED;
    let mut compression_code: u16 = 1;
    let mut format_found = false;
    let mut data_found = false;
    let mut format_freq: i32 = 0;
    let mut loop_begin: i32 = 0;
    let mut loop_end: i32 = 0;
    let mut frames: i32 = 0;
    let mut data: Vec<f32> = Vec::new();

    while !file.eof {
        let chunk_id = file.get_buffer4();
        let chunksize = file.get_32();
        let file_pos = file.pos as u32;
        if file.eof {
            break;
        }

        if &chunk_id == b"fmt " && !format_found {
            compression_code = file.get_16();
            if compression_code != 1 && compression_code != 3 {
                return Err("not PCM or float");
            }
            format_channels = file.get_16() as i32;
            if format_channels != 1 && format_channels != 2 {
                return Err("not mono or stereo");
            }
            format_freq = file.get_32() as i32;
            file.get_32();
            file.get_16();
            format_bits = file.get_16() as i32;
            if format_bits % 8 != 0 || format_bits == 0 {
                return Err("bad bits");
            }
            if compression_code == 3 && format_bits % 32 != 0 {
                return Err("bad float bits");
            }
            // past 32 bits the C++ shifts by negative amounts (undefined)
            if compression_code == 1 && format_bits > 32 {
                return Err("PCM over 32 bits");
            }
            format_found = true;
        }

        if &chunk_id == b"data" && !data_found {
            data_found = true;
            if !format_found {
                // ERR_PRINT + break: carries on with no data
                break;
            }
            frames = chunksize as i32;
            frames /= format_channels;
            frames /= format_bits >> 3;
            let n = (frames * format_channels).max(0) as usize;
            data = Vec::with_capacity(n);
            if compression_code == 1 {
                if format_bits == 8 {
                    for _ in 0..n {
                        data.push(((file.get_8() as i32 - 128) as i8) as f32 / 128.0);
                    }
                } else if format_bits == 16 {
                    for _ in 0..n {
                        data.push(file.get_16() as i16 as f32 / 32768.0);
                    }
                } else {
                    for _ in 0..n {
                        let mut s: u32 = 0;
                        for b in 0..(format_bits >> 3) {
                            s |= (file.get_8() as u32).wrapping_shl((b * 8) as u32);
                        }
                        s = s.wrapping_shl((32 - format_bits) as u32);
                        data.push(((s as i32) >> 16) as f32 / 32768.0);
                    }
                }
            } else if format_bits == 32 {
                for _ in 0..n {
                    data.push(f32::from_bits(file.get_32()));
                }
            } else if format_bits == 64 {
                for _ in 0..n {
                    data.push(f64::from_bits(file.get_64()) as f32);
                }
            } else {
                // float with another size of multiple of 32: the C++ leaves
                // the resized vector unwritten
                return Err("float bits not 32/64");
            }
            if file.eof {
                return Err("premature end of file");
            }
        }

        if import_loop_mode == 0 && &chunk_id == b"smpl" {
            for _ in 0..10 {
                file.get_32();
            }
            let loop_type = file.get_32();
            if loop_type <= 2 {
                loop_mode = match loop_type {
                    0 => LOOP_FORWARD,
                    1 => LOOP_PING_PONG,
                    _ => LOOP_BACKWARD,
                };
                loop_begin = file.get_32() as i32;
                loop_end = file.get_32() as i32;
            }
        }
        file.seek(file_pos as u64 + chunksize as u64);
    }

    // STEP 2, APPLY CONVERSIONS
    let mut is16 = format_bits != 8;
    let mut rate = format_freq;

    let limit_rate_hz = o.force_max_rate_hz;
    if o.force_max_rate && rate > limit_rate_hz && rate > 0 && frames > 0 {
        // (int)(frames * (float)limit_rate_hz / (float)rate), left to right
        let new_data_frames = ((frames as f32 * limit_rate_hz as f32) / rate as f32) as i32;
        let ch = format_channels as usize;
        let mut new_data = vec![0f32; new_data_frames.max(0) as usize * ch];
        for c in 0..ch {
            let mut frac: f32 = 0.0;
            let mut ipos: i32 = 0;
            for i in 0..new_data_frames.max(0) as usize {
                let mu = frac;
                // the C++ would read past the end here; never seen, but don't guess
                let at = |p: i32| data.get(p as usize * ch + c).copied().ok_or("resample out of range");
                let y0 = at((ipos - 1).max(0))?;
                let y1 = at(ipos)?;
                let y2 = at((frames - 1).min(ipos + 1))?;
                let y3 = at((frames - 1).min(ipos + 2))?;
                let mu2 = mu * mu;
                let a0 = y3 - y2 - y0 + y1;
                let a1 = y0 - y1 - a0;
                let a2 = y2 - y0;
                let a3 = y1;
                let res = a0 * mu * mu2 + a1 * mu2 + a2 * mu + a3;
                new_data[i * ch + c] = res;
                frac += rate as f32 / limit_rate_hz as f32;
                let tpos = frac.floor() as i32;
                ipos += tpos;
                frac -= tpos as f32;
            }
        }
        if loop_mode != LOOP_DISABLED {
            loop_begin = (loop_begin as f32 * new_data_frames as f32 / frames as f32) as i32;
            loop_end = (loop_end as f32 * new_data_frames as f32 / frames as f32) as i32;
        }
        data = new_data;
        rate = limit_rate_hz;
        frames = new_data_frames;
    }

    if o.edit_normalize {
        let mut max: f32 = 0.0;
        for &v in &data {
            let amp = v.abs();
            if amp > max {
                max = amp;
            }
        }
        if max > 0.0 {
            let mult = (1.0f64 / max as f64) as f32;
            for v in data.iter_mut() {
                *v *= mult;
            }
        }
    }

    if o.edit_trim && loop_mode != LOOP_DISABLED && format_channels > 0 {
        let ch = format_channels as usize;
        let mut first: i32 = 0;
        let mut last: i32 = (frames / format_channels) - 1;
        let mut found = false;
        let limit = (TRIM_DB_LIMIT * 0.115_129_254_649_702_28_f32).exp();
        for i in 0..data.len() / ch {
            let mut amp_channel_sum: f32 = 0.0;
            for j in 0..ch {
                amp_channel_sum += data[i * ch + j].abs();
            }
            let amp = (amp_channel_sum / format_channels as f32).abs();
            if !found && amp > limit {
                first = i as i32;
                found = true;
            }
            if found && amp > limit {
                last = i as i32;
            }
        }
        if first < last {
            let mut new_data = vec![0f32; (last - first) as usize * ch];
            for i in first..last {
                let mut fade_out_mult: f32 = 1.0;
                if last - i < TRIM_FADE_OUT_FRAMES {
                    fade_out_mult = (last - i - 1) as f32 / TRIM_FADE_OUT_FRAMES as f32;
                }
                for j in 0..ch {
                    new_data[(i - first) as usize * ch + j] = data[i as usize * ch + j] * fade_out_mult;
                }
            }
            data = new_data;
            frames = (data.len() / ch) as i32;
        }
    }

    if import_loop_mode >= 2 {
        loop_mode = import_loop_mode - 1;
        loop_begin = o.edit_loop_begin;
        loop_end = o.edit_loop_end;
        if loop_begin < 0 {
            loop_begin = (loop_begin + frames + 1).clamp(0, frames.max(0));
        }
        if loop_end < 0 {
            loop_end = (loop_end + frames + 1).clamp(0, frames.max(0));
        }
    }

    if o.force_mono && format_channels == 2 {
        let mut new_data = vec![0f32; data.len() / 2];
        if frames.max(0) as usize > new_data.len() {
            return Err("mono out of range");
        }
        for i in 0..frames.max(0) as usize {
            new_data[i] = ((data[i * 2] + data[i * 2 + 1]) as f64 / 2.0) as f32;
        }
        data = new_data;
        format_channels = 1;
    }

    if o.force_8_bit {
        is16 = false;
    }

    let (dst_format, dst_data) = if o.compress_mode == 1 {
        if format_channels == 1 {
            (FORMAT_IMA_ADPCM, compress_ima_adpcm(&data))
        } else {
            let tframes = data.len() / 2;
            let left: Vec<f32> = (0..tframes).map(|i| data[i * 2]).collect();
            let right: Vec<f32> = (0..tframes).map(|i| data[i * 2 + 1]).collect();
            let bl = compress_ima_adpcm(&left);
            let br = compress_ima_adpcm(&right);
            let mut out = vec![0u8; bl.len() * 2];
            for i in 0..bl.len() {
                out[i * 2] = bl[i];
                out[i * 2 + 1] = br[i];
            }
            (FORMAT_IMA_ADPCM, out)
        }
    } else if is16 {
        let mut out = Vec::with_capacity(data.len() * 2);
        for &v in &data {
            let s = clamp_f32(v * 32768.0, -32768.0, 32767.0) as i32 as i16;
            out.extend_from_slice(&s.to_le_bytes());
        }
        (FORMAT_16_BITS, out)
    } else {
        let out = data
            .iter()
            .map(|&v| clamp_f32(v * 128.0, -128.0, 127.0) as i32 as i8 as u8)
            .collect();
        (FORMAT_8_BITS, out)
    };

    Ok(Sample {
        data: dst_data,
        format: dst_format,
        mix_rate: rate,
        loop_mode,
        loop_begin,
        loop_end,
        stereo: format_channels == 2,
    })
}

// CLAMP(a, min, max): (a < min ? min : (a > max ? max : a)); NaN falls through
fn clamp_f32(a: f32, min: f32, max: f32) -> f32 {
    if a < min {
        min
    } else if a > max {
        max
    } else {
        a
    }
}

fn clamp_f64(a: f64, min: f64, max: f64) -> f64 {
    if a < min {
        min
    } else if a > max {
        max
    } else {
        a
    }
}

const IMA_STEP: [i32; 89] = [
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97,
    107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658, 724,
    796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026,
    4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818, 18500,
    20350, 22385, 24623, 27086, 29794, 32767,
];
const IMA_INDEX: [i32; 16] = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8];

fn compress_ima_adpcm(input: &[f32]) -> Vec<u8> {
    let datamax = input.len();
    let mut datalen = datamax;
    if datalen & 1 != 0 {
        datalen += 1;
    }
    let mut out = vec![0u8; datalen / 2 + 4];
    let mut o = 4;
    let (mut step_idx, mut prev): (i32, i32) = (0, 0);
    for i in 0..datalen {
        let xm_sample: i16 = if i >= datamax {
            0
        } else {
            // in[i] * 32767.0 is a double multiply in the C++
            clamp_f64(input[i] as f64 * 32767.0, -32768.0, 32767.0) as i32 as i16
        };
        let mut diff = xm_sample as i32 - prev;
        let mut nibble: u8 = 0;
        let mut step = IMA_STEP[step_idx as usize];
        let mut vpdiff = step >> 3;
        if diff < 0 {
            nibble = 8;
            diff = -diff;
        }
        let mut mask = 4u8;
        while mask != 0 {
            if diff >= step {
                nibble |= mask;
                diff -= step;
                vpdiff += step;
            }
            step >>= 1;
            mask >>= 1;
        }
        if nibble & 8 != 0 {
            prev -= vpdiff;
        } else {
            prev += vpdiff;
        }
        prev = prev.clamp(-32768, 32767);
        step_idx = (step_idx + IMA_INDEX[nibble as usize]).clamp(0, 88);
        if i & 1 != 0 {
            out[o] |= nibble << 4;
            o += 1;
        } else {
            out[o] = nibble;
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn wav(channels: u16, rate: u32, bits: u16, code: u16, data: &[u8], extra: &[u8]) -> Vec<u8> {
        let mut fmt = Vec::new();
        fmt.extend_from_slice(&code.to_le_bytes());
        fmt.extend_from_slice(&channels.to_le_bytes());
        fmt.extend_from_slice(&rate.to_le_bytes());
        fmt.extend_from_slice(&(rate * channels as u32 * bits as u32 / 8).to_le_bytes());
        fmt.extend_from_slice(&(channels * bits / 8).to_le_bytes());
        fmt.extend_from_slice(&bits.to_le_bytes());
        let mut body = b"WAVE".to_vec();
        body.extend_from_slice(b"fmt ");
        body.extend_from_slice(&(fmt.len() as u32).to_le_bytes());
        body.extend_from_slice(&fmt);
        body.extend_from_slice(extra);
        body.extend_from_slice(b"data");
        body.extend_from_slice(&(data.len() as u32).to_le_bytes());
        body.extend_from_slice(data);
        let mut out = b"RIFF".to_vec();
        out.extend_from_slice(&(body.len() as u32).to_le_bytes());
        out.extend_from_slice(&body);
        out
    }

    #[test]
    fn pcm16_passes_through() {
        let samples: Vec<i16> = vec![0, 1, -1, 32767, -32768, 1234, -4321, 7];
        let bytes: Vec<u8> = samples.iter().flat_map(|s| s.to_le_bytes()).collect();
        let s = import_wav(&wav(2, 48000, 16, 1, &bytes, &[]), &WavOptions::default()).unwrap();
        assert_eq!((s.format, s.mix_rate, s.stereo, s.loop_mode), (FORMAT_16_BITS, 48000, true, LOOP_DISABLED));
        assert_eq!(s.data, bytes);
    }

    #[test]
    fn rejects_what_the_editor_rejects() {
        assert!(import_wav(&wav(1, 44100, 16, 0xFFFE, &[0, 0], &[]), &WavOptions::default()).is_err());
        assert!(import_wav(&wav(3, 44100, 16, 1, &[0; 6], &[]), &WavOptions::default()).is_err());
        assert!(import_wav(b"not a wav at all", &WavOptions::default()).is_err());
    }

    #[test]
    fn options_run() {
        let bytes: Vec<u8> = (0..4000i32).flat_map(|i| (((i * 37) % 2000 - 1000) as i16 * 9).to_le_bytes()).collect();
        let w = wav(2, 96000, 16, 1, &bytes, &[]);
        let o = WavOptions {
            force_max_rate: true,
            force_mono: true,
            edit_normalize: true,
            compress_mode: 1,
            edit_loop_mode: 2,
            ..Default::default()
        };
        let s = import_wav(&w, &o).unwrap();
        assert_eq!((s.format, s.mix_rate, s.stereo, s.loop_mode), (FORMAT_IMA_ADPCM, 44100, false, LOOP_FORWARD));
    }
}
