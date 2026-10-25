extends SceneTree
# Writes zips with gdzip.gd and reads them back with the ORIGINAL gdunzip.
func _init():
	var outdir = ""
	for a in OS.get_cmdline_args():
		if a.begins_with("out="): outdir = a.substr(4)
	var Zip = ResourceLoader.load("res://modloader/gdunzip/gdzip.gd")
	var Orig = ResourceLoader.load("res://modloader/gdunzip/gdunzip_gdscript.gd")
	var rng = RandomNumberGenerator.new(); rng.seed = 7
	var files = {}
	files["mod/_metadata"] = '{"name": "x"}'.to_utf8()
	files["mod/"] = PoolByteArray()
	files["mod/empty.txt"] = PoolByteArray()
	var noise = PoolByteArray(); noise.resize(100000)
	for i in noise.size(): noise[i] = rng.randi() & 0xFF
	files["mod/noise.bin"] = noise
	var text = ""
	for i in 20000: text += "line %d func var extends\n" % (i % 97)
	files["mod/ModMain.gd"] = text.to_utf8()
	files["mod/ユニコード/ファイル.txt"] = "テキスト 😀".to_utf8()
	files["mod/one.txt"] = "x".to_utf8()
	var fails = 0
	for variant in ["a", "b"]:
		var zip = Zip.new()
		var p = outdir + "/written_" + variant + ".zip"
		var e = zip.open(p)
		for k in files:
			e = e if e != OK else zip.add_file(k, files[k], k != "mod/noise.bin" or variant == "b")
		if e == OK: e = zip.close()
		print("write ", variant, " -> ", e)
		var g = Orig.new()
		print("original gdunzip load: ", g.load(p))
		if g.files.keys() != files.keys():
			print("KEYS DIFFER ", g.files.keys()); fails += 1
		for k in files:
			var got = g.uncompress(k)
			if typeof(got) != TYPE_RAW_ARRAY or got != files[k]:
				print("DATA DIFFERS ", k); fails += 1
		# also through the new one
		var n = ResourceLoader.load("res://modloader/gdunzip/gdunzip.gd").new()
		n.load(p)
		for k in files:
			if n.uncompress(k) != files[k]:
				print("NEW DATA DIFFERS ", k); fails += 1
	# error handling
	var z = Zip.new()
	print("add before open: ", z.add_file("a", PoolByteArray()))
	print("open bad dir: ", z.open("/nonexistent_dir_xyz/a.zip"))
	z.open(outdir + "/bad.zip")
	print("empty name: ", z.add_file("", PoolByteArray()))
	print("close: ", z.close())
	print("close twice: ", z.close())
	z = Zip.new(); z.open(outdir + "/again.zip"); z.add_file("k", "x".to_utf8()); z.close()
	print("reuse after close: ", z.open(outdir + "/again2.zip"), " ", z.add_file("k", "x".to_utf8()), " ", z.close())
	print("WRITER FAILS: ", fails)
	quit()
