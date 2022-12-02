extends Node

var IS_ONLINE: bool
var IS_OWNED: bool

var STEAM_ID: int
var STEAM_NAME: String = ""

var STARTED = false

func _enter_tree():
	_initialize_steam()
	pass

func _initialize_steam():
	STARTED = true
	var INIT: Dictionary = Steam.steamInit()
	print("Did steam initialize?: " + str(INIT))
	
	if INIT['status'] != 1:
		print("Failed to initialize Steam. " + str(INIT['verbal']))

	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	IS_OWNED = Steam.isSubscribed()

func _process(_delta):
	if STARTED:
		Steam.run_callbacks()

func has_supporter_pack(steam_id):
	if !STARTED:
		print("steam not started, assuming true")
		return true
	if SteamLobby.OPPONENT_ID == steam_id:
		if SteamLobby.CLIENT_TICKET:
			print("checking if your opponent has the supporter pack...")
			return Steam.userHasLicenseForApp(steam_id, Custom.SUPPORTER_PACK) == 0
	elif steam_id == SteamYomi.STEAM_ID:
		print("checking if you have the supporter pack...")
		return Steam.isDLCInstalled(Custom.SUPPORTER_PACK)
	print("this ID does not have the supporter pack.")
	return false
