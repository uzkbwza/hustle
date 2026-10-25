// Godot glue for the zip code in zipcore.rs.
//
// Used through res://modloader/gdunzip/gdunzip.gd (reading) and
// res://modloader/gdunzip/gdzip.gd (writing). File access stays on the
// GDScript side so paths (res://, user://, Android storage) behave exactly
// like they always did; this side only works on bytes.

use gdnative::export::user_data::MutexData;
use gdnative::init::{godot_gdnative_init, godot_gdnative_terminate, godot_nativescript_init};
use gdnative::prelude::*;

pub mod zipcore;

use zipcore::{Parse, ZipBuilder};

const PARSE_OK: i64 = 0;
const PARSE_NEED_FROM: i64 = 1;
const PARSE_FALLBACK: i64 = 2;

/// File.COMPRESSION_DEFLATE, what gdunzip stores for every non-stored entry.
const COMPRESSION_DEFLATE: i64 = 1;

#[derive(NativeClass)]
#[inherit(Reference)]
#[user_data(MutexData<GDUnzipNative>)]
pub struct GDUnzipNative;

#[methods]
impl GDUnzipNative {
    fn new(_base: &Reference) -> Self {
        GDUnzipNative
    }

    /// Parses the central directory out of `data` (the file from `data_start` to
    /// `file_len`) and adds every entry to `files`, exactly like gdunzip `_get_files()`.
    /// Returns [status, value]: [0, end pos], [1, offset to read from], or [2, 0] to
    /// use the GDScript implementation. `files` is only touched on success.
    #[method]
    fn parse_central_directory(
        &self,
        data: PoolArray<u8>,
        data_start: i64,
        file_len: i64,
        files: Dictionary,
    ) -> VariantArray {
        let result = VariantArray::new();
        if data_start < 0 || file_len < 0 {
            result.push(PARSE_FALLBACK);
            result.push(0);
            return result.into_shared();
        }
        let bytes = data.read();
        match zipcore::parse_central_directory(&bytes, data_start as u64, file_len as u64) {
            Parse::Ok { entries, end_pos } => {
                // Not really unique (the calling script holds it too), but it is only touched
                // from the calling thread for the length of this call.
                let files = unsafe { files.assume_unique() };
                // Same key order as gdunzip's header literal. Made once and
                // shared, instead of building five Godot strings per entry.
                let keys = [
                    "compression_method",
                    "file_name",
                    "compressed_size",
                    "uncompressed_size",
                    "file_header_offset",
                ]
                .map(Variant::new);
                for e in entries {
                    let name = godot_string_from_utf8(&bytes[e.name.clone()]).to_variant();
                    let header = Dictionary::new();
                    header.insert(&keys[0], if e.stored { -1 } else { COMPRESSION_DEFLATE });
                    header.insert(&keys[1], &name);
                    header.insert(&keys[2], e.compressed_size as i64);
                    header.insert(&keys[3], e.uncompressed_size as i64);
                    header.insert(&keys[4], e.file_header_offset as i64);
                    files.insert(name, header.into_shared());
                }
                result.push(PARSE_OK);
                result.push(end_pos as i64);
            }
            Parse::NeedFrom(off) => {
                result.push(PARSE_NEED_FROM);
                result.push(off as i64);
            }
            Parse::Fallback => {
                result.push(PARSE_FALLBACK);
                result.push(0);
            }
        }
        result.into_shared()
    }

    /// Inflates `data` into exactly `uncompressed_size` bytes, or returns null if
    /// the stream isn't one we can decode identically to gdunzip's Tinf.
    #[method]
    fn inflate(&self, data: PoolArray<u8>, uncompressed_size: i64) -> Variant {
        if !(0..=i32::MAX as i64).contains(&uncompressed_size) {
            return Variant::nil();
        }
        match zipcore::inflate_exact(&data.read(), uncompressed_size as usize) {
            Some(out) => PoolArray::<u8>::from_vec(out).to_variant(),
            None => Variant::nil(),
        }
    }
}

/// Builds a GodotString with Godot's own utf8 parser, the same one
/// PoolByteArray.get_string_from_utf8() uses, so NUL and BOM handling match.
///
/// Deliberate difference from the GDScript gdunzip: on invalid utf8, Godot
/// 3.5's parser stops halfway and leaves uninitialized memory in the string,
/// so the original produced random garbage names. Here invalid bytes become
/// U+FFFD instead, so the result is at least the same every time.
fn godot_string_from_utf8(bytes: &[u8]) -> GodotString {
    let bytes = String::from_utf8_lossy(bytes);
    let bytes = bytes.as_bytes();
    unsafe {
        let api = gdnative::private::get_api();
        GodotString::from_sys((api.godot_string_chars_to_utf8_with_len)(
            bytes.as_ptr() as *const _,
            bytes.len() as _,
        ))
    }
}

#[derive(NativeClass)]
#[inherit(Reference)]
#[user_data(MutexData<GDZipNative>)]
pub struct GDZipNative {
    builder: ZipBuilder,
}

#[methods]
impl GDZipNative {
    fn new(_base: &Reference) -> Self {
        GDZipNative { builder: ZipBuilder::new() }
    }

    /// Returns the bytes to append for this file (local header + data), or null on error.
    #[method]
    fn add_file(&mut self, name: GodotString, data: PoolArray<u8>, level: i64) -> Variant {
        let level = level.clamp(0, 10) as u8;
        match self.builder.add(&name.to_string(), &data.read(), level) {
            Ok(bytes) => PoolArray::<u8>::from_vec(bytes).to_variant(),
            Err(e) => {
                godot_error!("gdzip: {}", e);
                Variant::nil()
            }
        }
    }

    /// Returns the central directory + end record to append, or null on error.
    #[method]
    fn finish(&mut self) -> Variant {
        match self.builder.finish() {
            Ok(bytes) => PoolArray::<u8>::from_vec(bytes).to_variant(),
            Err(e) => {
                godot_error!("gdzip: {}", e);
                Variant::nil()
            }
        }
    }
}

fn init(handle: InitHandle) {
    handle.add_class::<GDUnzipNative>();
    handle.add_class::<GDZipNative>();
}

// Own symbol names (symbol_prefix = "gdzip_" in lib/gdzip.tres) so they can't
// clash with tbfg-lib's godot_* entry points.
godot_gdnative_init!(_ as gdzip_gdnative_init);
godot_nativescript_init!(init as gdzip_nativescript_init);
godot_gdnative_terminate!(_ as gdzip_gdnative_terminate);
