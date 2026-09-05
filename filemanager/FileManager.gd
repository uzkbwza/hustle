extends Node

# ============================================================================
# FileManager
# ============================================================================

const PACK_TYPE: String = "YMHPACK"
const PACK_FORMAT_VERSION: int = 1
const PACK_EXT: String = ".ymhpack"
const LIST_EXT: String = ".ymhlist"
const PENDING_DELETE_PATH: String = "user://lists/files_to_delete.ymhlist"
# Whole-pack cap. Kept modest: a fighting-game pack is a handful of style/
# mod files; allowing multi-GB files invites memory blowups on import/export.
const MAX_PACK_FILE_BYTES: int = 8 * 1024 * 1024 * 1024 #8gb
# Per-entry cap, enforced before any payload is buffered into memory.
const MAX_ENTRY_BYTES: int = 512 * 1024 * 1024 #512mb

# category name (matches FileManagerInterface.dir_name) -> absolute dir_path
var _category_dirs: Dictionary = {}

var android_picker  # GodotFilePicker singleton, if present

signal status_message(text)
signal pack_imported(path, count)
signal pack_import_failed(path, reason)
signal file_copied(path, category)
signal inbox_files_pending(files)  # untrusted .ymhpack files await user confirmation


func _init() -> void:
	if OS.get_name() == "Windows":
		_register_file_associations()
	
	if OS.get_name() == "Android" and Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
	
	_process_pending_deletions()
	
	for arg in OS.get_cmdline_args():
		if arg.get_extension().to_lower() == "ymhpack":
			import_pack(arg)
	
	_check_ymhpack_inbox()


func _notification(what: int) -> void:
	if Global.is_mobile_device and what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
		_check_ymhpack_inbox()


# ---------------------------------------------------------------------------
# Category registry
# ---------------------------------------------------------------------------

func register_category(category: String, dir_path: String) -> void:
	_category_dirs[category] = dir_path


func unregister_category(category: String) -> void:
	_category_dirs.erase(category)


func get_category_dir(category: String) -> String:
	return _category_dirs.get(category, "")


# ---------------------------------------------------------------------------
# Windows file association / cmdline / mobile inbox
# ---------------------------------------------------------------------------

func _register_file_associations() -> void:
	if Global.registered_ymhpack:
		return
	
	var exe_path = OS.get_executable_path().replace("/", "\\")
	var commands = [
		["add", "HKCU\\Software\\Classes\\.ymhpack", "/ve", "/d", "YourOnlyMoveIsHustlePack", "/f"],
		["add", "HKCU\\Software\\Classes\\YourOnlyMoveIsHustlePack", "/ve", "/d", "YourOnlyMoveIsHustlePack", "/f"],
		["add", "HKCU\\Software\\Classes\\YourOnlyMoveIsHustlePack\\shell\\open\\command", "/ve", "/d", "\"" + exe_path + "\" \"%1\"", "/f"],
		["add", "HKCU\\Software\\Classes\\YourOnlyMoveIsHustlePack\\DefaultIcon", "/ve", "/d", exe_path + ",0", "/f"],
	]
	for cmd in commands:
		OS.execute("reg", cmd, true)
	OS.execute("cmd", ["/c", "assoc", ".ymhpack"], false)
	
	Global.registered_ymhpack = true
	Global.save_options_after_change("registered_ymhpack", true)


# Scans the mobile inbox for untrusted .ymhpack files and reports them via
# inbox_files_pending WITHOUT importing or deleting anything. Import only
# happens after the user explicitly confirms (see import_inbox). This stops
# content received on a device from being silently extracted on its own.
func _check_ymhpack_inbox() -> void:
	var inbox = "user://ymhpack"
	var dir = Directory.new()
	if dir.open(inbox) != OK:
		return
	dir.list_dir_begin(true, true)
	var pending := []
	var f = dir.get_next()
	while f != "":
		if f.get_extension().to_lower() == "ymhpack":
			pending.append(inbox.plus_file(f))
		f = dir.get_next()
	dir.list_dir_end()
	
	if not pending.empty():
		emit_signal("inbox_files_pending", pending)


# Imports and removes the confirmed .ymhpack files sitting in the mobile
# inbox. Call this only after the user has explicitly chosen to accept them.
func import_inbox() -> void:
	var inbox = "user://ymhpack"
	var dir = Directory.new()
	if dir.open(inbox) != OK:
		return
	dir.list_dir_begin(true, true)
	var f = dir.get_next()
	while f != "":
		if f.get_extension().to_lower() == "ymhpack":
			if import_pack(inbox.plus_file(f)):
				dir.remove(f)
		f = dir.get_next()
	dir.list_dir_end()


# ---------------------------------------------------------------------------
# pack export/import.
# ---------------------------------------------------------------------------

func export_pack(entries: Array, destination_dir: String, package_name: String) -> bool:
	if entries.empty():
		emit_signal("status_message", "Failed to export, no files given")
		return false
	
	var dir = Directory.new()
	if not dir.dir_exists(destination_dir):
		if dir.make_dir_recursive(destination_dir) != OK:
			emit_signal("status_message", "Failed to export, couldn't create dir: " + destination_dir)
			return false
	
	var packed_entries := []
	
	for entry in entries:
		var src_path: String = entry.get("path", "")
		var category: String = entry.get("category", "")
		
		var src = File.new()
		if src_path == "" or not src.file_exists(src_path):
			emit_signal("status_message", "Failed to export, file does not exist: " + src_path)
			return false
		
		if src.open(src_path, File.READ) != OK:
			emit_signal("status_message", "Failed to export, couldn't read file: " + src_path)
			return false
		
		var file_len = src.get_len()
		if file_len > MAX_ENTRY_BYTES:
			src.close()
			emit_signal("status_message", "Failed to export, file too large (%.1f MB): %s" % [file_len / (1024.0 * 1024.0), src_path])
			return false
		
		var bytes: PoolByteArray = src.get_buffer(file_len)
		src.close()
		
		packed_entries.append({
			"file_name": src_path.get_file(),
			"category": category,
			"payload": bytes,
		})
	
	var package := {
		"type": PACK_TYPE,
		"version": PACK_FORMAT_VERSION,
		"entries": packed_entries,
	}
	
	var clean_name = package_name.strip_edges()
	if clean_name == "":
		clean_name = "export"
	var final_path = destination_dir.plus_file(clean_name + PACK_EXT)
	
	var out_file = File.new()
	if out_file.open(final_path, File.WRITE) != OK:
		emit_signal("status_message", "Failed to export, couldn't write package: " + final_path)
		return false
	
	out_file.store_var(package, false)
	out_file.close()
	
	emit_signal("status_message", "Exported %d file(s) to: %s" % [packed_entries.size(), final_path])
	return true


func import_pack(path: String) -> bool:
	var probe = File.new()
	if not probe.file_exists(path):
		emit_signal("pack_import_failed", path, "file does not exist")
		emit_signal("status_message", "Package not found: " + path)
		return false
	
	if probe.open(path, File.READ) != OK:
		emit_signal("pack_import_failed", path, "couldn't open file")
		emit_signal("status_message", "Failed to open package: " + path)
		return false
	
	var file_len = probe.get_len()
	if file_len > MAX_PACK_FILE_BYTES:
		probe.close()
		emit_signal("pack_import_failed", path, "package too large")
		emit_signal("status_message", "Package exceeds size limit, aborted: " + path)
		return false
	
	var package = probe.get_var(false)
	probe.close()
	
	if typeof(package) != TYPE_DICTIONARY or package.get("type", "") != PACK_TYPE:
		emit_signal("pack_import_failed", path, "not a valid package")
		emit_signal("status_message", "Package is invalid: " + path)
		return false
	
	if typeof(package.get("version")) != TYPE_INT or package["version"] > PACK_FORMAT_VERSION:
		emit_signal("pack_import_failed", path, "unsupported package version")
		emit_signal("status_message", "Package needs a newer game version: " + path)
		return false
	
	var entries = package.get("entries", [])
	if typeof(entries) != TYPE_ARRAY or entries.empty():
		emit_signal("pack_import_failed", path, "no entries")
		emit_signal("status_message", "Package has no files: " + path)
		return false
	
	var imported_count := 0
	
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		
		var original_name: String = entry.get("file_name", "")
		var category: String = entry.get("category", "")
		var payload = entry.get("payload", null)
		
		if typeof(payload) != TYPE_RAW_ARRAY:
			emit_signal("status_message", "Skipped entry with invalid payload: " + original_name)
			continue
		
		if payload.size() > MAX_ENTRY_BYTES:
			emit_signal("status_message", "Skipped oversized file (%.1f MB): %s" % [payload.size() / (1024.0 * 1024.0), original_name])
			continue
		
		# Strip any directory component a malicious entry might smuggle in.
		var safe_name = original_name.get_file()
		if safe_name == "" or safe_name.begins_with("."):
			emit_signal("status_message", "Skipped file with unsafe name: " + original_name)
			continue
		
		var dest_dir = get_category_dir(category)
		if dest_dir == "":
			emit_signal("status_message", "Skipped file with unknown category '%s': %s" % [category, safe_name])
			continue
		
		var dir = Directory.new()
		if not dir.dir_exists(dest_dir):
			if dir.make_dir_recursive(dest_dir) != OK:
				emit_signal("status_message", "Failed to import, couldn't create dir: " + dest_dir)
				continue
		
		var dest_path = dest_dir.plus_file(safe_name)
		var out_file = File.new()
		if out_file.open(dest_path, File.WRITE) != OK:
			emit_signal("status_message", "Failed to import, couldn't write file: " + dest_path)
			continue
		
		out_file.store_buffer(payload)
		out_file.close()
		
		emit_signal("file_copied", dest_path, category)
		imported_count += 1
	
	if imported_count == 0:
		emit_signal("pack_import_failed", path, "nothing imported")
		emit_signal("status_message", "Package imported nothing: " + path)
		return false
	
	emit_signal("pack_imported", path, imported_count)
	emit_signal("status_message", "Package imported %d file(s): %s" % [imported_count, path])
	return true


# ---------------------------------------------------------------------------
# Generic directory / copy utilities (no UI, no data_source)
# ---------------------------------------------------------------------------

func scan_directory_for_files(directory: String, extensions: PoolStringArray, all_files := false, full_path := false) -> PoolStringArray:
	var results := PoolStringArray()
	var dir = Directory.new()
	if dir.open(directory) != OK:
		return results

	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			for extension in extensions:
				if all_files or "." + file_name.get_extension().to_lower() == extension:
					results.append(directory.plus_file(file_name) if full_path else file_name)
					break
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func copy_file_to_directory(path: String, directory: String, extensions: PoolStringArray, category: String) -> bool:
	var ext = "." + path.get_extension().to_lower()
	
	if ext == PACK_EXT:
		return import_pack(path)
	
	if extensions.size() > 0 and not ext in extensions:
		emit_signal("status_message", "Failed to copy file, it doesn't match the extensions: " + extensions.join(", "))
		return false
	
	var dir = Directory.new()
	if not dir.dir_exists(directory):
		var err = dir.make_dir_recursive(directory)
		if err != OK:
			emit_signal("status_message", "Failed to copy file, couldn't create dir: %s (error %d)" % [directory, err])
			return false
	
	var file_name = path.get_file()
	var dest_path = directory.plus_file(file_name)
	var err = dir.copy(path, dest_path)
	
	if err != OK:
		emit_signal("status_message", "Failed to copy file, error code: " + str(err))
		return false
	
	if not dir.file_exists(dest_path):
		emit_signal("status_message", "Copy reported OK but file not found at destination")
		return false
	
	emit_signal("status_message", "File copied and verified: " + dest_path)
	emit_signal("file_copied", dest_path, category)
	return true


# ---------------------------------------------------------------------------
# List persistence
# ---------------------------------------------------------------------------

func _try_parse_json(text: String):
	if text.empty():
		return null
	var result = JSON.parse(text)
	if result.error != OK:
		return null
	return result.result


func make_list_folder(list_dir_path: String) -> void:
	var dir = Directory.new()
	if not dir.dir_exists(list_dir_path):
		dir.make_dir_recursive(list_dir_path)


func save_list(list_dir_path: String, data: Dictionary, list_name: String) -> String:
	var clean_name = list_name.strip_edges()
	if clean_name == "":
		clean_name = "default"
	make_list_folder(list_dir_path)
	
	var to_save = data.duplicate(true)
	to_save["list_name"] = clean_name
	
	var file = File.new()
	if file.open(list_dir_path.plus_file(clean_name) + LIST_EXT, File.WRITE) == OK:
		file.store_string(to_json(to_save))
		file.close()
	else:
		emit_signal("status_message", "Failed to save list: " + clean_name)
	return clean_name


func load_list(list_dir_path: String, list_name: String) -> Dictionary:
	var path = list_dir_path.plus_file(list_name) + LIST_EXT
	var file = File.new()
	if not file.file_exists(path):
		return {}
	
	if file.open(path, File.READ) != OK:
		return {}
	var text = file.get_as_text()
	file.close()
	
	var parsed = _try_parse_json(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	
	return {}


func load_all_lists(list_dir_path: String) -> Array:
	make_list_folder(list_dir_path)
	var dir = Directory.new()
	var files = []
	var _directories = []
	dir.open(list_dir_path)
	dir.list_dir_begin(false, true)
	Global.add_dir_contents(dir, files, _directories, false, LIST_EXT)
	dir.list_dir_end()

	var items := []
	for path in files:
		var list_name = path.get_file().get_basename()
		var data = load_list(list_dir_path, list_name)
		if not data.empty():
			items.append(data)
	return items


func delete_list(list_dir_path: String, list_name: String) -> void:
	Directory.new().remove(list_dir_path.plus_file(list_name) + LIST_EXT)


# ---------------------------------------------------------------------------
# Deferred deletion
# ---------------------------------------------------------------------------

const PENDING_DELETE_DIR: String = "user://lists"

func mark_for_deletion(paths: PoolStringArray) -> void:
	if paths.size() < 1:
		return
	
	var f = File.new()
	if not f.file_exists(PENDING_DELETE_PATH):
		var tmp_path = PENDING_DELETE_PATH + ".tmp"
		if f.open(tmp_path, File.WRITE) != OK:
			push_warning("ModLoader: failed to write user://modded.json")
			return
		f.store_string(JSON.print([], "  "))
		f.close()
		var dir = Directory.new()
		if dir.rename(tmp_path, PENDING_DELETE_PATH) != OK:
			push_warning("ModLoader: failed to commit user://modded.json")
	
	var data: Array = []
	var file = File.new()
	if file.open(PENDING_DELETE_PATH, File.READ) == OK:
		var text = file.get_as_text()
		file.close()
		var parsed = _try_parse_json(text)
		if typeof(parsed) == TYPE_ARRAY:
			data = parsed
	
	for path in paths:
		data.append(path)
	
	var dir = Directory.new()
	if not dir.dir_exists(PENDING_DELETE_DIR):
		dir.make_dir_recursive(PENDING_DELETE_DIR)
	
	var out = File.new()
	if out.open(PENDING_DELETE_PATH, File.WRITE) == OK:
		out.store_string(to_json(data))
		out.close()
	else:
		emit_signal("status_message", "Failed to queue files for deletion")
		return
	
	get_tree().quit()


func _process_pending_deletions() -> void:
	var file = File.new()
	if not file.file_exists(PENDING_DELETE_PATH):
		return
	
	if file.open(PENDING_DELETE_PATH, File.READ) != OK:
		return
	var text = file.get_as_text()
	file.close()
	
	var parsed = _try_parse_json(text)
	if typeof(parsed) == TYPE_ARRAY:
		var dir = Directory.new()
		for path in parsed:
			if typeof(path) == TYPE_STRING:
				dir.remove(path)
	
	Directory.new().remove(PENDING_DELETE_PATH)


# ---------------------------------------------------------------------------
# Generic list sorting shared by all list UIs (style list, mod list).
# Menus build an Array of item Dictionaries and call sort_items(); the
# resulting order is then applied to each menu's own scene tree.
# ---------------------------------------------------------------------------

enum SortMode { NAME, DATE, ACTIVE }

# Sort parameters, set once per sort_items() call. Safe as instance vars:
# sort_custom() runs synchronously, so the singleton is never read while a
# different sort is in progress.
var _sort_mode = SortMode.NAME
var _sort_inverted := false

# Sorts `items` (an Array of Dictionaries) in place and returns it. Each item:
#   "name":   String display name (also the tie-breaker)
#   "active": bool   - active entries come first in ACTIVE mode
#   "path":   String file path used for DATE mode (file modified time)
func sort_items(items: Array, mode: int, inverted: bool) -> Array:
	_sort_mode = mode
	_sort_inverted = inverted
	items.sort_custom(self, "_compare_items")
	return items


func _compare_items(a: Dictionary, b: Dictionary) -> bool:
	if _sort_inverted:
		return _item_less(b, a)
	return _item_less(a, b)


func _item_less(a: Dictionary, b: Dictionary) -> bool:
	var a_name := str(a.get("name", "")).to_lower()
	var b_name := str(b.get("name", "")).to_lower()

	match _sort_mode:
		SortMode.DATE:
			var file_a := File.new()
			var file_b := File.new()
			var a_time := file_a.get_modified_time(a.get("path", ""))
			var b_time := file_b.get_modified_time(b.get("path", ""))
			if a_time != b_time:
				return a_time > b_time
			return a_name < b_name
		SortMode.ACTIVE:
			if bool(a.get("active", false)) != bool(b.get("active", false)):
				return bool(a.get("active", false))
			return a_name < b_name
		SortMode.NAME:
			return a_name < b_name
	return a_name < b_name
