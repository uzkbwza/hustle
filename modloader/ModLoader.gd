extends Node
# MODLOADER V1.1

const CL_VERSION = "4.1.0"
const WORKSHOP_STORE := preload("res://modloader/modio/WorkshopStore.gd")
const GDUNZIP := preload("res://modloader/gdunzip/gdunzip.gd")
const GDZIP_WRITER := preload("res://modloader/gdunzip/gdzip.gd")
const WORKSHOP_CACHE_DIR := "user://workshop_cache"

var _modZipFiles = []
var _file_hashes = {}
var active_mods = []
var inactive_mods = []
var all_mods = []
var disabled_mod_names := {}
var _savedObjects = [] # Things to keep to ensure they are not garbage collected
var mods_w_overwrites = []
var mods_w_missing_depend = {}
var mods_w_load_errors = {}
var mods_w_depend = []
var zips_by_name = {}
var active = false

var _mods_allowed = false
var _mods_load_reason = "not checked yet"
var _pending_mod_files = []
var _boot_progress = null
var _boot_log_file = null
var _abort_requested = false
var last_step_ms = 0

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
	if dir.file_exists("user://modded.json"):
		dir.remove("user://modded.json")
	if dir.rename(tmp_path, "user://modded.json") != OK:
		push_warning("ModLoader: failed to commit user://modded.json")


func _init():
#	Steam.steamInit()
	if not File.new().file_exists("user://modded.json"):
		_write_modded_json({"modsEnabled": true, "lastLaunchOk": true})

	var _modded_file = _parse_json_dict(_read_modded_json_text())

	# If modded.json is corrupted (bad JSON, wrong type, or missing/wrong-typed
	# keys), fall back to safe defaults and rewrite the file. We treat a
	# corrupted file the same as a crashed last launch: don't load mods,
	# and let the UI warn the user.
	var was_corrupted = false
	if _modded_file == null \
	or !_modded_file.has("modsEnabled") or typeof(_modded_file.modsEnabled) != TYPE_BOOL:
		was_corrupted = true
		_modded_file = {"modsEnabled": false, "lastLaunchOk": false}
		_write_modded_json(_modded_file)
		print("ModLoader: modded.json could not be read, loading without mods")
	elif !_modded_file.has("lastLaunchOk") or typeof(_modded_file.lastLaunchOk) != TYPE_BOOL:
		_modded_file["lastLaunchOk"] = true
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
		_mods_load_reason = "mods disabled for this version"
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
		print("ModLoader: previous launch did not finish, loading without mods")
		_mods_load_reason = "previous launch did not finish"
		return

	if !_modded_file.modsEnabled:
		_mods_load_reason = "mods disabled in options"
		return

	# From this point on we're actually attempting to load mods.
	# Mark the flag dirty on disk BEFORE doing anything risky, so a
	# crash during loading leaves "lastLaunchOk": false behind.
	_mods_allowed = true
	_mods_load_reason = "loading"
	_modded_file.lastLaunchOk = false
	_write_modded_json(_modded_file)


func _boot_log(text):
	last_step_ms = OS.get_ticks_msec()
	var line = "%d ms  %s" % [last_step_ms, text]
	print("ModLoader: " + text)
	if _boot_log_file != null:
		_boot_log_file.store_line(line)
		_boot_log_file.flush()


func _open_boot_log():
	var dir = Directory.new()
	if !dir.dir_exists("user://logs"):
		dir.make_dir_recursive("user://logs")
	_boot_log_file = File.new()
	if _boot_log_file.open("user://logs/mod_load.log", File.WRITE) != OK:
		_boot_log_file = null
		return
	_boot_log_file.store_line("ModLoader boot log")
	_boot_log_file.flush()


func _finish_boot():
	_boot_log("boot finished")
	if _boot_log_file != null:
		_boot_log_file.close()
		_boot_log_file = null


func _set_boot_status(text, percent):
	last_step_ms = OS.get_ticks_msec()
	_boot_log(text)
	if _boot_progress != null and is_instance_valid(_boot_progress):
		_boot_progress.set_status(text)
		_boot_progress.set_progress(percent)
		_boot_progress.add_log(text)


func _set_boot_detail(text):
	if _boot_progress != null and is_instance_valid(_boot_progress):
		_boot_progress.set_detail(text)


func _boot_percent(index, total, start_pct, end_pct):
	if total <= 0:
		return end_pct
	return start_pct + (end_pct - start_pct) * (float(index) / float(total))


func request_abort():
	_abort_requested = true
	_boot_log("abort requested")


func start(progress = null):
	_boot_progress = progress
	_abort_requested = false
	last_step_ms = OS.get_ticks_msec()
	_open_boot_log()

	if !_mods_allowed:
		_set_boot_status("mods not loaded: " + _mods_load_reason, 0)
		_finish_boot()
		yield(get_tree(), "idle_frame")
		return

	_set_boot_status("preparing mod loading", 1)
	yield(get_tree(), "idle_frame")

	_clear_import_packs()
	installScriptExtension("res://modloader/MLStateSounds.gd")

	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()

	active = true
	_load_disabled_mods()

	_set_boot_status("checking workshop installs", 2)
	yield(get_tree(), "idle_frame")
	WORKSHOP_STORE.install_pending()
	WORKSHOP_STORE.modio_install_pending()
	WORKSHOP_STORE.reconcile()
	WORKSHOP_STORE.ensure_subscriptions()

	_set_boot_status("starting steam", 3)
	yield(get_tree(), "idle_frame")
	Steam.steamInit()

	_set_boot_status("scanning mod folders", 4)
	yield(get_tree(), "idle_frame")
	_collect_mod_files(gameInstallDirectory)
	_boot_log("found " + str(_pending_mod_files.size()) + " mod packages")

	var total = _pending_mod_files.size()
	var index = 0
	for modFSPath in _pending_mod_files:
		if _abort_requested:
			_boot_log("skipped by user while mounting packages")
			break
		index += 1
		_set_boot_status("mounting " + modFSPath.get_file(), _boot_percent(index - 1, total, 5, 55))
		_set_boot_detail(modFSPath)
		yield(get_tree(), "idle_frame")
		var modLoadPath = modFSPath
		if !modLoadPath.begins_with("user://"):
			modLoadPath = ProjectSettings.globalize_path(modLoadPath)
		if ProjectSettings.load_resource_pack(modLoadPath, true):
			_modZipFiles.append(modFSPath)
		else:
			_boot_log("skipping mod package: " + modFSPath)
		yield(get_tree(), "idle_frame")

	yield(_init_mods_async(), "completed")
	Global.refresh_characters_cache()

	if _abort_requested:
		_set_boot_status("mod loading skipped - starting game", 100)
		_finish_boot()
		yield(get_tree(), "idle_frame")
		return

	print("----------------mods------loaded--------------------")
	installScriptExtension("res://modloader/ModHashCheck.gd")
	call_deferred("append_hash")
	_set_boot_status("mods loaded", 100)
	_finish_boot()
	yield(get_tree(), "idle_frame")


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
			Global.MOD_FINGERPRINT = ("%10x" % hash(h)).strip_edges()
			Global.VERSION += "-" + Global.MOD_FINGERPRINT
		else:
			Global.MOD_FINGERPRINT = ""
			Global.VERSION = Global.VERSION.split(" Modded")[0]


func _collect_mod_files(gameInstallDirectory):
	_pending_mod_files = []
	_collect_mod_files_in_folder(gameInstallDirectory.plus_file("mods"), false)

	var workshop = SteamWorkshop.new()
	var subscribed = Steam.getSubscribedItems()
	_boot_log("workshop subscriptions: " + str(subscribed.size()))
	for item in subscribed:
		var info = workshop.get_item_install_info(item)
		if info.ret:
			_collect_mod_files_in_folder(info.folder, true)

	if Global.is_mobile_device:
		_collect_mod_files_in_folder("user://mods", true)


func _collect_mod_files_in_folder(modPathPrefix, zip_only=false):
	_boot_log("scanning mods in folder: " + modPathPrefix)
	var dir = Directory.new()
	if dir.open(modPathPrefix) != OK:
		return
	if dir.list_dir_begin(true, false) != OK:
		return

	while true:
		var fileName = dir.get_next()
		if fileName == '':
			break
		if dir.current_is_dir():
			continue
		var modFSPath: String = modPathPrefix.plus_file(fileName)
		if zip_only and modFSPath.get_extension() != "zip":
			continue
		if modFSPath in _modZipFiles or modFSPath in _pending_mod_files:
			continue
		_pending_mod_files.append(modFSPath)

	dir.list_dir_end()


# Load and run any ModMain.gd scripts which were present in mod ZIP files.
# Attach the script instances to this singleton's scene to keep them alive.
func _init_mods_async():
	yield(get_tree(), "idle_frame")
	var total = _modZipFiles.size()
	var index = 0
	for modFSPath in _modZipFiles:
		index += 1
		_set_boot_status("reading " + modFSPath.get_file(), _boot_percent(index - 1, total, 55, 88))
		_set_boot_detail(modFSPath)
		yield(get_tree(), "idle_frame")
		if _abort_requested:
			_boot_log("skipped by user while reading packages")
			break
		var gdunzip = GDUNZIP.new()
		gdunzip.load(modFSPath)
		var modHash = _hash_file(modFSPath)
		for modEntryPath in gdunzip.files:
			var modSubFolder = modEntryPath.rsplit('/')[0]
			var modEntryName = modEntryPath.get_file().to_lower()
			if modEntryName.begins_with('modmain') and modEntryName.ends_with('.gd'):
				var metaRes = _checkMetadata(modSubFolder, gdunzip.files, modEntryPath)
				if metaRes != null:
					var modInfo = [metaRes[0], modHash, metaRes[1]]
					modInfo[2].zip_path = modFSPath
					zips_by_name[modInfo[2].name] = modFSPath
					if knownMergedModNames.has(metaRes[1].name):
						mergedModsDetected[metaRes[1].name] = true
						hasMergedModInstalled = true
						continue

					all_mods.append(modInfo)
					if modInfo[2].name in disabled_mod_names:
						inactive_mods.append(modInfo)
						modInfo.remove(0)
						continue

					if modInfo[2].requires == [""]:
						modInfo[0] = ResourceLoader.load(modInfo[0])
						if modInfo[2].overwrites:
							mods_w_overwrites.append({"subfolder":modSubFolder, "priority": metaRes[1].priority})
						active_mods.append(modInfo)
					elif modInfo[2].requires != [""]:
						_dependencyCheck(modInfo, true, modSubFolder)
		yield(get_tree(), "idle_frame")

	for modInfo in mods_w_depend:
		_dependencyCheck(modInfo, false, modInfo[0])
	for modInfo in all_mods:
		if modInfo.size() == 3 and not modInfo in active_mods:
			modInfo.remove(0)
	active_mods.sort_custom(self, "_compareScriptPriority")

	var mod_total = active_mods.size()
	var mod_index = 0
	for item in active_mods:
		mod_index += 1
		_set_boot_status("starting " + item[2].friendly_name, _boot_percent(mod_index - 1, mod_total, 88, 99))
		yield(get_tree(), "idle_frame")
		if _abort_requested:
			_boot_log("skipped by user while starting mods")
			for remaining in active_mods:
				while remaining.size() == 3:
					remaining.remove(0)
			break
		var scriptInstance = item[0].new(self)
		add_child(scriptInstance)
		print("Loaded " + item[2].friendly_name)
		_boot_log("loaded " + item[2].friendly_name)
		item.remove(0)
		yield(get_tree(), "idle_frame")

	_set_boot_status("applying character overwrites", 99)
	yield(get_tree(), "idle_frame")
	mods_w_overwrites.sort_custom(self, "_compareOverwritePriority")
	var doesExist = Directory.new()
	for item in mods_w_overwrites:
		if _abort_requested:
			break
		for character in Global.name_paths:
			if doesExist.file_exists(Global.name_paths.get(character)):
				_overwriteCharacterTexs(item.subfolder, character)


func _compareOverwritePriority(a, b) -> bool:
	if a.priority != b.priority:
		return a.priority < b.priority
	return a.subfolder < b.subfolder


func _dependencyCheck(modInfo, first, modSubFolder):
	var missing_dependices = modInfo[2].requires.duplicate()
	missing_dependices.erase("char_loader")
	missing_dependices.erase("soupModOptions")

	var dependices_loaded = false
	for item in modInfo[2].requires:
		item = item.strip_edges()

		if item.replace(" ", "") == "":
			modInfo[2].requires.erase(item)
			missing_dependices.erase(item)

		for mods in active_mods:
			if mods[2].name == item:
				missing_dependices.erase(item)


	if len(missing_dependices) == 0:
		dependices_loaded = true
	else:
		dependices_loaded = false

	if !dependices_loaded:
		if first:
			mods_w_depend.append(modInfo)
		elif !first:
			print(str(modInfo[2].friendly_name) + ": Missing Dependency: " + str(missing_dependices))
			mods_w_missing_depend[modInfo[2].friendly_name] = missing_dependices
	else:
		if modInfo[2].overwrites:
			mods_w_overwrites.append(modSubFolder)
			return

		modInfo[0] = ResourceLoader.load(modInfo[0])
		active_mods.append(modInfo)


func _checkMetadata(modSubFolder, zipFiles, modEntryPath):
	if modSubFolder + "/_metadata" in zipFiles:
		var modMetadataPath = "res://" + modSubFolder + "/_metadata"
		var metadata = _readMetadata(modMetadataPath)
		var check = _verifyMetadata(metadata)
		if !check == null:
			print("Metadata error: " + check)
			return null
		else:
			var modGlobalPath = "res://" + modEntryPath
			var modInfo = [modGlobalPath, metadata]
			_editMetaData(metadata, modMetadataPath)
			return modInfo
	else:
		print("No metadata in mod: " + modSubFolder)
		return null


func _editMetaData(metadata, modMetadataPath):
	metadata["id"] = "12345"
	if OS.has_feature("standalone"):
		return
	var f = File.new()
	if f.open(modMetadataPath, File.WRITE) != OK:
		return
	f.store_string(JSON.print(metadata, "  ", true))
	f.close()


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
	if ResourceLoader.has_cached(scenePath):
		var previous = load(scenePath)
		if previous != null and previous != packed_scene:
			previous.resource_path = ""
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
	if charImages.empty() and mediaSounds.empty() and mediaStateSounds.empty() and charActionImages.empty():
		return
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
	if _file_hashes.has(path):
		return _file_hashes[path]
	var file = File.new()
	var modZIPHash = file.get_md5(path)
	file.close()
	_file_hashes[path] = modZIPHash
	return modZIPHash

func _readMetadata(mdFSPath):
	var file = File.new()
	if not file.file_exists(mdFSPath):
		return null
	if file.open(mdFSPath, File.READ) != OK:
		return null
	var parsed = JSON.parse(file.get_as_text())
	if parsed.error != OK:
		return null
	file.close()
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
	# check to make sure that all required fields are included and no key is null
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
