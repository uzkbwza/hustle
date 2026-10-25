# Compares modloader/AudioImport.gd (char loader's sound conversion) against
# Godot 3.5.1's own importer. Setup, in a throwaway project folder:
#   1. project.godot, lib/gdzip.tres + lib/gdzip/<library>, bin/GDAudioImporter.gdns,
#      modloader/AudioImport.gd copied from this project
#   2. the .wav/.ogg/.mp3 files to test with their .import files
#      (python3 gen_wav.py <folder>/synth makes synthetic ones with every option)
#   3. let the editor import them: run it with -e on that folder until
#      .import/ stops growing, then close it
#   4. godot --path <folder> -s compare_audio.gd out=<result file>
# MISMATCH must be 0; "both failed" means the editor rejected the file too.
extends SceneTree
var frames = 0
func _all(path, out):
	var d = Directory.new()
	if d.open(path) != OK:
		return out
	d.list_dir_begin(true, true)
	var f = d.get_next()
	while f != "":
		if d.current_is_dir():
			_all(path.plus_file(f), out)
		elif f.get_extension() in ["wav", "ogg", "mp3"]:
			out.append(path.plus_file(f))
		f = d.get_next()
	return out

func _bytes(path):
	var f = File.new()
	if f.open(path, File.READ) != OK:
		return null
	var b = f.get_buffer(f.get_len())
	f.close()
	return b

func _idle(_d):
	frames += 1
	if frames != 3:
		return false
	var out_path = ""
	for a in OS.get_cmdline_args():
		if a.begins_with("out="): out_path = a.substr(4)
	var out = File.new()
	out.open(out_path, File.WRITE)
	var AudioImport = load("res://modloader/AudioImport.gd")
	Directory.new().make_dir_recursive("user://cmp")
	var n = {"files": 0, "same": 0, "both_failed": 0, "MISMATCH": 0, "file_bytes_identical": 0}
	var i = 0
	for path in _all("res://", []):
		if path.begins_with("res://.import"):
			continue
		i += 1
		n.files += 1
		var cfg = ConfigFile.new()
		cfg.load(path + ".import")
		var editor_dest = cfg.get_value("remap", "path", "")
		var ref = ResourceLoader.load(path) if editor_dest != "" and File.new().file_exists(editor_dest) else null
		var ext = editor_dest.get_extension() if editor_dest != "" else {"wav": "sample", "ogg": "oggstr", "mp3": "mp3str"}[path.get_extension()]
		var ours_path = "user://cmp/%d.%s" % [i, ext]
		var ok = AudioImport.save_wav(path, ours_path, cfg) if path.ends_with(".wav") else AudioImport.save_compressed(path, ours_path, cfg)
		if ref == null and not ok:
			n.both_failed += 1
			out.store_line("both failed: " + path)
			continue
		if ref == null or not ok:
			n.MISMATCH += 1
			out.store_line("MISMATCH %s editor %s, ours %s" % [path, "failed" if ref == null else "ok", "ok" if ok else "failed"])
			continue
		var ours = ResourceLoader.load(ours_path, "", true)
		var problems = []
		var props = ["data", "format", "mix_rate", "stereo", "loop_mode", "loop_begin", "loop_end"] if ref is AudioStreamSample else ["data", "loop", "loop_offset"]
		for p in props:
			if typeof(ref.get(p)) != typeof(ours.get(p)) or ref.get(p) != ours.get(p):
				problems.append("%s: %s vs %s" % [p, str(ref.get(p)).substr(0, 40), str(ours.get(p)).substr(0, 40)])
		if problems.size() > 0:
			n.MISMATCH += 1
			out.store_line("MISMATCH %s %s" % [path, problems])
		else:
			n.same += 1
		if _bytes(editor_dest) == _bytes(ours_path):
			n.file_bytes_identical += 1
		else:
			out.store_line("file bytes differ: %s" % path)
	out.store_line("AUDIO " + JSON.print(n))
	out.close()
	quit()
	return false
