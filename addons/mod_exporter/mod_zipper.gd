# Packs a mod folder into a zip the mod loader can use, including the files
# Godot's importer generated for it (res://.import/...). With those in the zip,
# char loader doesn't have to convert anything when the mod is first loaded.
#
# Only the generated files that the mod's own *.import files list are added,
# never the whole .import folder (that would be a copy of the whole game).
#
#   var report = ModZipper.export_mod("res://MyMod", "/path/to/MyMod.zip")
#
# report: {error: OK or an Error, files: n, imported_files: n, bytes: n,
#          missing: [generated files that don't exist (asset never imported)]}

tool
extends Reference

const Zip = preload("res://modloader/gdunzip/gdzip.gd")

const SKIP_NAMES = [".git", ".DS_Store", "Thumbs.db"]


static func export_mod(folder, zip_path):
	var report = {"error": OK, "files": 0, "imported_files": 0, "bytes": 0, "missing": []}
	folder = folder.trim_suffix("/")
	var files = _all_files(folder, [])
	files.sort()

	var generated = []
	for f in files:
		if f.ends_with(".import"):
			for dest in _generated_files(f):
				if not dest in generated:
					generated.append(dest)
	generated.sort()

	var zip = Zip.new()
	report.error = zip.open(zip_path)
	if report.error != OK:
		return report
	for f in files:
		report.error = zip.add_file_from_path(f.trim_prefix("res://"), f)
		if report.error != OK:
			zip.close()
			return report
		report.files += 1
	var check = File.new()
	for dest in generated:
		if not check.file_exists(dest):
			report.missing.append(dest)
			continue
		report.error = zip.add_file_from_path(dest.trim_prefix("res://"), dest)
		if report.error != OK:
			zip.close()
			return report
		report.imported_files += 1
	report.error = zip.close()

	if check.open(zip_path, File.READ) == OK:
		report.bytes = check.get_len()
		check.close()
	return report


# Top-level folders with a _metadata file.
static func find_mod_folders():
	var found = []
	var dir = Directory.new()
	if dir.open("res://") != OK:
		return found
	dir.list_dir_begin(true, true)
	var name = dir.get_next()
	while name != "":
		if dir.current_is_dir() and dir.file_exists("res://" + name + "/_metadata"):
			found.append("res://" + name)
		name = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found


static func _generated_files(import_path):
	var cfg = ConfigFile.new()
	if cfg.load(import_path) != OK:
		return []
	var dests = cfg.get_value("deps", "dest_files", [])
	if dests.empty() and cfg.has_section("remap"):
		for key in cfg.get_section_keys("remap"):
			if key == "path" or key.begins_with("path."):
				dests.append(cfg.get_value("remap", key))
	var out = []
	for d in dests:
		if str(d).begins_with("res://.import/"):
			out.append(str(d))
	return out


static func _all_files(path, out):
	var dir = Directory.new()
	if dir.open(path) != OK:
		return out
	dir.list_dir_begin(true, false)
	var name = dir.get_next()
	while name != "":
		if not name in SKIP_NAMES:
			if dir.current_is_dir():
				_all_files(path.plus_file(name), out)
			else:
				out.append(path.plus_file(name))
		name = dir.get_next()
	dir.list_dir_end()
	return out
