# Writes zip files (native/gdzip, Rust). Output is deterministic (every entry
# gets the same fixed timestamp), so the same files always make the same zip,
# and gdunzip reads it back byte for byte.
#
#   var zip = load('res://modloader/gdunzip/gdzip.gd').new()
#   zip.open('user://out.zip')
#   zip.add_file('folder/a.txt', 'hello'.to_utf8())
#   zip.add_file('folder/b.png', png_bytes, false)  # store without compressing
#   zip.add_file_from_path('folder/c.ogg', 'user://c.ogg')
#   zip.close()
#
# Every function returns OK or an Error code. Folders don't need their own
# entries; a name ending in '/' adds an empty folder.

extends Reference

const _Native = preload("res://bin/GDZipNative.gdns")

const COMPRESSION_LEVEL = 6

var _native = null
var _file = null


func open(path):
	if _file != null:
		return ERR_ALREADY_IN_USE
	_native = _Native.new()
	if _native == null:
		return ERR_UNAVAILABLE
	_file = File.new()
	var err = _file.open(path, File.WRITE)
	if err != OK:
		_file = null
		_native = null
	return err


func add_file(name, data, compress = true):
	if _file == null:
		return ERR_UNCONFIGURED
	var bytes = _native.add_file(name, data, COMPRESSION_LEVEL if compress else 0)
	if bytes == null:
		return ERR_INVALID_PARAMETER
	_file.store_buffer(bytes)
	return _file.get_error()


func add_file_from_path(name, source_path, compress = true):
	var source = File.new()
	var err = source.open(source_path, File.READ)
	if err != OK:
		return err
	var data = source.get_buffer(source.get_len())
	source.close()
	return add_file(name, data, compress)


func close():
	if _file == null:
		return ERR_UNCONFIGURED
	var err = OK
	var bytes = _native.finish()
	if bytes == null:
		err = ERR_INVALID_DATA
	else:
		_file.store_buffer(bytes)
		err = _file.get_error()
	_file.close()
	_file = null
	_native = null
	return err
