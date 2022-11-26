extends Node

var IS_ONLINE: bool
var IS_OWNED: bool

var STEAM_ID: int
var STEAM_NAME: String = ""

func _ready():
	_initialize_steam()

func _initialize_steam():
	var INIT: Dictionary = Steam.steamInit()
	print("Did steam initialize?: " + str(INIT))
	
	if INIT['status'] != 1:
		print("Failed to initialize Steam. " + str(INIT['verbal']))

	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	IS_OWNED = Steam.isSubscribed()

func _process(_delta):
	Steam.run_callbacks()
