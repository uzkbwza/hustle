extends Node
# MODLOADER V1.1 

const CL_VERSION = "4.0.0"
const WORKSHOP_STORE := preload("res://modloader/modio/WorkshopStore.gd")
const GDUNZIP := preload("res://modloader/gdunzip/gdunzip.gd")

var _modZipFiles = []
var active_mods = []
var inactive_mods = []
var all_mods = [] 
var disabled_mod_names := {}
var _savedObjects = [] # Things to keep to ensure they are not garbage collected
var mods_w_overwrites = []
var mods_w_missing_depend = {}
var mods_w_load_errors = {}
var zips_by_name = {}
var active = false

# list of mods that have been historically merged with base game code
# and now should display a warning about it
# "metadata.name": "metadata.friendly_name"
var knownMergedModNames = {
	"char_loader": "Character Loader",
	"soupModOptions": "Mod Options Menu",
	"_tri_search_bar": "Better Character Select",
}
var hasMergedModInstalled = false
var shownMergedModWarning = false
var mergedModsDetected = {}

var charFolders = []

func _read_modded_json_text() -> String:
	var file = File.new()
	if file.open("user://modded.json", File.READ) != OK:
		return ""
	var text = file.get_as_text()
	file.close()
	return text


func _write_modded_json(data: Dictionary) -> void:
	var tmp_path = "user://modded.json.tmp"
	var file = File.new()
	if file.open(tmp_path, File.WRITE) != OK:
		push_warning("ModLoader: failed to write user://modded.json")
		return
	file.store_string(JSON.print(data, "  "))
	file.close()
	
	var dir = Directory.new()
	if dir.rename(tmp_path, "user://modded.json") != OK:
		push_warning("ModLoader: failed to commit user://modded.json")


func _init():
#	Steam.steamInit()
	_clear_import_packs()
	if not File.new().file_exists("user://modded.json"):
		_write_modded_json({"modsEnabled": true, "lastLaunchOk": true})
	
	var _modded_file = _parse_json_dict(_read_modded_json_text())
	
	# If modded.json is corrupted (bad JSON, wrong type, or missing/wrong-typed
	# keys), fall back to safe defaults and rewrite the file. We treat a
	# corrupted file the same as a crashed last launch: don't load mods,
	# and let the UI warn the user.
	var was_corrupted = false
	if _modded_file == null \
	or !_modded_file.has("modsEnabled") or typeof(_modded_file.modsEnabled) != TYPE_BOOL \
	or !_modded_file.has("lastLaunchOk") or typeof(_modded_file.lastLaunchOk) != TYPE_BOOL:
		was_corrupted = true
		_modded_file = {"modsEnabled": false, "lastLaunchOk": false}
		_write_modded_json(_modded_file)
	
	# Version-transition gate: first launch on a MOD_DISABLE_VERSIONS entry
	# (with an existing save) skips mod loading this session and flips
	# modsEnabled off in modded.json so the user has to deliberately
	# re-enable for the next session. The base version is logged in
	# player_data so the gate only fires once. UILayer.should_open_mod
	# _warning_window reads the flag and shows the warning explaining
	# the user can re-enable in options if they want.
	if Global.should_disable_mods_for_version_transition():
		Global.mods_disabled_by_version_transition = true
		Global.mark_mod_sensitive_version_opened(Global.current_base_version())
		_modded_file.modsEnabled = false
		_write_modded_json(_modded_file)
		return
	
	# Crash gate: last session never reached the "finished booting" checkpoint
	# (or the file itself was corrupted, which is its own sign of a crash
	# mid-write). Skip mod loading this session, flag it for the UI to show a
	# warning, and let the options screen lock the toggle so the user has to
	# consciously re-enable mods. The flag stays false until main.gd reaches
	# the end of its _ready(), so a crash during this safeboot is noticed too.
	if was_corrupted or !_modded_file.lastLaunchOk:
		Global.mods_disabled_by_crash = true
		_modded_file.modsEnabled = false
		_write_modded_json(_modded_file)
		return
	
	if !_modded_file.modsEnabled:
		return
	
	# From this point on we're actually attempting to load mods.
	# Mark the flag dirty on disk BEFORE doing anything risky, so a
	# crash during loading leaves "lastLaunchOk": false behind.
	_modded_file.lastLaunchOk = false
	_write_modded_json(_modded_file)
	
	installScriptExtension("res://modloader/MLStateSounds.gd") 
	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
#
#	var dir = Directory.new()
#	if !dir.dir_exists(gameInstallDirectory.plus_file("mods")):
#		dir.make_dir_recursive(gameInstallDirectory.plus_file("mods").plus_file("workshop_upload"))
#
	Steam.steamInit() # needed to get workshop mods.
	active = true
#	Global.VERSION += " Modded" 
	_load_disabled_mods()
	WORKSHOP_STORE.install_pending()
	WORKSHOP_STORE.modio_install_pending()
	WORKSHOP_STORE.reconcile()
	#This script has to be installed before the mods or else it doesn't get extended
	_loadMods()
	print("----------------mods------loaded--------------------")
	_initMods()
	print("----------------mods initialized--------------------")
	installScriptExtension("res://modloader/ModHashCheck.gd")
	call_deferred("append_hash")


func mark_launch_clean() -> void:
	var data = _parse_json_dict(_read_modded_json_text())
	if data == null:
		return
	if data.get("lastLaunchOk", false):
		return
	data["lastLaunchOk"] = true
	_write_modded_json(data)


# Char select packs each mod import into its own file under
# user://mod_temp_packs and keeps it mounted for the session; clear them at
# startup, before anything is mounted. Also the old shared imagepack.pck and
# leftover import temp files.
func _clear_import_packs():
	var dir = Directory.new()
	if dir.dir_exists("user://mod_temp_packs"):
		for f in _get_all_files("user://mod_temp_packs", "pck"):
			dir.remove(f)
	if dir.file_exists("user://imagepack.pck"):
		dir.remove("user://imagepack.pck")
	# temp files of an import that didn't finish (crash, quit mid-load)
	if dir.dir_exists("user://mod_temp"):
		for f in _get_all_files("user://mod_temp"):
			dir.remove(f)
		dir.remove("user://mod_temp")


# Parses a JSON string and returns it only if it's a valid Dictionary.
# Returns null on parse errors or unexpected top-level types (e.g. a
# truncated/corrupted file), so callers can treat that as "no usable data"
# instead of accessing a null result and crashing.
func _parse_json_dict(text: String):
	var parsed = JSON.parse(text)
	if parsed.error != OK:
		return null
	if typeof(parsed.result) != TYPE_DICTIONARY:
		return null
	return parsed.result


func _load_disabled_mods():
	disabled_mod_names = {}
	var path = "user://lists/mods/_current_state.ymhlist"
	var f = File.new()
	if not f.file_exists(path):
		return
	f.open(path, File.READ)
	var text = f.get_as_text()
	f.close()
	
	var state = _parse_json_dict(text)
	if state == null:
		return
	
	var data = state.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	for mod_name in data.get("inactive", []):
		disabled_mod_names[mod_name] = true


func append_hash():
#	return
	var hashes = Network._get_hashes(ModLoader.active_mods)
	var h = ""
	for hash_ in hashes:
		h += hash_
	if SteamHustle.STARTED:
		if h != "":
			Global.VERSION += "-" + ("%10x" % hash(h)).strip_edges()
		else:
			Global.VERSION = Global.VERSION.split(" Modded")[0]


func _loadMods():
	var mod_paths := _collect_mod_paths()
	_load_mod_packs(mod_paths)

func _collect_mod_paths() -> Array:
	var paths := []
	var game_install_directory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		game_install_directory = game_install_directory.get_base_dir().get_base_dir().get_base_dir()
	_collect_folder_paths(game_install_directory.plus_file("mods"), paths)

	if SteamHustle.STARTED and SteamHustle.WORKSHOP_ENABLED:
		var workshop = SteamWorkshop.new()
		for item in Steam.getSubscribedItems():
			if WORKSHOP_STORE.is_managed(item):
				continue
			var info = workshop.get_item_install_info(item)
			if info.get("ret", false):
				_collect_folder_paths(info.folder, paths, true)

	if Global.is_mobile_device:
		_collect_folder_paths("user://mods", paths, true)
	return paths

func _collect_folder_paths(folder: String, paths: Array, zip_only := false) -> void:
	print("looking for mods in folder: " + folder)
	var dir = Directory.new()
	if dir.open(folder) != OK:
		return
	if dir.list_dir_begin(true, true) != OK:
		return
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		var path: String = folder.plus_file(file_name)
		if zip_only and path.get_extension().to_lower() != "zip":
			continue
		if not path in paths:
			paths.append(path)
	dir.list_dir_end()

func _load_mod_packs(paths: Array) -> void:
	var candidates := []
	var seen_names := {}
	for path in paths:
		var extension = path.get_extension().to_lower()
		if extension == "ymhpack":
			continue
		if extension != "zip":
			_mount_pack(path)
			continue
		var found := _inspect_mod_zip(path)
		if found.empty():
			_mount_pack(path)
			continue
		for candidate in found:
			var mod_name: String = candidate.metadata.name
			if seen_names.has(mod_name):
				print("Duplicate mod name, skipping: " + mod_name)
				continue
			seen_names[mod_name] = true
			zips_by_name[mod_name] = path
			if knownMergedModNames.has(mod_name):
				mergedModsDetected[mod_name] = true
				hasMergedModInstalled = true
				continue
			candidates.append(candidate)
	_resolve_and_mount(candidates)

func _mount_pack(path: String) -> bool:
	var global_path = ProjectSettings.globalize_path(path)
	if not ProjectSettings.load_resource_pack(global_path, true):
		return false
	_modZipFiles.append(path)
	return true

func _inspect_mod_zip(zip_path: String) -> Array:
	var found := []
	var gdunzip = GDUNZIP.new()
	if not gdunzip.load(zip_path):
		print("Mod is not a readable zip: " + zip_path)
		return found

	var native_entries := {}
	var modmain_entries := []
	for mod_entry_path in gdunzip.files:
		if mod_entry_path.ends_with("/"):
			continue
		if not _is_safe_entry_path(mod_entry_path):
			print("Skipping unsafe archive path: " + zip_path + " -> " + str(mod_entry_path))
			continue
		var mod_entry_name = mod_entry_path.get_file().to_lower()
		if _native_extension(mod_entry_path) and mod_entry_path.find("/") != -1:
			native_entries[mod_entry_path] = int(gdunzip.files[mod_entry_path].get("uncompressed_size", -1))
		if mod_entry_name.begins_with("modmain") and mod_entry_name.ends_with(".gd"):
			modmain_entries.append(mod_entry_path)

	for mod_entry_path in modmain_entries:
		var mod_sub_folder = mod_entry_path.get_base_dir()
		if mod_sub_folder == ".":
			mod_sub_folder = ""
		var metadata_entry = mod_sub_folder + "/_metadata" if mod_sub_folder != "" else "_metadata"
		var metadata = _read_metadata_from_zip(gdunzip, metadata_entry)
		if metadata == null:
			print("No readable _metadata in mod: " + zip_path)
			continue
		var error = _validate_metadata(metadata)
		if error != "":
			print("Metadata error in " + zip_path + ": " + error)
			continue
		metadata.zip_path = zip_path
		found.append({
			"path": zip_path,
			"subfolder": mod_sub_folder,
			"script_path": "res://" + mod_entry_path,
			"native": _native_entries_from(native_entries, mod_sub_folder),
			"metadata": metadata,
		})

	if found.empty():
		print("No ModMain found in mod: " + zip_path)
	return found


func _read_metadata_from_zip(gdunzip, entry_path: String):
	if not entry_path in gdunzip.files:
		return null
	var bytes = gdunzip.uncompress(entry_path)
	if typeof(bytes) != TYPE_RAW_ARRAY:
		return null
	var parsed = JSON.parse(bytes.get_string_from_utf8())
	if parsed.error != OK or typeof(parsed.result) != TYPE_DICTIONARY:
		return null
	return parsed.result

func _native_extension(entry_path: String) -> bool:
	var extension = entry_path.get_extension().to_lower()
	if OS.get_name() == "Windows":
		return extension == "dll"
	if OS.get_name() == "X11":
		return extension == "so"
	if OS.get_name() == "OSX":
		return extension == "dylib"
	return false


func _is_safe_entry_path(entry_path: String) -> bool:
	if entry_path == "":
		return false
	var normalized = entry_path.replace("\\", "/")
	if normalized.begins_with("/") or normalized.begins_with("~"):
		return false
	if normalized.find(":") != -1:
		return false
	for part in normalized.split("/"):
		if part == "" or part == "." or part == "..":
			return false
	return true


func _res_path(entry_path: String) -> String:
	if not _is_safe_entry_path(entry_path):
		return ""
	return ProjectSettings.globalize_path("res://" + entry_path)


func _native_entries_from(all_entries: Dictionary, mod_sub_folder: String) -> Dictionary:
	var entries := {}
	for entry_path in all_entries:
		if mod_sub_folder != "" and not entry_path.begins_with(mod_sub_folder + "/"):
			continue
		entries[entry_path] = int(all_entries[entry_path])
	return entries


func _native_folders_writable(candidate: Dictionary) -> bool:
	var checked := {}
	for entry_path in candidate.native:
		var folder = _res_path(entry_path.get_base_dir())
		if folder == "":
			return false
		if checked.has(folder):
			continue
		checked[folder] = true
		var directory = Directory.new()
		directory.make_dir_recursive(folder)
		var probe_path = folder.plus_file(".modloader_write_test")
		var probe = File.new()
		if probe.open(probe_path, File.WRITE) != OK:
			return false
		probe.store_string("")
		probe.close()
		directory.remove(probe_path)
	return true


func _extract_native_files(candidate: Dictionary) -> String:
	var written := []
	for entry_path in candidate.native:
		var target_path = _res_path(entry_path)
		if target_path == "":
			_remove_files(written)
			return "the mod contains an unsafe file path: " + str(entry_path)
		var expected_size = int(candidate.native[entry_path])
		if expected_size >= 0 and _file_size(target_path) == expected_size:
			continue

		var directory = Directory.new()
		directory.make_dir_recursive(target_path.get_base_dir())
		var backup_path = target_path + ".old"
		var had_target = directory.file_exists(target_path)
		if had_target and directory.rename(target_path, backup_path) != OK:
			_remove_files(written)
			return "native file could not be replaced: " + entry_path.get_file()

		var source = File.new()
		if source.open("res://" + entry_path, File.READ) != OK:
			if had_target:
				directory.rename(backup_path, target_path)
			_remove_files(written)
			return "native file could not be read: " + entry_path.get_file()
		var bytes = source.get_buffer(source.get_len())
		source.close()

		var temp_path = target_path + ".tmp"
		var output = File.new()
		if output.open(temp_path, File.WRITE) != OK:
			if had_target:
				directory.rename(backup_path, target_path)
			_remove_files(written)
			return "the game folder is not writable"
		output.store_buffer(bytes)
		output.close()

		if directory.rename(temp_path, target_path) != OK:
			directory.remove(temp_path)
			if had_target:
				directory.rename(backup_path, target_path)
			_remove_files(written)
			return "native file could not be written: " + entry_path.get_file()
		if had_target:
			directory.remove(backup_path)
		written.append(target_path)
	return ""


func _file_size(path: String) -> int:
	var file = File.new()
	if file.open(path, File.READ) != OK:
		return -1
	var size = file.get_len()
	file.close()
	return size


func _remove_files(paths: Array) -> void:
	var directory = Directory.new()
	for path in paths:
		directory.remove(path)

func _validate_metadata(metadata) -> String:
	if typeof(metadata) != TYPE_DICTIONARY:
		return "Metadata is not a JSON object"
	var error = _verifyMetadata(metadata)
	if error != null:
		return str(error)

	if str(metadata.get("name", "")).strip_edges() == "":
		return "Metadata has no name"
	if typeof(metadata.get("requires")) != TYPE_ARRAY:
		return "requires must be a list"
	if typeof(metadata.get("overwrites")) != TYPE_BOOL:
		return "overwrites must be true or false"
	if typeof(metadata.get("priority")) != TYPE_INT and typeof(metadata.get("priority")) != TYPE_REAL:
		return "priority must be a number"

	for key in ["description", "author", "version", "link", "id", "friendly_name"]:
		if typeof(metadata.get(key)) != TYPE_STRING:
			metadata[key] = str(metadata.get(key, ""))
	if metadata.friendly_name.strip_edges() == "":
		metadata["friendly_name"] = metadata.name

	var requires := []
	for required in metadata.requires:
		var dependency = str(required).strip_edges()
		if dependency != "":
			requires.append(dependency)
	metadata["requires"] = requires
	return ""

func _resolve_and_mount(candidates: Array) -> void:
	var by_name := {}
	var loadable := {}
	var mounted := {}
	for candidate in candidates:
		var mod_name: String = candidate.metadata.name
		by_name[mod_name] = candidate
		if not disabled_mod_names.has(mod_name):
			loadable[mod_name] = true

	for mod_name in loadable.keys():
		var candidate = by_name[mod_name]
		if candidate.native.empty() or _native_folders_writable(candidate):
			continue
		mods_w_load_errors[str(candidate.metadata.friendly_name)] = "the game folder is not writable"
		loadable.erase(mod_name)

	var dependents := {}
	var waiting := {}
	var failed := {}
	for mod_name in loadable.keys():
		waiting[mod_name] = 0
	for mod_name in loadable.keys():
		for required in by_name[mod_name].metadata.get("requires", []):
			var dependency = str(required).strip_edges()
			if dependency == "" or dependency == "char_loader" or dependency == "soupModOptions":
				continue
			if loadable.has(dependency):
				waiting[mod_name] = int(waiting[mod_name]) + 1
				if not dependents.has(dependency):
					dependents[dependency] = []
				dependents[dependency].append(mod_name)
			else:
				failed[mod_name] = true
	var queue := []
	for mod_name in loadable.keys():
		if int(waiting[mod_name]) == 0:
			queue.append(mod_name)
	var resolved := {}
	while not queue.empty():
		var mod_name = queue.pop_front()
		if resolved.has(mod_name):
			continue
		resolved[mod_name] = not failed.has(mod_name)
		for dependent in dependents.get(mod_name, []):
			if not resolved[mod_name]:
				failed[dependent] = true
			waiting[dependent] = int(waiting[dependent]) - 1
			if int(waiting[dependent]) == 0:
				queue.append(dependent)
	for mod_name in loadable.keys():
		if not resolved.get(mod_name, false):
			loadable.erase(mod_name)

	for candidate in candidates:
		var metadata: Dictionary = candidate.metadata
		if disabled_mod_names.has(metadata.name):
			var inactive_info = [_hash_file(candidate.path), metadata]
			all_mods.append(inactive_info)
			inactive_mods.append(inactive_info)
			continue

		if not loadable.has(metadata.name):
			if mods_w_load_errors.has(str(metadata.friendly_name)):
				print(str(metadata.friendly_name) + ": " + str(mods_w_load_errors[str(metadata.friendly_name)]))
				continue
			var missing = _missing_dependencies(metadata, loadable)
			print(str(metadata.friendly_name) + ": Missing Dependency: " + str(missing))
			mods_w_missing_depend[metadata.friendly_name] = missing
			all_mods.append([_hash_file(candidate.path), metadata])
			continue

		if not mounted.has(candidate.path):
			mounted[candidate.path] = _mount_pack(candidate.path)
		if not mounted[candidate.path]:
			var reason = "the mod archive could not be mounted"
			print(str(metadata.friendly_name) + ": " + reason)
			loadable.erase(metadata.name)
			mods_w_load_errors[str(metadata.friendly_name)] = reason
			all_mods.append([_hash_file(candidate.path), metadata])

	for candidate in candidates:
		var metadata: Dictionary = candidate.metadata
		if disabled_mod_names.has(metadata.name) or not loadable.has(metadata.name):
			continue
		if not mounted.get(candidate.path, false):
			continue
		var problem := _extract_native_files(candidate)
		if problem == "":
			continue
		print(str(metadata.friendly_name) + ": " + problem)
		loadable.erase(metadata.name)
		mods_w_load_errors[str(metadata.friendly_name)] = problem
		all_mods.append([_hash_file(candidate.path), metadata])

	for candidate in candidates:
		var metadata: Dictionary = candidate.metadata
		if disabled_mod_names.has(metadata.name) or not loadable.has(metadata.name):
			continue
		if not mounted.get(candidate.path, false):
			continue

		var script = ResourceLoader.load(candidate.script_path)
		if script == null or not script.can_instance():
			var reason = "the mod script could not be loaded"
			print(str(metadata.friendly_name) + ": " + reason)
			mods_w_load_errors[str(metadata.friendly_name)] = reason
			all_mods.append([_hash_file(candidate.path), metadata])
			continue

		var mod_info = [script, _hash_file(candidate.path), metadata]
		all_mods.append(mod_info)
		active_mods.append(mod_info)
		if metadata.overwrites:
			mods_w_overwrites.append({"subfolder": candidate.subfolder, "priority": metadata.priority})

func _missing_dependencies(metadata: Dictionary, available: Dictionary) -> Array:
	var missing := []
	for dependency in metadata.get("requires", []):
		var name = str(dependency).strip_edges()
		if name == "" or name == "char_loader" or name == "soupModOptions":
			continue
		if not available.has(name):
			missing.append(name)
	return missing

# Load and run any ModMain.gd scripts which were present in mod ZIP files.
# Attach the script instances to this singleton's scene to keep them alive.
func _initMods():
	active_mods.sort_custom(self, "_compareScriptPriority")
	for item in active_mods:
		var script_instance = item[0].new(self)
		add_child(script_instance)
		print("Loaded " + item[2].friendly_name)
		item.remove(0)
	mods_w_overwrites.sort_custom(self, "_compareOverwritePriority")
	var does_exist = File.new()
	for item in mods_w_overwrites:
		for character in Global.name_paths:
			if does_exist.file_exists(Global.name_paths.get(character)):
				_overwriteCharacterTexs(item.subfolder, character)

func _compareOverwritePriority(a, b) -> bool:
	if a.priority != b.priority:
		return a.priority < b.priority
	return a.subfolder < b.subfolder
	

# Compares metadata priority, and if the same, uses the resource path of the Packed Scene
func _compareScriptPriority(a, b):
	var aPrio = a[2].priority
	var bPrio = b[2].priority
	if aPrio != bPrio:
		return aPrio < bPrio
	# Ensure that the result is deterministic, even when the priority is the same
	var aPath = a[0].resource_path
	var bPath = b[0].resource_path
	if aPath != bPath:
		return aPath < bPath
	return false

func installScriptExtension(childScriptPath:String):
	var childScript = ResourceLoader.load(childScriptPath)
	# Force Godot to compile the script now.
	# We need to do this here to ensure that the inheritance chain isz
	# properly set up, and multiple mods can chain-extend the same
	# class multiple times.
	# This is also needed to make Godot instantiate the extended class
	# when creating singletons.
	# The actual instance is thrown away.
	childScript.new()
	var parentScript = childScript.get_base_script()
	if parentScript == null:
		print("Missing dependencies")
	else:
		if parentScript.resource_path != "res://Network.gd" or childScript.resource_path == "res://modloader/ModHashCheck.gd":
			var parentScriptPath = parentScript.resource_path
			childScript.take_over_path(parentScriptPath)
		else:
			print("You can't access network!")

func appendNodeInScene(modifiedScene, nodeName:String = "", nodeParent = null, instancePath:String = "", isVisible:bool = true):
	var newNode
	if instancePath != "":
		newNode = load(instancePath).instance()
	else:
		newNode = Node.instance()
	if nodeName != "":
		newNode.name = nodeName
	if isVisible == false:
		newNode.visible = false
	if nodeParent != null:
		var tmpNode = modifiedScene.get_node(nodeParent)
		tmpNode.add_child(newNode)
		newNode.set_owner(modifiedScene)
	else:
		modifiedScene.add_child(newNode)
		newNode.set_owner(modifiedScene)

func saveScene(modifiedScene, scenePath:String):
	var packed_scene = PackedScene.new()
	packed_scene.pack(modifiedScene)
	packed_scene.take_over_path(scenePath)
	_savedObjects.append(packed_scene)
	
func _getTexsFromSheet(spritePath, columns, rows):
	pass

func _overwriteCharacterTexs(modFolderName, charName): #Base Asset replacement support
	#Load all custom user overwrites
	var charImages = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName, "png")
	var mediaSounds = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName + "/Sounds/BaseSounds", "wav")
	var mediaStateSounds = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName + "/Sounds/StateSounds", "wav")
	var charActionImages = _get_all_files("res://" + modFolderName + "/Overwrites/" + charName + "/Buttons", "png")
	mediaSounds.sort() #Sorts the array alphabetically
	mediaStateSounds.sort() 
	
	#Instantiate replacable assets: visuals
	var instCharTS = load(Global.name_paths.get(charName)).instance()
	var instCharAnim = instCharTS.get_node("Flip/Sprite")
	var instCharFrames = instCharAnim.get_sprite_frames()
	
	#Instantiate replacable assets: sounds
	var instCharSounds = instCharTS.get_node("Sounds").get_children()
	var instCharStates = instCharTS.get_node("StateMachine").get_children()
	
	#Replace all images in animation frames
	for media in charImages:
		var newFrameTex = textureGet(media)
		if media.split('/')[-2].to_lower() == 'wait':
			instCharTS.character_portrait = newFrameTex
		if charName == "Cowboy" and media.split("/")[ - 3] == "ShootingArm":
			instCharAnim = instCharTS.get_node("Flip/ShootingArm")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		#Changes the sprite for the in air sprite because it's a seperate node like cowboys arm. -Valkarin
		elif charName == "Wizard" and media.split("/")[ - 3 ] == "LiftoffAir":
			instCharAnim = instCharTS.get_node("Flip/LiftoffSprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		elif charName == "Robot" and media.split("/")[ - 3 ] == "ChainsawArm":
			instCharAnim = instCharTS.get_node("Flip/ChainsawArm")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		elif charName == "Robot" and media.split("/")[ - 3 ] == "DriveJumpSprite":
			instCharAnim = instCharTS.get_node("Flip/DriveJumpSprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			# after 2 years mutant is now fixed for overwrites :P -Fleig
		elif charName == "Mutant" and media.split("/")[ - 3 ] == "TwistAttackSprite":
			instCharAnim = instCharTS.get_node("Flip/TwistAttackSprite")
			instCharFrames = instCharAnim.get_sprite_frames()
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			instCharAnim = instCharTS.get_node("Flip/Sprite")
			instCharFrames = instCharAnim.get_sprite_frames()
		else :
			instCharFrames.set_frame(media.split("/")[ - 2], int(media.get_file()), newFrameTex)
			
	#Replace all base character sounds
	for charSound in instCharSounds:
		for media in mediaSounds:
			if media.get_file().split('.')[0] == charSound.name:
				var mediaStream = loadSound(media)
				charSound.set_stream(mediaStream)
				
				charSound.pitch_scale = 2
				
	#Iterate through character states
	for state in instCharStates:
		#Replace all character state sounds
		for media in mediaStateSounds:
			#Gets the name of the file so it can focus on just the underscore
			#".' is there because get_extnsion don't include it
			var media_name = media.get_file().trim_suffix("."+media.get_extension()) 
			if media_name.split('_')[0] == state.name:
				var mediaStream = loadSound(media)
				
				#This checks to see if the name has enter stating that it's a on enter sfx
				if media_name.split('_')[-1] != 'enter':
					#if it isn't then it will set enter_sfx to null incase there isn't one
					state.sfx = mediaStream
					state.enter_sfx = null
				else:
					#sets the enter_sfx if it's in the name
					state.enter_sfx = mediaStream
				#state.pitch_var = 0.0 #Sets the current state pitch_variation to 0
				state.pitch_scale = 2
		#Replace button textures
		if state.button_texture != null:
			for button in charActionImages:
				var buttonName = button.get_file().trim_suffix("."+button.get_extension())
				if buttonName == state.name:
					var newButtonTex = textureGet(button)
					state.button_texture = newButtonTex
			
	#Save out the scene
	saveScene(instCharTS, Global.name_paths.get(charName))
	instCharTS.queue_free()

func _get_all_files(path: String, file_ext := "", files := [], full_path := true): #https://gist.github.com/hiulit/772b8784436898fd7f942750ad99e33e
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				files = _get_all_files(dir.get_current_dir().plus_file(file_name), file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue
				if full_path:
					files.append(dir.get_current_dir().plus_file(file_name))
				else:
					files.append(file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)
	return files
		
func textureGet(imagePath): #Snippet by: 
	var image = Image.new()
	var err = image.load(imagePath)
	if err != OK:
		return 0
	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	return tex
	
func loadSound(soundPath): # Just moved it over here so that it can be used by other people, even tho this only supports wav -Fleig
	var file = File.new()
	file.open(soundPath, File.READ)
	var buffer = file.get_buffer(file.get_len())
	var stream = AudioStreamSample.new()
	stream.format = AudioStreamSample.FORMAT_16_BITS
	stream.data = buffer
	file.close()
	return stream

func _hash_file(path):
	var file = File.new()
	var modZIPHash = file.get_md5(path)
	file.close()
	return modZIPHash
	
func _readMetadata(mdFSPath):
	var file = File.new()
	if not file.file_exists(mdFSPath):
		return null
	if file.open(mdFSPath, File.READ) != OK:
		return null
	var parsed = JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK:
		return null
	return parsed.result


func _verifyMetadata(metadataVar):
	var mdString = JSON.print(metadataVar)
	var error : String = ""
	error = validate_json(mdString)
	if error : return "Invalid JSON data passed with message: " + error
	var schema = [
		"name",
		"friendly_name",
		"description",
		"author",
		"version",
		"link",
		"id",
		"overwrites",
		"requires",
		"priority",
	]
	if !metadataVar.has_all(schema):
		return "Metadata is missing fields"
	for key in metadataVar:
		if key == null:
			return key +" is empty"

func add_character_folder(path):
	if !(path in charFolders):
		charFolders.append(path)

#Valk's script for grabbing all gdscripts from a path
func get_scripts(path):
	var scripts = []
	var dir = Directory.new()
	dir.open(path)
	
	if not dir.list_dir_begin() == OK:
		print("FAILED TO LOAD SCRIPTS")
		return
	
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with('.') and file.ends_with(".gd"):
			scripts.append(file)
			
	dir.list_dir_end()
	return scripts
