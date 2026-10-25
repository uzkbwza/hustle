// Pure zip logic, no Godot types, so it can be tested with plain `cargo test`.
//
// The reader half mirrors modloader/gdunzip/gdunzip_gdscript.gd (the original
// GDScript gdunzip). It only handles the cases where it is certain to produce
// exactly what the GDScript code would. Anything else (corrupt archives,
// truncated records, odd deflate streams, anything that would make the GDScript
// version hit an out-of-bounds script error) is reported as `Fallback`, and the
// GDScript wrapper then runs the original code on the full file instead.

use std::ops::Range;

const EOCD_SIG: [u8; 4] = [0x50, 0x4B, 0x05, 0x06];
const CD_SIG: [u8; 4] = [0x50, 0x4B, 0x01, 0x02];
const LOCAL_SIG: u32 = 0x04034B50;

/// Size of the end-of-central-directory record without its comment.
pub const EOCD_LEN: u64 = 22;
/// How far from the end of the file the EOCD record can be (max comment is 65535 bytes).
pub const MAX_EOCD_SEARCH: u64 = EOCD_LEN + 0xFFFF;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Entry {
    /// gdunzip stores -1 when method bytes are both zero, File.COMPRESSION_DEFLATE (1) otherwise.
    pub stored: bool,
    /// Range of the raw file name bytes inside the `data` slice given to the parser.
    pub name: Range<usize>,
    pub compressed_size: u32,
    pub uncompressed_size: u32,
    pub file_header_offset: u32,
}

#[derive(Debug, PartialEq, Eq)]
pub enum Parse {
    /// Every central directory record parsed cleanly. `end_pos` is where gdunzip's `pos` ends up.
    Ok { entries: Vec<Entry>, end_pos: u64 },
    /// Call again with the file read starting from this offset.
    NeedFrom(u64),
    /// Not a case we can mirror exactly; run the GDScript implementation.
    Fallback,
}

fn u16_at(b: &[u8], i: usize) -> u64 {
    b[i] as u64 | (b[i + 1] as u64) << 8
}

fn u32_at(b: &[u8], i: usize) -> u32 {
    u32::from_le_bytes([b[i], b[i + 1], b[i + 2], b[i + 3]])
}

/// Mirrors gdunzip `_get_files()`.
///
/// `data` holds the bytes of the file from `data_start` up to `file_len` (the end of the file).
pub fn parse_central_directory(data: &[u8], data_start: u64, file_len: u64) -> Parse {
    if data_start + data.len() as u64 != file_len || file_len < EOCD_LEN {
        return Parse::Fallback;
    }
    let at = |off: u64| (off - data_start) as usize;

    // gdunzip scans backwards from size - 22 while offset > 0. It never checks
    // offset 0 itself and uses 0 if nothing matched.
    let mut eocd = None;
    let mut off = file_len - EOCD_LEN;
    while off > 0 {
        if off < data_start {
            return Parse::NeedFrom(0);
        }
        if data[at(off)..at(off) + 4] == EOCD_SIG {
            eocd = Some(off);
            break;
        }
        off -= 1;
    }
    let eocd = match eocd {
        Some(o) => o,
        None if data_start > 0 => return Parse::NeedFrom(0),
        None => 0,
    };

    let cd_offset = u32_at(data, at(eocd) + 16) as u64;
    if cd_offset < data_start {
        return Parse::NeedFrom(cd_offset);
    }

    let mut entries = Vec::new();
    let mut pos = cd_offset;
    loop {
        // gdunzip reads buffer[pos + 3] first; out of range there is a script error.
        if pos + 3 >= file_len {
            return Parse::Fallback;
        }
        if data[at(pos)..at(pos) + 4] != CD_SIG {
            break;
        }
        if pos + 46 > file_len {
            return Parse::Fallback;
        }
        let raw = &data[at(pos)..at(pos) + 46];
        let name_len = u16_at(raw, 28);
        let extra_len = u16_at(raw, 30);
        let comment_len = u16_at(raw, 32);
        let tail_len = name_len + extra_len + comment_len;
        // A zero-length tail makes gdunzip return false, and a zero-length name
        // makes it use the whole tail as the name. Leave both to the GDScript code.
        if name_len == 0 || pos + 46 + tail_len > file_len {
            return Parse::Fallback;
        }
        let name_start = at(pos) + 46;
        entries.push(Entry {
            stored: raw[10] == 0 && raw[11] == 0,
            name: name_start..name_start + name_len as usize,
            compressed_size: u32_at(raw, 20),
            uncompressed_size: u32_at(raw, 24),
            file_header_offset: u32_at(raw, 42),
        });
        pos += 46 + tail_len;
    }
    Parse::Ok { entries, end_pos: pos }
}

/// Inflates a raw deflate stream the way gdunzip's Tinf port would, or returns
/// None when the result might differ (anything other than a well-formed stream
/// that uses exactly every input byte and fills exactly `out_len` bytes).
pub fn inflate_exact(src: &[u8], out_len: usize) -> Option<Vec<u8>> {
    use miniz_oxide::inflate::core::{decompress, inflate_flags, DecompressorOxide};
    use miniz_oxide::inflate::TINFLStatus;

    let mut out = vec![0u8; out_len];
    let mut state = Box::<DecompressorOxide>::default();
    let (status, consumed, written) = decompress(
        &mut state,
        src,
        &mut out,
        0,
        inflate_flags::TINFL_FLAG_USING_NON_WRAPPING_OUTPUT_BUF,
    );
    if status == TINFLStatus::Done && consumed == src.len() && written == out_len {
        Some(out)
    } else {
        None
    }
}

// ---------------------------------------------------------------------------
// Writer
// ---------------------------------------------------------------------------

/// Builds a zip archive one entry at a time. Each `add` returns the bytes to
/// append to the output file; `finish` returns the central directory.
///
/// Output is deterministic: every entry gets the same fixed timestamp
/// (1980-01-01 00:00), so the same input always gives the same bytes.
#[derive(Default)]
pub struct ZipBuilder {
    central: Vec<u8>,
    count: u64,
    offset: u64,
    finished: bool,
}

const DOS_TIME: u16 = 0;
const DOS_DATE: u16 = (1 << 5) | 1; // 1980-01-01
const VERSION: u16 = 20;
const FLAG_UTF8: u16 = 1 << 11;

impl ZipBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    /// `level` 0 stores the data, 1-10 deflates it (stored anyway if deflate doesn't help).
    pub fn add(&mut self, name: &str, data: &[u8], level: u8) -> Result<Vec<u8>, String> {
        if self.finished {
            return Err("zip already finished".into());
        }
        if name.is_empty() {
            return Err("empty file name".into());
        }
        if name.len() > 0xFFFF {
            return Err(format!("file name too long: {name}"));
        }
        // gdunzip reads names with Godot's utf8 parser, which stops at NUL and drops a leading BOM.
        if name.contains('\0') || name.starts_with('\u{FEFF}') {
            return Err(format!("file name can't contain NUL or start with a BOM: {name:?}"));
        }
        if self.count >= 0xFFFF {
            return Err("too many files for a zip without zip64".into());
        }
        if data.len() as u64 >= 0xFFFF_FFFF {
            return Err(format!("file too big for a zip without zip64: {name}"));
        }

        let crc = crc32fast::hash(data);
        let deflated = if level > 0 && !data.is_empty() {
            let c = miniz_oxide::deflate::compress_to_vec(data, level.min(10));
            if c.len() < data.len() {
                Some(c)
            } else {
                None
            }
        } else {
            None
        };
        let (method, body): (u16, &[u8]) = match &deflated {
            Some(c) => (8, c),
            None => (0, data),
        };
        let flags = if name.is_ascii() { 0 } else { FLAG_UTF8 };
        let header_offset = self.offset;
        if header_offset >= 0xFFFF_FFFF
            || header_offset + 30 + name.len() as u64 + body.len() as u64 >= 0xFFFF_FFFF
        {
            return Err("zip too big without zip64".into());
        }

        let mut local = Vec::with_capacity(30 + name.len() + body.len());
        put32(&mut local, LOCAL_SIG);
        put16(&mut local, VERSION);
        put16(&mut local, flags);
        put16(&mut local, method);
        put16(&mut local, DOS_TIME);
        put16(&mut local, DOS_DATE);
        put32(&mut local, crc);
        put32(&mut local, body.len() as u32);
        put32(&mut local, data.len() as u32);
        put16(&mut local, name.len() as u16);
        put16(&mut local, 0);
        local.extend_from_slice(name.as_bytes());
        local.extend_from_slice(body);

        let c = &mut self.central;
        put32(c, 0x02014B50);
        put16(c, VERSION);
        put16(c, VERSION);
        put16(c, flags);
        put16(c, method);
        put16(c, DOS_TIME);
        put16(c, DOS_DATE);
        put32(c, crc);
        put32(c, body.len() as u32);
        put32(c, data.len() as u32);
        put16(c, name.len() as u16);
        put16(c, 0); // extra
        put16(c, 0); // comment
        put16(c, 0); // disk
        put16(c, 0); // internal attributes
        put32(c, if name.ends_with('/') { 0x10 } else { 0 });
        put32(c, header_offset as u32);
        c.extend_from_slice(name.as_bytes());

        self.count += 1;
        self.offset += local.len() as u64;
        Ok(local)
    }

    pub fn finish(&mut self) -> Result<Vec<u8>, String> {
        if self.finished {
            return Err("zip already finished".into());
        }
        if self.offset + self.central.len() as u64 >= 0xFFFF_FFFF {
            return Err("zip too big without zip64".into());
        }
        self.finished = true;
        let mut out = std::mem::take(&mut self.central);
        let cd_size = out.len() as u32;
        put32(&mut out, u32::from_le_bytes(EOCD_SIG));
        put16(&mut out, 0);
        put16(&mut out, 0);
        put16(&mut out, self.count as u16);
        put16(&mut out, self.count as u16);
        put32(&mut out, cd_size);
        put32(&mut out, self.offset as u32);
        put16(&mut out, 0);
        Ok(out)
    }
}

fn put16(v: &mut Vec<u8>, x: u16) {
    v.extend_from_slice(&x.to_le_bytes());
}

fn put32(v: &mut Vec<u8>, x: u32) {
    v.extend_from_slice(&x.to_le_bytes());
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{Cursor, Read};

    fn build(files: &[(&str, &[u8], u8)]) -> Vec<u8> {
        let mut z = ZipBuilder::new();
        let mut out = Vec::new();
        for (name, data, level) in files {
            out.extend(z.add(name, data, *level).unwrap());
        }
        out.extend(z.finish().unwrap());
        out
    }

    fn sample_files() -> Vec<(String, Vec<u8>, u8)> {
        let mut text = Vec::new();
        for i in 0..5000 {
            text.extend_from_slice(format!("line {i} of some text\n").as_bytes());
        }
        let noise: Vec<u8> = (0..70000u32).map(|i| (i.wrapping_mul(2654435761) >> 13) as u8).collect();
        vec![
            ("a.txt".into(), b"hello".to_vec(), 6),
            ("dir/".into(), vec![], 6),
            ("dir/text.txt".into(), text.clone(), 6),
            ("dir/text9.txt".into(), text.clone(), 9),
            ("dir/stored.txt".into(), text, 0),
            ("noise.bin".into(), noise, 6),
            ("empty.txt".into(), vec![], 6),
            ("ユニコード/ファイル.txt".into(), "テキスト".as_bytes().to_vec(), 6),
            ("emoji/😀.txt".into(), b"4 byte utf8 name".to_vec(), 1),
        ]
    }

    #[test]
    fn writer_output_reads_back_with_zip_crate() {
        let files = sample_files();
        let refs: Vec<_> = files.iter().map(|(n, d, l)| (n.as_str(), d.as_slice(), *l)).collect();
        let bytes = build(&refs);
        let mut archive = zip::ZipArchive::new(Cursor::new(bytes)).unwrap();
        assert_eq!(archive.len(), files.len());
        for (i, (name, data, _)) in files.iter().enumerate() {
            let mut f = archive.by_index(i).unwrap();
            assert_eq!(f.name(), name);
            let mut got = Vec::new();
            f.read_to_end(&mut got).unwrap();
            assert_eq!(&got, data, "{name}");
        }
    }

    #[test]
    fn writer_output_parses_and_inflates() {
        let files = sample_files();
        let refs: Vec<_> = files.iter().map(|(n, d, l)| (n.as_str(), d.as_slice(), *l)).collect();
        let bytes = build(&refs);
        let Parse::Ok { entries, end_pos } = parse_central_directory(&bytes, 0, bytes.len() as u64) else {
            panic!("parse failed");
        };
        assert_eq!(end_pos as usize, bytes.len() - 22);
        assert_eq!(entries.len(), files.len());
        for (e, (name, data, _)) in entries.iter().zip(&files) {
            assert_eq!(&bytes[e.name.clone()], name.as_bytes());
            let off = e.file_header_offset as usize;
            let n = u16_at(&bytes, off + 26) as usize;
            let x = u16_at(&bytes, off + 28) as usize;
            let body = &bytes[off + 30 + n + x..][..e.compressed_size as usize];
            let got = if e.stored { body.to_vec() } else { inflate_exact(body, e.uncompressed_size as usize).unwrap() };
            assert_eq!(&got, data, "{name}");
        }
    }

    #[test]
    fn writer_is_deterministic() {
        let files = sample_files();
        let refs: Vec<_> = files.iter().map(|(n, d, l)| (n.as_str(), d.as_slice(), *l)).collect();
        assert_eq!(build(&refs), build(&refs));
    }

    #[test]
    fn tail_read_asks_for_central_directory() {
        let big: Vec<u8> = (0..300_000u32).map(|i| (i.wrapping_mul(2654435761) >> 7) as u8).collect();
        let bytes = build(&[("big.bin", &big, 0), ("x.txt", b"x", 0)]);
        let len = bytes.len() as u64;
        let start = len - 100;
        match parse_central_directory(&bytes[start as usize..], start, len) {
            Parse::NeedFrom(off) => {
                assert!(off < start);
                assert!(matches!(parse_central_directory(&bytes[off as usize..], off, len), Parse::Ok { .. }));
            }
            other => panic!("{other:?}"),
        }
    }

    #[test]
    fn inflate_rejects_trailing_bytes_and_wrong_sizes() {
        let data = b"some data some data some data".repeat(50);
        let c = miniz_oxide::deflate::compress_to_vec(&data, 6);
        assert_eq!(inflate_exact(&c, data.len()).unwrap(), data);
        assert!(inflate_exact(&c, data.len() + 1).is_none());
        assert!(inflate_exact(&c, data.len() - 1).is_none());
        let mut trailing = c.clone();
        trailing.push(0);
        assert!(inflate_exact(&trailing, data.len()).is_none());
        assert!(inflate_exact(&c[..c.len() - 1], data.len()).is_none());
        assert!(inflate_exact(&[], 0).is_none());
    }

    #[test]
    fn bad_names_rejected() {
        let mut z = ZipBuilder::new();
        assert!(z.add("", b"", 0).is_err());
        assert!(z.add("a\0b", b"", 0).is_err());
        assert!(z.add("\u{FEFF}a", b"", 0).is_err());
    }
}
