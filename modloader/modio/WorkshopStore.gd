extends Reference

const INBOX_DIR := "user://workshop_inbox"
const DB_PATH := "user://workshop_installed.json"
const STYLES_DIR := "user://custom"
const CACHE_DIR := "user://workshop_cache"

const MODIO_INBOX_DIR := "user://modio_inbox"
const MODIO_PENDING_DB := "user://modio_pending.json"
const COLLECTIONS_DB := "user://workshop_collections.json"

const WORKSHOP_APP_ID := 2212330
const STATE_SUBSCRIBED := 1


static func load_db() -> Dictionary:
	return _load_json(DB_PATH)


static func save_db(db: Dictionary) -> void:
	_save_json(DB_PATH, db)


static func get_entry(item_id) -> Dictionary:
	var db = load_db()
	var entry = db.get(str(item_id), {})
	return entry if typeof(entry) == TYPE_DICTIONARY else {}


static func is_managed(item_id) -> bool:
	return not get_entry(item_id).empty()


static func has_local_copies(entry: Dictionary) -> bool:
	if typeof(entry) != TYPE_DICTIONARY:
		return false
	for group in ["mods", "styles"]:
		var files = entry.get(group, [])
		if typeof(files) == TYPE_ARRAY and not files.empty():
			return true
	return false


static func record_subscription(item_id: int, meta: Dictionary) -> Dictionary:
	var db = load_db()
	var key = str(item_id)
	var entry = db.get(key, {})
	if typeof(entry) != TYPE_DICTIONARY:
		entry = {}
	entry["item_id"] = item_id
	entry["title"] = str(meta.get("title", entry.get("title", "")))
	entry["author"] = str(meta.get("author", entry.get("author", "")))
	entry["preview_url"] = str(meta.get("preview_url", entry.get("preview_url", "")))
	var updated = int(meta.get("time_updated", 0))
	if updated > 0:
		entry["time_updated"] = updated
	entry["state"] = "installed"
	entry["source"] = "steam"
	entry["installed_at"] = OS.get_unix_time()
	if typeof(entry.get("mods")) != TYPE_ARRAY:
		entry["mods"] = []
	if typeof(entry.get("styles")) != TYPE_ARRAY:
		entry["styles"] = []
	if typeof(entry.get("files")) != TYPE_DICTIONARY:
		entry["files"] = {"mods": [], "styles": []}
	db[key] = entry
	save_db(db)
	return entry


static func ensure_subscriptions() -> void:
	if not SteamHustle.STARTED:
		return
	if not Engine.has_singleton("Steam"):
		return
	if int(Steam.getAppID()) != WORKSHOP_APP_ID:
		return
	var db = load_db()
	for key in db.keys():
		if not str(key).is_valid_integer():
			continue
		var entry = db[key]
		if typeof(entry) != TYPE_DICTIONARY or not has_local_copies(entry):
			continue
		var item_id = int(key)
		if (int(Steam.getItemState(item_id)) & STATE_SUBSCRIBED) == 0:
			print("Workshop: re-subscribing " + str(item_id))
			Steam.subscribeItem(item_id)



static func stage_item(item_id: int, meta: Dictionary, source_folder: String) -> bool:
	if source_folder == "":
		return false
	var source_files := []
	_collect_files(source_folder, source_files)
	var item_dir = INBOX_DIR.plus_file(str(item_id))
	var staging_dir = INBOX_DIR.plus_file("." + str(item_id) + ".new")
	_delete_dir(staging_dir)
	_ensure_dir(staging_dir)

	var mod_files := []
	var style_files := []
	var copied := 0
	var failed := false
	for source_path in source_files:
		var extension = source_path.get_extension().to_lower()
		if extension != "zip" and extension != "ymhpack" and extension != "style":
			continue
		var file_name = source_path.get_file()
		var target_name = file_name
		if extension != "style":
			target_name = "%s_%s" % [str(item_id), file_name]
		var target_path = staging_dir.plus_file(target_name)
		var suffix := 1
		while File.new().file_exists(target_path):
			target_path = staging_dir.plus_file("%d_%s" % [suffix, target_name])
			suffix += 1
		if not _copy_file(source_path, target_path):
			failed = true
			continue
		if extension == "style":
			style_files.append(target_path.get_file())
		else:
			mod_files.append(target_path.get_file())
		copied += 1

	if failed or copied == 0:
		_delete_dir(staging_dir)
		return false

	_delete_dir(item_dir)
	if Directory.new().rename(staging_dir, item_dir) != OK:
		_delete_dir(staging_dir)
		return false

	var db = load_db()
	var entry = db.get(str(item_id), {})
	if typeof(entry) != TYPE_DICTIONARY:
		entry = {}
	entry["item_id"] = item_id
	entry["title"] = str(meta.get("title", entry.get("title", "")))
	entry["author"] = str(meta.get("author", entry.get("author", "")))
	entry["preview_url"] = str(meta.get("preview_url", entry.get("preview_url", "")))
	entry["time_updated"] = int(meta.get("time_updated", entry.get("time_updated", 0)))
	entry["files"] = {"mods": mod_files, "styles": style_files}
	entry["state"] = "pending"
	entry["queued_at"] = OS.get_unix_time()
	db[str(item_id)] = entry
	save_db(db)
	return true


static func install_pending() -> void:
	var db = load_db()
	if db.empty():
		return
	var mods_folder = mods_dir()
	_ensure_dir(mods_folder)
	_ensure_dir(STYLES_DIR)
	var changed := false

	for key in db.keys():
		var entry = db[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if not str(key).is_valid_integer():
			continue
		if str(entry.get("state", "")) != "pending":
			continue

		var item_dir = INBOX_DIR.plus_file(str(key))
		var files = entry.get("files", {})
		if typeof(files) != TYPE_DICTIONARY:
			files = {}

		var installed_mods := []
		var installed_styles := []
		var failed := false
		for file_name in files.get("mods", []):
			var safe_mod_name = _safe_file_name(str(file_name))
			if safe_mod_name == "":
				failed = true
				continue
			var target_path = mods_folder.plus_file(safe_mod_name)
			if _copy_file(item_dir.plus_file(safe_mod_name), target_path):
				installed_mods.append(target_path)
			else:
				failed = true

		for file_name in files.get("styles", []):
			var safe_style_name = _safe_file_name(str(file_name))
			if safe_style_name == "":
				failed = true
				continue
			var target_path = STYLES_DIR.plus_file(safe_style_name)
			if _copy_file(item_dir.plus_file(safe_style_name), target_path):
				installed_styles.append(target_path)
			else:
				failed = true

		if failed or (installed_mods.empty() and installed_styles.empty()):
			continue

		_remove_replaced_files(entry.get("mods", []), installed_mods)
		_remove_replaced_files(entry.get("styles", []), installed_styles)

		entry["mods"] = installed_mods
		entry["styles"] = installed_styles
		entry["state"] = "installed"
		entry["installed_at"] = OS.get_unix_time()
		db[key] = entry
		_delete_dir(item_dir)
		changed = true

	if changed:
		save_db(db)


static func _remove_replaced_files(old_files, new_files: Array) -> void:
	if typeof(old_files) != TYPE_ARRAY:
		return
	for path in old_files:
		var text = str(path)
		if text != "" and not (text in new_files):
			_remove_path(text)


static func uninstall(item_id) -> void:
	var db = load_db()
	var entry = db.get(str(item_id), {})
	if typeof(entry) == TYPE_DICTIONARY:
		var paths := PoolStringArray()
		for path in entry.get("mods", []):
			paths.append(str(path))
		for path in entry.get("styles", []):
			paths.append(str(path))
		if paths.size() > 0:
			FileManager.mark_for_deletion(paths)
	_delete_dir(INBOX_DIR.plus_file(str(item_id)))
	_remove_cache(item_id)
	db.erase(str(item_id))
	save_db(db)


static func _remove_cache(item_id) -> void:
	var dir = Directory.new()
	if dir.open(CACHE_DIR) != OK:
		return
	dir.list_dir_begin(true, true)
	var prefix = "workshop_%s_" % str(item_id)
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if not dir.current_is_dir() and file_name.begins_with(prefix) \
				and file_name.get_extension().to_lower() == "zip":
			dir.remove(CACHE_DIR.plus_file(file_name))
	dir.list_dir_end()


static func modio_pending() -> Dictionary:
	return _load_json(MODIO_PENDING_DB)


static func modio_download_path(item_id, file: Dictionary) -> String:
	var file_name = _safe_file_name(str(file.get("filename", "")))
	if file_name == "":
		file_name = "mod.zip"
	if not file_name.to_lower().ends_with(".zip"):
		file_name += ".zip"
	var item_dir = MODIO_INBOX_DIR.plus_file(str(item_id))
	_ensure_dir(item_dir)
	return item_dir.plus_file("modio_%s_%s" % [str(item_id), file_name])


static func modio_record_pending(item_id, meta: Dictionary, path: String, file: Dictionary) -> void:
	var db = modio_pending()
	db[str(item_id)] = {
		"file_id": int(file.get("id", 0)),
		"name": str(meta.get("name", "")),
		"profile_url": str(meta.get("profile_url", "")),
		"filename": path.get_file(),
		"user_id": int(meta.get("user_id", 0)),
	}
	_save_json(MODIO_PENDING_DB, db)


static func modio_discard(item_id) -> void:
	var db = modio_pending()
	db.erase(str(item_id))
	_save_json(MODIO_PENDING_DB, db)
	_delete_dir(MODIO_INBOX_DIR.plus_file(str(item_id)))


static func modio_install_pending() -> void:
	var pending = modio_pending()
	if pending.empty():
		return

	var mods_folder = mods_dir()
	var remaining := {}

	for key in pending.keys():
		var entry = pending[key]
		if typeof(entry) != TYPE_DICTIONARY or not str(key).is_valid_integer():
			remaining[key] = entry
			continue
		var file_name = _safe_file_name(str(entry.get("filename", "")))
		if file_name == "":
			remaining[key] = entry
			continue
		var source_path = MODIO_INBOX_DIR.plus_file(str(key)).plus_file(file_name)
		var target_path = mods_folder.plus_file(file_name)
		if not _copy_file(source_path, target_path):
			remaining[key] = entry
			continue

		var old = ModIO.get_installed(key)
		if typeof(old) == TYPE_DICTIONARY:
			var old_path = str(old.get("path", ""))
			if old_path != "" and old_path != target_path:
				_remove_path(old_path)

		ModIO.record_installed(key, {
			"file_id": int(entry.get("file_id", 0)),
			"path": target_path,
			"filename": file_name,
			"name": str(entry.get("name", "")),
			"profile_url": str(entry.get("profile_url", "")),
			"user_id": int(entry.get("user_id", 0)),
		})
		_delete_dir(MODIO_INBOX_DIR.plus_file(str(key)))

	_save_json(MODIO_PENDING_DB, remaining)


static func reconcile() -> void:
	var db = load_db()
	var db_changed := false
	for key in db.keys():
		var entry = db[key]
		if typeof(entry) != TYPE_DICTIONARY or not str(key).is_valid_integer():
			db.erase(key)
			db_changed = true
			continue
		var base_dir = INBOX_DIR.plus_file(str(key)) if str(entry.get("state", "")) == "pending" else ""
		if str(entry.get("state", "")) == "pending" and not _entry_files_exist(entry, base_dir):
			db.erase(key)
			_delete_dir(INBOX_DIR.plus_file(str(key)))
			db_changed = true
	if db_changed:
		save_db(db)

	var pending = modio_pending()
	var pending_changed := false
	for key in pending.keys():
		var entry = pending[key]
		var file_name = ""
		if typeof(entry) == TYPE_DICTIONARY:
			file_name = _safe_file_name(str(entry.get("filename", "")))
		if file_name == "" or not File.new().file_exists(MODIO_INBOX_DIR.plus_file(str(key)).plus_file(file_name)):
			pending.erase(key)
			_delete_dir(MODIO_INBOX_DIR.plus_file(str(key)))
			pending_changed = true
	if pending_changed:
		_save_json(MODIO_PENDING_DB, pending)

	ModIO.reconcile_installed()


static func _entry_files_exist(entry: Dictionary, base_dir: String) -> bool:
	for group in ["mods", "styles"]:
		var files = entry.get(group, [])
		if typeof(files) != TYPE_ARRAY:
			continue
		for path in files:
			var text = str(path)
			if text == "":
				continue
			var full_path = text
			if base_dir != "" and not text.begins_with("user://") \
					and not text.begins_with("res://") and not text.is_abs_path():
				full_path = base_dir.plus_file(text)
			if File.new().file_exists(full_path):
				return true
	return false


static func mods_dir() -> String:
	var path = "user://mods"
	if not OS.has_feature("mobile"):
		var exe_dir = OS.get_executable_path().get_base_dir()
		if OS.get_name() == "OSX":
			exe_dir = exe_dir.get_base_dir().get_base_dir().get_base_dir()
		path = exe_dir.plus_file("mods")
	_ensure_dir(path)
	return path


static func _load_json(path: String) -> Dictionary:
	var file = File.new()
	if not file.file_exists(path):
		return {}
	if file.open(path, File.READ) != OK:
		return {}
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error == OK and typeof(parsed.result) == TYPE_DICTIONARY:
		return parsed.result
	return {}


static func _save_json(path: String, data: Dictionary) -> void:
	_ensure_dir(path.get_base_dir())
	var file = File.new()
	if file.open(path, File.WRITE) != OK:
		return
	file.store_string(JSON.print(data, "  ", true))
	file.close()


static func _safe_file_name(file_name: String) -> String:
	var cleaned = file_name.strip_edges()
	for bad in ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		cleaned = cleaned.replace(bad, "_")
	var output := ""
	for index in cleaned.length():
		var code = cleaned.ord_at(index)
		if code < 32 or code == 127:
			continue
		output += cleaned.substr(index, 1)
	cleaned = output
	while cleaned.begins_with("."):
		cleaned = cleaned.substr(1)
	while cleaned.ends_with(".") or cleaned.ends_with(" "):
		cleaned = cleaned.substr(0, cleaned.length() - 1)
	if cleaned == "" or cleaned == "." or cleaned == "..":
		return ""
	if cleaned.length() > 120:
		cleaned = cleaned.substr(0, 120)
	return cleaned


static func _collect_files(folder: String, result: Array) -> void:
	var dir = Directory.new()
	if dir.open(folder) != OK:
		return
	dir.list_dir_begin(true, true)
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		var path = folder.plus_file(file_name)
		if dir.current_is_dir():
			_collect_files(path, result)
		else:
			result.append(path)
	dir.list_dir_end()


static func _ensure_dir(path: String) -> void:
	var dir = Directory.new()
	if not dir.dir_exists(path):
		dir.make_dir_recursive(path)


static func _copy_file(source_path: String, target_path: String) -> bool:
	if not File.new().file_exists(source_path):
		return false
	_ensure_dir(target_path.get_base_dir())
	var temp_path = target_path.get_base_dir().plus_file("." + target_path.get_file() + ".new")
	_remove_path(temp_path)
	if Directory.new().copy(source_path, temp_path) != OK:
		_remove_path(temp_path)
		return false
	_remove_path(target_path)
	if Directory.new().rename(temp_path, target_path) != OK:
		_remove_path(temp_path)
		return false
	return true


static func _remove_path(path: String) -> void:
	if path == "":
		return
	var dir = Directory.new()
	if dir.file_exists(path):
		dir.remove(path)


static func _delete_dir(path: String) -> void:
	var dir = Directory.new()
	if not dir.dir_exists(path):
		return
	dir.open(path)
	dir.list_dir_begin(true, true)
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		var child = path.plus_file(file_name)
		if dir.current_is_dir():
			_delete_dir(child)
		else:
			dir.remove(child)
	dir.list_dir_end()
	Directory.new().remove(path)

static func load_collections_db() -> Dictionary:
	var db = _load_json(COLLECTIONS_DB)
	if typeof(db.get("collections")) != TYPE_ARRAY:
		db["collections"] = []
	if not db.has("next_id"):
		db["next_id"] = 1
	return db


static func save_collections_db(db: Dictionary) -> void:
	_save_json(COLLECTIONS_DB, db)


static func list_collections() -> Array:
	var result := []
	for collection in load_collections_db().get("collections", []):
		if typeof(collection) == TYPE_DICTIONARY:
			result.append(collection)
	return result


static func get_collection(collection_id: int) -> Dictionary:
	for collection in list_collections():
		if int(collection.get("id", 0)) == collection_id:
			return collection
	return {}


static func create_collection(collection_name: String) -> Dictionary:
	var db = load_collections_db()
	var collection_id = int(db.get("next_id", 1))
	db["next_id"] = collection_id + 1
	var collection = {
		"id": collection_id,
		"name": collection_name,
		"summary": "Local Workshop collection",
		"workshop": true,
		"mods": [],
	}
	db["collections"].append(collection)
	save_collections_db(db)
	return collection


static func delete_collection(collection_id: int) -> void:
	var db = load_collections_db()
	var kept := []
	for collection in db.get("collections", []):
		if typeof(collection) == TYPE_DICTIONARY and int(collection.get("id", 0)) != collection_id:
			kept.append(collection)
	db["collections"] = kept
	save_collections_db(db)


static func add_item(collection_id: int, mod: Dictionary) -> bool:
	if mod.empty():
		return false
	var db = load_collections_db()
	var collections = db.get("collections", [])
	for index in range(collections.size()):
		var collection = collections[index]
		if typeof(collection) != TYPE_DICTIONARY or int(collection.get("id", 0)) != collection_id:
			continue
		var mods = collection.get("mods", [])
		if typeof(mods) != TYPE_ARRAY:
			mods = []
		var item_id = str(mod.get("id", ""))
		for existing in mods:
			if typeof(existing) == TYPE_DICTIONARY and str(existing.get("id", "")) == item_id:
				return false
		mods.append(_collection_snapshot(mod))
		collection["mods"] = mods
		collections[index] = collection
		db["collections"] = collections
		save_collections_db(db)
		return true
	return false


static func remove_item(collection_id: int, item_id) -> bool:
	var db = load_collections_db()
	var collections = db.get("collections", [])
	var key = str(item_id)
	for index in range(collections.size()):
		var collection = collections[index]
		if typeof(collection) != TYPE_DICTIONARY or int(collection.get("id", 0)) != collection_id:
			continue
		var mods = collection.get("mods", [])
		if typeof(mods) != TYPE_ARRAY:
			mods = []
		var kept := []
		var removed := false
		for existing in mods:
			if typeof(existing) == TYPE_DICTIONARY and str(existing.get("id", "")) == key:
				removed = true
				continue
			kept.append(existing)
		if not removed:
			return false
		collection["mods"] = kept
		collections[index] = collection
		db["collections"] = collections
		save_collections_db(db)
		return true
	return false


static func has_item(collection_id: int, item_id) -> bool:
	var collection = get_collection(collection_id)
	var key = str(item_id)
	for mod in collection.get("mods", []):
		if typeof(mod) == TYPE_DICTIONARY and str(mod.get("id", "")) == key:
			return true
	return false


static func _collection_snapshot(mod: Dictionary) -> Dictionary:
	var snapshot := {
		"id": str(mod.get("id", "")),
		"name": str(mod.get("name", "Workshop item")),
		"summary": str(mod.get("summary", "")),
		"description_plaintext": str(mod.get("description_plaintext", "")),
		"tags": mod.get("tags", []),
		"date_updated": int(mod.get("date_updated", 0)),
		"modfile": mod.get("modfile", {}),
		"logo": mod.get("logo", {}),
		"profile_url": str(mod.get("profile_url", "")),
		"homepage_url": "",
		"workshop": true,
		"workshop_time_updated": int(mod.get("workshop_time_updated", 0)),
		"workshop_author": str(mod.get("workshop_author", "Steam user")),
		"workshop_votes_up": int(mod.get("workshop_votes_up", 0)),
		"workshop_votes_down": int(mod.get("workshop_votes_down", 0)),
	}
	var author = mod.get("submitted_by", {})
	snapshot["submitted_by"] = author if typeof(author) == TYPE_DICTIONARY else {"display_name": "Steam user"}
	var stats = mod.get("stats", {})
	snapshot["stats"] = stats if typeof(stats) == TYPE_DICTIONARY else {}
	return snapshot