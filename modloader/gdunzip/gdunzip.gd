# Drop-in replacement for the original GDScript gdunzip (gdunzip_gdscript.gd).
# Same vars, same methods, same results, just faster:
#
# - load() only reads the end of the zip (the file list) instead of the whole
#   file, and parses it natively (native/gdzip, Rust).
# - uncompress() / get_compressed() read just that one file's bytes, and
#   inflate natively.
#
# Whenever the native side can't guarantee the exact same result (corrupt or
# unusual zips, odd deflate streams), it hands back and the original GDScript
# code runs on the whole file instead. Same if the native library is missing.
#
# Differences from the original:
# - `buffer` stays null after a native load (that's the whole file, which is
#   what we're avoiding reading). It's filled in if a fallback needs it.
# - file names that aren't valid utf8 come out with U+FFFD for the bad bytes.
#   The original gave random garbage for those (Godot 3.5's utf8 parser leaves
#   uninitialized memory in the string), different on every load.
#
# Usage is unchanged:
#   var gdunzip = load('res://modloader/gdunzip/gdunzip.gd').new()
#   gdunzip.load(path)
#   for f in gdunzip.files: ...
#   var bytes = gdunzip.uncompress(name)

extends "res://modloader/gdunzip/gdunzip_gdscript.gd"

# Note: this class has its own load(), so resources here must use preload().
const _Native = preload("res://bin/GDUnzipNative.gdns")

# Read this much from the end of the file first. The end record is always in
# the last 65557 bytes; the extra usually covers the whole file list too.
const _TAIL_READ = 262144

const _PARSE_OK = 0
const _PARSE_NEED_FROM = 1

var _native = null


func _init():
	if Engine.has_meta("gdunzip_native_missing"):
		return
	_native = _Native.new()
	if _native == null:
		Engine.set_meta("gdunzip_native_missing", true)


func load(path):
	if _native == null:
		return .load(path)

	if path == null:
		return false

	self.path = path
	self.pos = 0

	var file = File.new()

	if !file.file_exists(path):
		return false

	file.open(path, File.READ)
	var file_length = file.get_len()
	if file.get_32() != 0x04034B50:
		return false

	if file_length < 22:
		return _load_with_gdscript(file, file_length)

	var start = max(0, file_length - _TAIL_READ)
	while true:
		file.seek(start)
		var data = file.get_buffer(file_length - start)
		if data.size() != file_length - start:
			break
		var res = _native.parse_central_directory(data, start, file_length, self.files)
		if res[0] == _PARSE_OK:
			file.close()
			self.buffer_size = file_length
			self.pos = res[1]
			return true
		if res[0] != _PARSE_NEED_FROM or res[1] >= start:
			break
		start = res[1]

	return _load_with_gdscript(file, file_length)


func uncompress(file_name):
	if _native == null or self.buffer != null:
		return .uncompress(file_name)

	if !(file_name in self.files):
		return false

	var f = self.files[file_name]
	var raw = _read_entry_data(f)
	if raw == null:
		_load_buffer()
		return .uncompress(file_name)
	if f['compression_method'] == -1:
		return raw
	var out = _native.inflate(raw, f['uncompressed_size'])
	if out == null:
		return tinf.tinf_uncompress(f['uncompressed_size'], raw)
	return out


func get_compressed(file_name):
	if _native == null or self.buffer != null:
		return .get_compressed(file_name)

	if !(file_name in self.files):
		return false

	var raw = _read_entry_data(self.files[file_name])
	if raw == null:
		_load_buffer()
		return .get_compressed(file_name)
	return raw


# The rest of the original load(), from the point it reads the whole file.
func _load_with_gdscript(file, file_length):
	file.seek(0)
	self.buffer = file.get_buffer(file_length)
	self.buffer_size = self.buffer.size()
	file.close()

	if self.buffer_size < 22:
		return false

	return self._get_files()


func _load_buffer():
	var file = File.new()
	file.open(self.path, File.READ)
	self.buffer = file.get_buffer(file.get_len())
	self.buffer_size = self.buffer.size()
	file.close()


# Reads a file's compressed bytes straight from disk, the same bytes the
# original gets from `pos = file_header_offset; _skip_file_header();
# _read(compressed_size)`. Returns null for anything that would go out of
# bounds there, so the caller can run the original instead.
func _read_entry_data(f):
	var offset = f['file_header_offset']
	var size = f['compressed_size']
	if typeof(offset) != TYPE_INT or typeof(size) != TYPE_INT or offset < 0 or size < 0:
		return null
	if offset + 30 > self.buffer_size:
		return null

	var file = File.new()
	if file.open(self.path, File.READ) != OK:
		return null
	if file.get_len() != self.buffer_size:
		file.close()
		return null

	file.seek(offset)
	var header = file.get_buffer(30)
	var data_pos = offset + 30 + (header[27] << 8 | header[26]) + (header[29] << 8 | header[28])
	if data_pos + max(size, 1) > self.buffer_size:
		file.close()
		return null

	var data = PoolByteArray()
	if size > 0:
		file.seek(data_pos)
		data = file.get_buffer(size)
	file.close()
	self.pos = data_pos + size
	return data
