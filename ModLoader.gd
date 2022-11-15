extends Node

var areModsEnabled = false

func _init():
	if !areModsEnabled:
		return

	_loadMods()
	print("----------------mods loaded--------------------")
	_initMods()

var _modZipFiles = []

func _loadMods():
	var gameInstallDirectory = OS.get_executable_path().get_base_dir()
	if OS.get_name() == "OSX":
		gameInstallDirectory = gameInstallDirectory.get_base_dir().get_base_dir().get_base_dir()
	var modPathPrefix = gameInstallDirectory.plus_file("mods")

	var dir = Directory.new()
	if dir.open(modPathPrefix) != OK:
		return
	if dir.list_dir_begin() != OK:
		return

	while true:
		var fileName = dir.get_next()
		if fileName == '':
			break
		if dir.current_is_dir():
			continue
		var modFSPath = modPathPrefix.plus_file(fileName)
		var modGlobalPath = ProjectSettings.globalize_path(modFSPath)
		if !ProjectSettings.load_resource_pack(modGlobalPath, true):
			continue
		_modZipFiles.append(modFSPath)
	dir.list_dir_end()

func dir_contents(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			else:
				print("Found file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

# Load and run any ModMain.gd scripts which were present in mod ZIP files.
# Attach the script instances to this singleton's scene to keep them alive.
func _initMods():
	var initScripts = []
	for modFSPath in _modZipFiles:
		var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
		gdunzip.load(modFSPath)
		for modEntryPath in gdunzip.files:
			var modEntryName = modEntryPath.get_file().to_lower()
			if modEntryName.begins_with('modmain') and modEntryName.ends_with('.gd'):
				var modGlobalPath = "res://" + modEntryPath
				var packedScript = ResourceLoader.load(modGlobalPath)
				initScripts.append(packedScript)

	initScripts.sort_custom(self, "_compareScriptPriority")

	for packedScript in initScripts:
		var scriptInstance = packedScript.new(self)
		add_child(scriptInstance)


func _compareScriptPriority(a, b):
	var aPrio = a.get_script_constant_map().get("MOD_PRIORITY", 0)
	var bPrio = b.get_script_constant_map().get("MOD_PRIORITY", 0)
	if aPrio != bPrio:
		return aPrio < bPrio

	# Ensure that the result is deterministic, even when the priority is the same
	var aPath = a.resource_path
	var bPath = b.resource_path
	if aPath != bPath:
		return aPath < bPath

	return false


func installScriptExtension(childScriptPath:String):
	dir_contents("res://")
	var childScript = ResourceLoader.load(childScriptPath)
	# Force Godot to compile the script now.
	# We need to do this here to ensure that the inheritance chain is
	# properly set up, and multiple mods can chain-extend the same
	# class multiple times.
	# This is also needed to make Godot instantiate the extended class
	# when creating singletons.
	# The actual instance is thrown away.
	childScript.new()

	var parentScript = childScript.get_base_script()
	var parentScriptPath = parentScript.resource_path
	print(parentScriptPath)
	childScript.take_over_path(parentScriptPath)


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

# Things to keep to ensure they are not garbage collected
var _savedObjects = []

func saveScene(modifiedScene, scenePath:String):
	var packed_scene = PackedScene.new()
	packed_scene.pack(modifiedScene)
	packed_scene.take_over_path(scenePath)
	_savedObjects.append(packed_scene)
