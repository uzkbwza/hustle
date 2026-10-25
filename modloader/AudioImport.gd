# Turns a mod's .wav / .ogg / .mp3 into the same resource Godot's own importer
# would have made from it, using the options in that file's .import, for char
# loader's asset cache. The WAV part is a port of Godot 3.5.1's importer in
# native/gdzip (audio.rs); .ogg and .mp3 are stored as-is, like the importer
# does. Each function returns false where the editor's importer would have
# failed too (or the native library is missing), so the caller can fall back.

extends Reference

# preload, not load(), so exports that only include used resources keep it
const _Importer = preload("res://bin/GDAudioImporter.gdns")

# ResourceImporterWAV's options and defaults
const WAV_DEFAULTS = {
	"force/8_bit": false,
	"force/mono": false,
	"force/max_rate": false,
	"force/max_rate_hz": 44100,
	"edit/trim": false,
	"edit/normalize": false,
	"edit/loop_mode": 0,
	"edit/loop_begin": 0,
	"edit/loop_end": -1,
	"compress/mode": 0,
}


static func wav_options(import_cfg):
	var options = {}
	for key in WAV_DEFAULTS:
		var value = import_cfg.get_value("params", key, WAV_DEFAULTS[key])
		options[key] = bool(value) if typeof(WAV_DEFAULTS[key]) == TYPE_BOOL else int(value)
	return options


static func save_wav(source_path, dest_path, import_cfg):
	var importer = _Importer.new()
	if importer == null:
		return false
	var bytes = _read(source_path)
	if bytes == null:
		return false
	var r = importer.import_wav(bytes, wav_options(import_cfg))
	if r == null:
		return false
	var sample = AudioStreamSample.new()
	sample.data = r[0]
	sample.format = r[1]
	sample.mix_rate = r[2]
	sample.loop_mode = r[3]
	sample.loop_begin = r[4]
	sample.loop_end = r[5]
	sample.stereo = r[6]
	return ResourceSaver.save(dest_path, sample) == OK


# .ogg -> .oggstr, .mp3 -> .mp3str
static func save_compressed(source_path, dest_path, import_cfg):
	var stream
	if dest_path.ends_with(".oggstr"):
		stream = AudioStreamOGGVorbis.new()
	elif dest_path.ends_with(".mp3str") and ClassDB.class_exists("AudioStreamMP3"):
		stream = ClassDB.instance("AudioStreamMP3")
	else:
		return false
	var bytes = _read(source_path)
	if bytes == null:
		return false
	stream.data = bytes
	if stream.data.size() == 0: # not a valid file
		return false
	stream.loop = import_cfg.get_value("params", "loop", true)
	stream.loop_offset = import_cfg.get_value("params", "loop_offset", 0.0)
	return ResourceSaver.save(dest_path, stream) == OK


static func _read(path):
	var f = File.new()
	if f.open(path, File.READ) != OK:
		return null
	var bytes = f.get_buffer(f.get_len())
	f.close()
	return bytes
