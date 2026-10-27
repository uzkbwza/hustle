extends Node

# ============================================================================
# FileManager
# ============================================================================

const PACK_TYPE: String = "YMHPACK"
const PACK_FORMAT_VERSION: int = 1
const PACK_EXT: String = ".ymhpack"
const LIST_EXT: String = ".ymhlist"
const PENDING_DELETE_PATH: String = "user://lists/files_to_delete.ymhlist"
const MAX_PACK_FILE_BYTES: int = 8 * 1024 * 1024 * 1024 #8gb
const MAX_ENTRY_BYTES: int = 512 * 1024 * 1024 #512mb
const PACK_SNIFF_BYTES: int = 64 * 1024
const PACK_CHUNK_BYTES: int = 256 * 1024
const PACK_MAGIC: String = "YMHPACK"

const INVALID_NAME_CHARS: String = "<>:\"/\\|?*"
const RESERVED_NAMES: Array = [
	"con", "prn", "aux", "nul",
	"com1", "com2", "com3", "com4", "com5", "com6", "com7", "com8", "com9",
	"lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9",
]
const MAX_NAME_LENGTH: int = 120

# category name (matches FileManagerInterface.dir_name) -> absolute dir_path
var _category_dirs: Dictionary = {}

var android_picker  # GodotFilePicker singleton, if present

signal status_message(text)
signal pack_imported(path, count)
signal pack_import_failed(path, reason)
signal file_copied(path, category)


func _init() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("GodotFilePicker"):
		android_picker = Engine.get_singleton("GodotFilePicker")
	elif OS.get_name() == "Android":
		push_warning("FileManager: GodotFilePicker Android plugin not found - in-game file import is unavailable.")
	
	register_category("custom", "user://custom")
	register_category("replay", "user://replay")
	var mods_default_dir = "user://mods"
	if not OS.has_feature("mobile"):
		var install_dir = OS.get_executable_path().get_base_dir()
		if OS.get_name() == "OSX":
			install_dir = install_dir.get_base_dir().get_base_dir().get_base_dir()
		mods_default_dir = install_dir.plus_file("mods")
	register_category("mods", mods_default_dir)
	
	_process_pending_deletions()


# ---------------------------------------------------------------------------
# Category registry
# ---------------------------------------------------------------------------

func register_category(category: String, dir_path: String) -> void:
	_category_dirs[category] = dir_path


func unregister_category(category: String) -> void:
	_category_dirs.erase(category)


func get_category_dir(category: String) -> String:
	return _category_dirs.get(category, "")


func _safe_name(raw: String, fallback: String = "") -> String:
	var value = raw.replace("\\", "/").strip_edges()
	value = value.replace("/", "_")
	var cleaned := ""
	for index in value.length():
		var code = value.ord_at(index)
		if code < 32 or code == 127:
			continue
		var character = value.substr(index, 1)
		if INVALID_NAME_CHARS.find(character) != -1:
			cleaned += "_"
		else:
			cleaned += character
	while cleaned.begins_with("."):
		cleaned = cleaned.substr(1)
	while cleaned.ends_with(".") or cleaned.ends_with(" "):
		cleaned = cleaned.substr(0, cleaned.length() - 1)
	cleaned = cleaned.strip_edges()
	if cleaned.length() > MAX_NAME_LENGTH:
		cleaned = cleaned.substr(0, MAX_NAME_LENGTH)
	if cleaned == "" or cleaned == "." or cleaned == "..":
		return fallback
	if cleaned.get_basename().to_lower() in RESERVED_NAMES:
		return fallback
	return cleaned


func _path_within(base_dir: String, path: String) -> bool:
	if base_dir == "" or path == "":
		return false
	var base = base_dir.replace("\\", "/").simplify_path().trim_suffix("/")
	var target = path.replace("\\", "/").simplify_path()
	if base == "" or target == "":
		return false
	return target == base or target.begins_with(base + "/")


func _is_managed_path(path: String) -> bool:
	if path == "":
		return false
	for category in _category_dirs:
		if _path_within(str(_category_dirs[category]), path):
			return true
	return false


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
	var total_bytes := 0

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
		src.close()
		if file_len > MAX_ENTRY_BYTES:
			emit_signal("status_message", "Failed to export, file too large (%.1f MB): %s" % [file_len / (1024.0 * 1024.0), src_path])
			return false
		total_bytes += file_len
		if total_bytes > MAX_PACK_FILE_BYTES:
			emit_signal("status_message", "Failed to export, package too large: " + src_path)
			return false

		packed_entries.append({
			"path": src_path,
			"file_name": src_path.get_file(),
			"category": category,
			"size": file_len,
		})

	var clean_name = _safe_name(package_name, "export")
	var base_dir = destination_dir
	var final_path = base_dir.plus_file(clean_name + PACK_EXT)
	if not _path_within(base_dir, final_path):
		emit_signal("status_message", "Failed to export, invalid package name: " + package_name)
		return false

	var out_file = File.new()
	if out_file.open(final_path, File.WRITE) != OK:
		# Scoped storage (Android 10+) blocks raw writes into shared folders
		# like Downloads without "All files access". Fall back to the app's
		# private external storage, which needs no permission.
		base_dir = "user://exports"
		if not dir.dir_exists(base_dir):
			dir.make_dir_recursive(base_dir)
		final_path = base_dir.plus_file(clean_name + PACK_EXT)
		if not _path_within(base_dir, final_path):
			emit_signal("status_message", "Failed to export, invalid package name: " + package_name)
			return false
		if out_file.open(final_path, File.WRITE) != OK:
			emit_signal("status_message", "Failed to export, couldn't write package: " + final_path)
			return false

	out_file.store_buffer(PACK_MAGIC.to_utf8())
	out_file.store_32(packed_entries.size())
	for packed in packed_entries:
		var src = File.new()
		if src.open(packed.path, File.READ) != OK:
			out_file.close()
			dir.remove(final_path)
			emit_signal("status_message", "Failed to export, couldn't read file: " + str(packed.path))
			return false
		out_file.store_pascal_string(str(packed.file_name))
		out_file.store_pascal_string(str(packed.category))
		out_file.store_64(int(packed.size))
		var remaining = int(packed.size)
		while remaining > 0:
			var chunk = src.get_buffer(min(PACK_CHUNK_BYTES, remaining))
			if chunk.size() == 0:
				break
			out_file.store_buffer(chunk)
			remaining -= chunk.size()
		src.close()
		if remaining > 0:
			out_file.close()
			dir.remove(final_path)
			emit_signal("status_message", "Failed to export, couldn't read file: " + str(packed.path))
			return false
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
	
	probe.seek(0)
	var head = probe.get_buffer(PACK_MAGIC.length())
	if head.get_string_from_ascii() == PACK_MAGIC:
		var streamed = _import_pack_stream(probe, path)
		probe.close()
		if streamed < 0:
			return false
		if streamed == 0:
			emit_signal("pack_import_failed", path, "nothing imported")
			emit_signal("status_message", "Package imported nothing: " + path)
			return false
		emit_signal("pack_imported", path, streamed)
		emit_signal("status_message", "Package imported %d file(s): %s" % [streamed, path])
		return true
	probe.seek(0)

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
		var safe_name = _safe_name(original_name)
		if safe_name == "":
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
		if not _path_within(dest_dir, dest_path):
			emit_signal("status_message", "Skipped file outside the target folder: " + original_name)
			continue
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


func _import_pack_stream(file: File, path: String) -> int:
	file.seek(PACK_MAGIC.length())
	var count = file.get_32()
	if count < 0 or count > 100000:
		emit_signal("pack_import_failed", path, "not a valid package")
		emit_signal("status_message", "Package is invalid: " + path)
		return -1

	var imported_count := 0
	var dir = Directory.new()

	for _index in range(count):
		if file.eof_reached():
			emit_signal("pack_import_failed", path, "package is truncated")
			emit_signal("status_message", "Package is truncated: " + path)
			return -1
		var original_name = file.get_pascal_string()
		var category = file.get_pascal_string()
		var size = file.get_64()

		if size < 0 or size > MAX_ENTRY_BYTES:
			if not _skip_bytes(file, size):
				emit_signal("pack_import_failed", path, "package is truncated")
				emit_signal("status_message", "Package is truncated: " + path)
				return -1
			emit_signal("status_message", "Skipped oversized file (%.1f MB): %s" % [size / (1024.0 * 1024.0), original_name])
			continue

		var safe_name = _safe_name(original_name)
		if safe_name == "":
			if not _skip_bytes(file, size):
				emit_signal("pack_import_failed", path, "package is truncated")
				emit_signal("status_message", "Package is truncated: " + path)
				return -1
			emit_signal("status_message", "Skipped file with unsafe name: " + original_name)
			continue

		var dest_dir = get_category_dir(category)
		if dest_dir == "":
			if not _skip_bytes(file, size):
				emit_signal("pack_import_failed", path, "package is truncated")
				emit_signal("status_message", "Package is truncated: " + path)
				return -1
			emit_signal("status_message", "Skipped file with unknown category '%s': %s" % [category, safe_name])
			continue

		if not dir.dir_exists(dest_dir):
			if dir.make_dir_recursive(dest_dir) != OK:
				emit_signal("status_message", "Failed to import, couldn't create dir: " + dest_dir)
				if not _skip_bytes(file, size):
					return -1
				continue

		var dest_path = dest_dir.plus_file(safe_name)
		if not _path_within(dest_dir, dest_path):
			if not _skip_bytes(file, size):
				emit_signal("pack_import_failed", path, "package is truncated")
				emit_signal("status_message", "Package is truncated: " + path)
				return -1
			emit_signal("status_message", "Skipped file outside the target folder: " + original_name)
			continue
		var out_file = File.new()
		if out_file.open(dest_path, File.WRITE) != OK:
			emit_signal("status_message", "Failed to import, couldn't write file: " + dest_path)
			if not _skip_bytes(file, size):
				return -1
			continue

		var remaining = size
		while remaining > 0:
			var chunk = file.get_buffer(min(PACK_CHUNK_BYTES, remaining))
			if chunk.size() == 0:
				break
			out_file.store_buffer(chunk)
			remaining -= chunk.size()
		out_file.close()
		if remaining > 0:
			emit_signal("pack_import_failed", path, "package is truncated")
			emit_signal("status_message", "Package is truncated: " + path)
			return -1

		emit_signal("file_copied", dest_path, category)
		imported_count += 1

	return imported_count


func _skip_bytes(file: File, count: int) -> bool:
	var remaining = count
	while remaining > 0:
		var chunk = file.get_buffer(min(PACK_CHUNK_BYTES, remaining))
		if chunk.size() == 0:
			return false
		remaining -= chunk.size()
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
		if !dir.current_is_dir() and (all_files or extensions.has("." + file_name.get_extension().to_lower())):
			results.append(directory.plus_file(file_name) if full_path else file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results


func copy_file_to_directory(path: String, directory: String, extensions: PoolStringArray, category: String) -> bool:
	var ext = "." + path.get_extension().to_lower()
	
	if ext == PACK_EXT:
		return import_pack(path)
	
	if ext != PACK_EXT and (ext == "." or ext in extensions) and _is_ymhpack(path):
		return import_pack(path)
	
	if extensions.size() > 0 and not extensions.has(ext):
		emit_signal("status_message", "Failed to copy file, it doesn't match the extensions: " + extensions.join(", "))
		return false
	
	var dir = Directory.new()
	if not dir.dir_exists(directory):
		var err = dir.make_dir_recursive(directory)
		if err != OK:
			emit_signal("status_message", "Failed to copy file, couldn't create dir: %s (error %d)" % [directory, err])
			return false
	
	var file_name = _safe_name(path.get_file())
	if file_name == "":
		emit_signal("status_message", "Failed to copy file, invalid file name: " + path)
		return false
	var dest_path = directory.plus_file(file_name)
	if not _path_within(directory, dest_path):
		emit_signal("status_message", "Failed to copy file, invalid destination: " + path)
		return false
	var err = dir.copy(path, dest_path)
	
	if err != OK:
		# Shared storage (e.g. Downloads on Android 10+) may reject the write;
		# fall back to the app's private external storage.
		var fallback_dir = "user://exports"
		if not dir.dir_exists(fallback_dir):
			dir.make_dir_recursive(fallback_dir)
		dest_path = fallback_dir.plus_file(file_name)
		err = dir.copy(path, dest_path)
	
	if err != OK:
		emit_signal("status_message", "Failed to copy file, error code: " + str(err))
		return false
	
	if not dir.file_exists(dest_path):
		emit_signal("status_message", "Copy reported OK but file not found at destination")
		return false
	
	emit_signal("status_message", "File copied and verified: " + dest_path)
	emit_signal("file_copied", dest_path, category)
	return true


func _is_ymhpack(path: String) -> bool:
	var probe = File.new()
	if not probe.file_exists(path):
		return false
	if probe.open(path, File.READ) != OK:
		return false
	var head = probe.get_buffer(min(probe.get_len(), PACK_SNIFF_BYTES))
	probe.close()
	if head.size() <= 0:
		return false
	return head.get_string_from_ascii().find(PACK_MAGIC) != -1


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
	var clean_name = _safe_name(list_name, "default")
	if clean_name == "":
		clean_name = "default"
	make_list_folder(list_dir_path)
	
	var to_save = data.duplicate(true)
	to_save["list_name"] = clean_name
	
	var path = list_dir_path.plus_file(clean_name) + LIST_EXT
	if not _path_within(list_dir_path, path):
		emit_signal("status_message", "Failed to save list, invalid name: " + list_name)
		return ""

	var file = File.new()
	if file.open(path, File.WRITE) == OK:
		file.store_string(to_json(to_save))
		file.close()
	else:
		emit_signal("status_message", "Failed to save list: " + clean_name)
	return clean_name


func load_list(list_dir_path: String, list_name: String) -> Dictionary:
	var clean_name = _safe_name(list_name)
	if clean_name == "":
		return {}
	var path = list_dir_path.plus_file(clean_name) + LIST_EXT
	if not _path_within(list_dir_path, path):
		return {}
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
	if not dir.dir_exists(list_dir_path):
		dir.make_dir_recursive(list_dir_path)
	var files = []
	var _directories = []
	dir.open(list_dir_path)
	dir.list_dir_begin(false, true)
	Global.add_dir_contents(dir, files, _directories, false, LIST_EXT)

	var items := []
	for path in files:
		var list_name = path.get_file().get_basename()
		var data = load_list(list_dir_path, list_name)
		if not data.empty():
			items.append(data)
	return items


func delete_list(list_dir_path: String, list_name: String) -> void:
	var clean_name = _safe_name(list_name)
	if clean_name == "":
		return
	var path = list_dir_path.plus_file(clean_name) + LIST_EXT
	if not _path_within(list_dir_path, path):
		return
	Directory.new().remove(path)


# ---------------------------------------------------------------------------
# Deferred deletion
# ---------------------------------------------------------------------------

const PENDING_DELETE_DIR: String = "user://lists"

func mark_for_deletion(paths: PoolStringArray) -> void:
	if paths.size() < 1:
		return
	
	var dir = Directory.new()
	if not dir.dir_exists(PENDING_DELETE_DIR):
		if dir.make_dir_recursive(PENDING_DELETE_DIR) != OK:
			push_warning("FileManager: failed to create %s" % PENDING_DELETE_DIR)
			return
	
	# Read the pending queue (if any), append, and write it back in one pass.
	var data: Array = []
	var file = File.new()
	if file.open(PENDING_DELETE_PATH, File.READ) == OK:
		var text = file.get_as_text()
		file.close()
		var parsed = _try_parse_json(text)
		if typeof(parsed) == TYPE_ARRAY:
			data = parsed
	
	for path in paths:
		if not _is_managed_path(path):
			push_warning("FileManager: refused to queue unmanaged path for deletion: %s" % path)
		elif not data.has(path):
			data.append(path)
	
	var out = File.new()
	if out.open(PENDING_DELETE_PATH, File.WRITE) == OK:
		out.store_string(to_json(data))
		out.close()
	else:
		emit_signal("status_message", "Failed to queue files for deletion")
		return


func unmark_for_deletion(path: String) -> void:
	if path == "":
		return
	var file = File.new()
	if file.open(PENDING_DELETE_PATH, File.READ) != OK:
		return
	var parsed = _try_parse_json(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_ARRAY:
		return
	var kept := []
	for entry in parsed:
		if str(entry) != path:
			kept.append(entry)
	if kept.size() == parsed.size():
		return
	if kept.empty():
		Directory.new().remove(PENDING_DELETE_PATH)
		return
	var out = File.new()
	if out.open(PENDING_DELETE_PATH, File.WRITE) == OK:
		out.store_string(to_json(kept))
		out.close()


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
			if typeof(path) != TYPE_STRING:
				continue
			if not _is_managed_path(path):
				push_warning("FileManager: skipped unmanaged pending deletion: %s" % path)
				continue
			dir.remove(path)
	
	Directory.new().remove(PENDING_DELETE_PATH)


# ---------------------------------------------------------------------------
# Generic list sorting shared by all list UIs (style list, mod list).
# Menus build an Array of item Dictionaries and call sort_items(); the
# resulting order is then applied to each menu's own scene tree.
# ---------------------------------------------------------------------------

enum SortMode { NAME, DATE, ACTIVE }

const SORT_LABELS := {
	SortMode.DATE: "Sort: Date",
	SortMode.NAME: "Sort: Name",
	SortMode.ACTIVE: "Sort: Active",
}

# Cycles the sort mode shared by every list menu's "Sort:" button
# (DATE -> NAME -> ACTIVE -> ...).
func next_sort_mode(mode: int) -> int:
	match mode:
		SortMode.DATE:
			return SortMode.NAME
		SortMode.NAME:
			return SortMode.ACTIVE
	return SortMode.DATE


func sort_label(mode: int) -> String:
	return SORT_LABELS.get(mode, SORT_LABELS[SortMode.DATE])

# Per-sort state for the comparator below.
var _sort_mode = SortMode.NAME
var _sort_inverted := false

# Sorts `items` (an Array of Dictionaries) in place and returns it. Each item:
#   "name":   String display name (also the tie-breaker)
#   "active": bool   - active entries come first in ACTIVE mode
#   "path":   String file path used for DATE mode (file modified time)
#   "modified": int  - optional precomputed modified time (replay rows); when
#                      absent/negative DATE mode stats the file instead
func sort_items(items: Array, mode: int, inverted: bool) -> Array:
	# Resolve each item's sort keys once (to_lower, filesystem stat) up
	# front instead of re-doing them on every comparison.
	var keyed := []
	for item in items:
		keyed.append({
			"name": str(item.get("name", "")).to_lower(),
			"active": bool(item.get("active", false)),
			"modified": _resolve_modified(item) if mode == SortMode.DATE else 0,
			"item": item,
		})
	_sort_mode = mode
	_sort_inverted = inverted
	keyed.sort_custom(self, "_compare_keyed")
	for i in keyed.size():
		items[i] = keyed[i]["item"]
	return items


func _resolve_modified(item: Dictionary) -> int:
	var t = item.get("modified", -1)
	if t < 0:
		var f := File.new()
		t = f.get_modified_time(item.get("path", ""))
	return t


func _compare_keyed(a: Dictionary, b: Dictionary) -> bool:
	if _sort_inverted:
		return _key_less(b, a)
	return _key_less(a, b)


func _key_less(a: Dictionary, b: Dictionary) -> bool:
	match _sort_mode:
		SortMode.DATE:
			if a["modified"] != b["modified"]:
				return a["modified"] > b["modified"]
			return a["name"] < b["name"]
		SortMode.ACTIVE:
			if a["active"] != b["active"]:
				return a["active"]
			return a["name"] < b["name"]
		SortMode.NAME:
			return a["name"] < b["name"]
	return a["name"] < b["name"]
