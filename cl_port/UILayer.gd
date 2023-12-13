extends "res://ui/UILayer.gd"

var noSteam = false

func _process(delta):
	$"%VersionLabel".text = "version " + Global.VERSION

func _ready():
	var ver = -1
	#if ("1.0." in Global.VERSION):
	#    ver = int(Global.VERSION.split("1.0.")[1][0])
	#if !(ver > 3 or ver == -1):
	#    noSteam = true
	#    $"%ButtonContainer".grow_horizontal = 2
	#    $"%SteamMultiplayerButton".text = "[Steam Multiplayer available on unstable beta or 1.0.4+]"

func _on_steam_multiplayer_pressed():
	
	if !noSteam:
		._on_steam_multiplayer_pressed()
	else:
		OS.shell_open("https://cdn.discordapp.com/attachments/750542558614257697/1072636992984191088/image.png")
		$"%SteamMultiplayerButton".disabled = true
