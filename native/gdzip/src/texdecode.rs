// Decodes the image inside a Godot 3 .stex file, giving the same pixels and
// Image format as StreamTexture's own loader, so it can run on all cores at
// once. Two kinds:
//
// - png (what char loader's cache writes): Godot uses libpng's simplified
//   API (PNGDriverCommon::png_to_image). Only taken for a single 8-bit (or
//   palette) png with no gamma correction to apply.
// - lossless webp (what the Godot editor writes): Godot uses libwebp
//   (_webp_lossy_unpack, despite the name). Lossless webp decodes to exact
//   pixels by definition; Godot picks RGBA8 or RGB8 from the header's alpha
//   bit. Lossy and extended (VP8X) webp are left alone.
//
// Header sizes have to match the image. Anything else returns None and the
// caller lets Godot load it as usual.

use std::ops::Range;

const PNG_BIT: u32 = 1 << 20;
const WEBP_BIT: u32 = 1 << 21;

// Image::Format values in Godot 3.5
const FORMAT_L8: i64 = 0;
const FORMAT_LA8: i64 = 1;
const FORMAT_RGB8: i64 = 4;
const FORMAT_RGBA8: i64 = 5;

// Image::MAX_WIDTH / MAX_HEIGHT in Godot 3.5
const MAX_SIZE: u32 = 16384;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Kind {
    Png,
    WebpLossless,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Plan {
    pub kind: Kind,
    pub width: u32,
    pub height: u32,
    /// Godot Image::Format of the decoded pixels.
    pub format: i64,
    /// Texture flags from the .stex header.
    pub flags: u32,
    /// Where the png / webp file is inside the .stex.
    pub data: Range<usize>,
    /// Size of the decoded pixels in bytes.
    pub out_len: usize,
}

fn u16_at(b: &[u8], i: usize) -> u32 {
    u16::from_le_bytes([b[i], b[i + 1]]) as u32
}

fn u32_at(b: &[u8], i: usize) -> u32 {
    u32::from_le_bytes([b[i], b[i + 1], b[i + 2], b[i + 3]])
}

fn decoder(png: &[u8]) -> png::Decoder<&[u8]> {
    let mut d = png::Decoder::new(png);
    // palette -> RGB(A), tRNS -> alpha, like the simplified libpng API
    d.set_transformations(png::Transformations::EXPAND);
    // libpng rejects bad checksums; don't decode anything it wouldn't
    d.ignore_checksums(false);
    d
}

/// Reads the .stex header and the png header. Cheap; no pixels decoded.
pub fn plan(stex: &[u8]) -> Option<Plan> {
    if stex.len() < 32 || &stex[0..4] != b"GDST" {
        return None;
    }
    let (tw, tw_custom, th, th_custom) = (u16_at(stex, 4), u16_at(stex, 6), u16_at(stex, 8), u16_at(stex, 10));
    let flags = u32_at(stex, 12);
    let data_format = u32_at(stex, 16);
    let mipmaps = u32_at(stex, 20);
    let size = u32_at(stex, 24) as usize;
    // a size override changes the reported size; leave those to Godot
    if mipmaps != 1 || tw_custom != 0 || th_custom != 0 {
        return None;
    }
    let data = 32..stex.len().min(28 + size).max(32);
    match (data_format & PNG_BIT != 0, data_format & WEBP_BIT != 0, &stex[28..32]) {
        (true, false, b"PNG ") => plan_png(stex, data, tw, th, flags),
        (false, true, b"WEBP") => plan_webp(stex, data, tw, th, flags),
        _ => None,
    }
}

fn plan_webp(stex: &[u8], data: Range<usize>, tw: u32, th: u32, flags: u32) -> Option<Plan> {
    let webp = &stex[data.clone()];
    // simple lossless file: RIFF <size> WEBP VP8L <size> 0x2f <14 bit w-1, 14 bit h-1, alpha bit, 3 bit version>
    if webp.len() < 25 || &webp[0..4] != b"RIFF" || &webp[8..16] != b"WEBPVP8L" || webp[20] != 0x2f {
        return None;
    }
    if u32_at(webp, 4) as usize + 8 > webp.len() {
        return None;
    }
    let header = u32_at(webp, 21);
    let width = (header & 0x3FFF) + 1;
    let height = ((header >> 14) & 0x3FFF) + 1;
    let alpha = header >> 28 & 1 != 0;
    if header >> 29 != 0 || width != tw || height != th || width > MAX_SIZE || height > MAX_SIZE {
        return None;
    }
    let (format, channels) = if alpha { (FORMAT_RGBA8, 4) } else { (FORMAT_RGB8, 3) };
    Some(Plan {
        kind: Kind::WebpLossless,
        width,
        height,
        format,
        flags,
        data,
        out_len: width as usize * height as usize * channels,
    })
}

fn plan_png(stex: &[u8], png: Range<usize>, tw: u32, th: u32, flags: u32) -> Option<Plan> {
    let reader = decoder(&stex[png.clone()]).read_info().ok()?;
    let info = reader.info();
    let (width, height) = (info.width, info.height);
    if width != tw || height != th || width > MAX_SIZE || height > MAX_SIZE {
        return None;
    }

    use png::{BitDepth, ColorType};
    let has_trns = info.trns.is_some();
    let format = match (info.color_type, info.bit_depth) {
        (ColorType::Indexed, _) => {
            if has_trns {
                FORMAT_RGBA8
            } else {
                FORMAT_RGB8
            }
        }
        (ColorType::Grayscale, BitDepth::Eight) => {
            if has_trns {
                FORMAT_LA8
            } else {
                FORMAT_L8
            }
        }
        (ColorType::Rgb, BitDepth::Eight) => {
            if has_trns {
                FORMAT_RGBA8
            } else {
                FORMAT_RGB8
            }
        }
        (ColorType::GrayscaleAlpha, BitDepth::Eight) => FORMAT_LA8,
        (ColorType::Rgba, BitDepth::Eight) => FORMAT_RGBA8,
        // 16-bit and 1/2/4-bit gray get converted by libpng; not worth matching
        _ => return None,
    };

    // libpng converts to sRGB unless the file already is; only take files
    // that already are (no gamma info means sRGB to libpng too)
    if info.srgb.is_none() {
        if info.icc_profile.is_some() {
            return None;
        }
        if let Some(g) = info.source_gamma {
            if !(45454..=45456).contains(&g.into_scaled()) {
                return None;
            }
        }
    }

    let out_len = reader.output_buffer_size();
    let channels = match format {
        FORMAT_L8 => 1,
        FORMAT_LA8 => 2,
        FORMAT_RGB8 => 3,
        _ => 4,
    };
    if out_len != width as usize * height as usize * channels {
        return None;
    }
    Some(Plan { kind: Kind::Png, width, height, format, flags, data: png, out_len })
}

/// Decodes the image into `out` (exactly `Plan::out_len` bytes).
pub fn decode_into(kind: Kind, data: &[u8], out: &mut [u8]) -> bool {
    match kind {
        Kind::Png => decode_png(data, out),
        Kind::WebpLossless => decode_webp(data, out),
    }
}

fn decode_webp(webp: &[u8], out: &mut [u8]) -> bool {
    let Ok(mut d) = image_webp::WebPDecoder::new(std::io::Cursor::new(webp)) else {
        return false;
    };
    if d.is_lossy() || d.is_animated() || d.output_buffer_size() != Some(out.len()) {
        return false;
    }
    d.read_image(out).is_ok()
}

fn decode_png(png: &[u8], out: &mut [u8]) -> bool {
    let Ok(mut reader) = decoder(png).read_info() else {
        return false;
    };
    if reader.output_buffer_size() != out.len() {
        return false;
    }
    reader.next_frame(out).is_ok()
}

/// Runs `job(i)` for every i in 0..n across all cores.
pub fn parallel_for(n: usize, job: impl Fn(usize) + Sync) {
    use std::sync::atomic::{AtomicUsize, Ordering};
    let next = AtomicUsize::new(0);
    let threads = std::thread::available_parallelism().map_or(1, |t| t.get()).min(n.max(1));
    std::thread::scope(|s| {
        for _ in 0..threads {
            s.spawn(|| loop {
                let i = next.fetch_add(1, Ordering::Relaxed);
                if i >= n {
                    break;
                }
                job(i);
            });
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    fn stex_for(png: &[u8], w: u32, h: u32) -> Vec<u8> {
        let mut s = b"GDST".to_vec();
        s.extend_from_slice(&w.to_le_bytes());
        s.extend_from_slice(&h.to_le_bytes());
        s.extend_from_slice(&0u32.to_le_bytes());
        s.extend_from_slice(&0x0710_0000u32.to_le_bytes());
        s.extend_from_slice(&1u32.to_le_bytes());
        s.extend_from_slice(&(png.len() as u32 + 6).to_le_bytes());
        s.extend_from_slice(b"PNG ");
        s.extend_from_slice(png);
        s
    }

    fn encode(w: u32, h: u32, color: png::ColorType, depth: png::BitDepth, data: &[u8], gamma: Option<u32>) -> Vec<u8> {
        let mut out = Vec::new();
        {
            let mut e = png::Encoder::new(&mut out, w, h);
            e.set_color(color);
            e.set_depth(depth);
            if let Some(g) = gamma {
                e.set_source_gamma(png::ScaledFloat::from_scaled(g));
            }
            let mut wr = e.write_header().unwrap();
            wr.write_image_data(data).unwrap();
        }
        out
    }

    #[test]
    fn rgba_roundtrip() {
        let data: Vec<u8> = (0..4 * 7 * 5).map(|i| i as u8).collect();
        let png = encode(7, 5, png::ColorType::Rgba, png::BitDepth::Eight, &data, None);
        let stex = stex_for(&png, 7, 5);
        let p = plan(&stex).unwrap();
        assert_eq!((p.width, p.height, p.format, p.out_len), (7, 5, FORMAT_RGBA8, data.len()));
        let mut out = vec![0; p.out_len];
        assert!(decode_into(p.kind, &stex[p.data.clone()], &mut out));
        assert_eq!(out, data);
    }

    #[test]
    fn rejects_what_godot_would_convert() {
        let px16 = vec![0u8; 2 * 3 * 4 * 4];
        let png16 = encode(4, 4, png::ColorType::Rgb, png::BitDepth::Sixteen, &px16, None);
        assert!(plan(&stex_for(&png16, 4, 4)).is_none());
        let px = vec![0u8; 3 * 4 * 4];
        let linear = encode(4, 4, png::ColorType::Rgb, png::BitDepth::Eight, &px, Some(100000));
        assert!(plan(&stex_for(&linear, 4, 4)).is_none());
        let srgb_gamma = encode(4, 4, png::ColorType::Rgb, png::BitDepth::Eight, &px, Some(45455));
        assert!(plan(&stex_for(&srgb_gamma, 4, 4)).is_some());
        // header size not matching the png
        let ok = encode(4, 4, png::ColorType::Rgb, png::BitDepth::Eight, &px, None);
        assert!(plan(&stex_for(&ok, 5, 4)).is_none());
    }

    fn webp_stex(w: u32, h: u32, data: &[u8], color: image_webp::ColorType) -> Vec<u8> {
        let mut webp = Vec::new();
        image_webp::WebPEncoder::new(&mut webp).encode(data, w, h, color).unwrap();
        let mut s = b"GDST".to_vec();
        s.extend_from_slice(&w.to_le_bytes());
        s.extend_from_slice(&h.to_le_bytes());
        s.extend_from_slice(&4u32.to_le_bytes());
        s.extend_from_slice(&0x0720_0000u32.to_le_bytes());
        s.extend_from_slice(&1u32.to_le_bytes());
        s.extend_from_slice(&(webp.len() as u32 + 4).to_le_bytes());
        s.extend_from_slice(b"WEBP");
        s.extend_from_slice(&webp);
        s
    }

    #[test]
    fn webp_lossless_roundtrip() {
        let rgba: Vec<u8> = (0..4 * 9 * 6).map(|i| (i * 7) as u8).collect();
        let stex = webp_stex(9, 6, &rgba, image_webp::ColorType::Rgba8);
        let p = plan(&stex).unwrap();
        assert_eq!((p.kind, p.format, p.flags, p.out_len), (Kind::WebpLossless, FORMAT_RGBA8, 4, rgba.len()));
        let mut out = vec![0; p.out_len];
        assert!(decode_into(p.kind, &stex[p.data.clone()], &mut out));
        assert_eq!(out, rgba);

        let rgb: Vec<u8> = (0..3 * 5 * 5).map(|i| (i * 11) as u8).collect();
        let stex = webp_stex(5, 5, &rgb, image_webp::ColorType::Rgb8);
        let p = plan(&stex).unwrap();
        assert_eq!((p.format, p.out_len), (FORMAT_RGB8, rgb.len()));
        let mut out = vec![0; p.out_len];
        assert!(decode_into(p.kind, &stex[p.data.clone()], &mut out));
        assert_eq!(out, rgb);
    }

    #[test]
    fn rejects_bad_checksum() {
        let px = vec![7u8; 3 * 16 * 16];
        let mut png = encode(16, 16, png::ColorType::Rgb, png::BitDepth::Eight, &px, None);
        let idat = png.windows(4).position(|w| w == b"IDAT").unwrap();
        png[idat + 6] ^= 0xFF;
        let stex = stex_for(&png, 16, 16);
        if let Some(p) = plan(&stex) {
            let mut out = vec![0; p.out_len];
            assert!(!decode_into(p.kind, &stex[p.data.clone()], &mut out));
        }
    }
}
