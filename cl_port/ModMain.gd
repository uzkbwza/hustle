extends Node

const MOD_PRIORITY = -10000

func installNetworkExtension(childScriptPath:String):
	var childScript = ResourceLoader.load(childScriptPath)
	childScript.new()
	var parentScript = childScript.get_base_script()
	if parentScript == null:
		print("Missing dependencies")

	var parentScriptPath = parentScript.resource_path
	childScript.take_over_path(parentScriptPath)

func _init(modLoader = ModLoader):
	modLoader.installScriptExtension("res://cl_port/AnimationTimings.gd")
	modLoader.installScriptExtension("res://cl_port/CharacterDisplay.gd")
	modLoader.installScriptExtension("res://cl_port/CharacterSelect.gd")
	modLoader.installScriptExtension("res://cl_port/main.gd")
	modLoader.installScriptExtension("res://cl_port/ErrorLabel.gd")
	modLoader.installScriptExtension("res://cl_port/UILayer.gd")

	# this is only for compatibility with 1.0.3, from 1.0.4 onwards none of this has to be overwritten
	var ver = -1
	if ("1.0." in Global.VERSION):
		ver = int(Global.VERSION.split("1.0.")[1][0])
	if !(ver > 3 or ver == -1):
		modLoader.installScriptExtension("res://cl_port/P2P_retroFix.gd")

	modLoader.installScriptExtension("res://cl_port/SteamLobby.gd")
	modLoader.installScriptExtension("res://cl_port/uiSteamLobby.gd")
	
#	installNetworkExtension("res://cl_port/Network.gd")
func _ready():
	var btt_scene = load("res://ui/CSS/CharacterButton.tscn").instance()
	btt_scene.set_custom_minimum_size(Vector2(60, 20))
	ModLoader.saveScene(btt_scene, "res://ui/CSS/CharacterButton.tscn")
	print("Char Loader: sorry about all those errors, had to force ModHashCheck to not run otherwise online functionality is impossible\n----------------------------------------------------\n")
	#Network.default_chars = len(Global.name_paths) # this would only work if there were no dlc characters planned for the future
