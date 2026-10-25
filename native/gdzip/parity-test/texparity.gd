extends SceneTree
# Decodes every .stex in a folder with the native decoder and with Godot's own
# png/webp unpack (same libpng/libwebp calls StreamTexture uses), and compares.
#   dir=<folder>  out=<result file>
var frames = 0
func _idle(_d):
	frames += 1
	if frames != 3:
		return false
	var dir_path = ""
	var out_path = ""
	for a in OS.get_cmdline_args():
		if a.begins_with("dir="): dir_path = a.substr(4)
		if a.begins_with("out="): out_path = a.substr(4)
	var out = File.new()
	out.open(out_path, File.WRITE)
	var decoder = ResourceLoader.load("res://bin/GDTextureDecoder.gdns").new()
	if decoder == null:
		out.store_line("FATAL no decoder")
		out.close()
		quit()
		return false
	var names = []
	var d = Directory.new()
	d.open(dir_path)
	d.list_dir_begin(true, true)
	var f = d.get_next()
	while f != "":
		if f.ends_with(".stex"):
			names.append(f)
		f = d.get_next()
	names.sort()
	var n = {"files": 0, "native": 0, "left_to_godot": 0, "godot_failed_too": 0, "MISMATCH": 0, "PNG ": 0, "WEBP": 0, "bytes_compared": 0}
	var i = 0
	while i < names.size():
		var chunk = []
		var stexes = []
		for j in range(i, min(i + 64, names.size())):
			var file = File.new()
			file.open(dir_path.plus_file(names[j]), File.READ)
			stexes.append(file.get_buffer(file.get_len()))
			file.close()
			chunk.append(names[j])
		var decoded = decoder.decode_stex(stexes)
		for k in chunk.size():
			n.files += 1
			var dd = decoded[k]
			if dd == null:
				n.left_to_godot += 1
				continue
			n.native += 1
			var stex = stexes[k]
			var size = stex[24] | stex[25] << 8 | stex[26] << 16 | stex[27] << 24
			var tag = stex.subarray(28, 31).get_string_from_ascii()
			n[tag] = n.get(tag, 0) + 1
			var body = stex.subarray(32, min(28 + size, stex.size()) - 1)
			var img = Image.new()
			var err = img.load_png_from_buffer(body) if tag == "PNG " else img.load_webp_from_buffer(body)
			if err != OK:
				n.godot_failed_too += 1
				out.store_line("MISMATCH %s godot failed (%d), native didn't" % [chunk[k], err])
				n.MISMATCH += 1
				continue
			if img.get_width() != dd[0] or img.get_height() != dd[1] or img.get_format() != dd[2] or img.get_data() != dd[3]:
				n.MISMATCH += 1
				out.store_line("MISMATCH %s godot %s fmt %d vs native %dx%d fmt %d" % [chunk[k], img.get_size(), img.get_format(), dd[0], dd[1], dd[2]])
			else:
				n.bytes_compared += dd[3].size()
		i += 64
	out.store_line("TEXPARITY " + JSON.print(n))
	out.close()
	quit()
	return false
