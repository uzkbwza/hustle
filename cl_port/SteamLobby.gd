extends "res://SteamLobby.gd"

var _Global = Network

# mods = {normal : [], characters : []}

# mod list will only be sent when getting challenged
func challenge_user(user):
	print("challenging user")
	var data = {
		"challenge_from":[SteamHustle.STEAM_ID, Network.normal_mods, Network.char_mods, Network.hash_to_folder], # mods get sent through here for simplicity
		"match_settings":MATCH_SETTINGS,
	}
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	_send_P2P_Packet(user.steam_id, data)
	SETTINGS_LOCKED = true
	CHALLENGING_STEAM_ID = user.steam_id
	OPPONENT_ID = user.steam_id
	PLAYER_SIDE = 1
	#Network.multiplayer_host = true # will only be useful after challenge gets accepted
	Network.steam_isHost = true

func _read_P2P_Packet_custom(readable):
	._read_P2P_Packet_custom(readable)

	if readable.has("character_list"):
		Network.steam_oppChars = readable.character_list
	elif readable.has("character_difference"):
		Network.diff = readable.character_difference
		_Global.steam_errorMsg = "Can't challenge, you don't share these server-side mods: " + Network.diff
#		_Global.steam_errorMsg = "Can't challenge, mod mismatch. Try deleting character cache in options."
	elif readable.has("_packetName"):
		print("hasta aca esta bien")
		match readable._packetName:
			"go_button_activate":
				Network.do_button_activate()
			"go_button_pressed":
				Network.do_button_pressed()

func _receive_challenge(fromData, match_settings):
	var steam_id = fromData[0]
	var serverMods = fromData[1]
	var charMods = fromData[2]
	Network.steam_oppChars = charMods

	Network.player1_hashes = Network.normal_mods
	Network.player2_hashes = serverMods

	Network.player1_hash_to_folder = Network.hash_to_folder
	Network.player2_hash_to_folder = fromData[3]
	if (!Network._compare_checksum()):
		Network.update_diffList()
		_Global.steam_errorMsg = "You got challenged, but you don't share these server-side mods: " + Network.diff
#		_Global.steam_errorMsg = "Can't receive challenge, mod mismatch. Try deleting character cache in options."
		_send_P2P_Packet(steam_id, {"character_difference" : Network.diff})
		decline_challenge()
		return
	
	_send_P2P_Packet(steam_id, {"character_list":Network.char_mods})

	if Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status") != "idle":
		_send_P2P_Packet(steam_id, {"player_busy":null})
		return 

	Network.steam_oppChars = charMods
	#Network.multiplayer_host = false # will only be useful after challenge gets accepted
	Network.steam_isHost = false

	print("received challenge")
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	CHALLENGER_STEAM_ID = steam_id
	CHALLENGER_MATCH_SETTINGS = match_settings
	emit_signal("received_challenge", CHALLENGER_STEAM_ID)

func _setup_game_vs(steam_id):
	_Global.isSteamGame = true

	print("registering players")
	REMATCHING_ID = 0
	OPPONENT_ID = steam_id
	Network.register_player_steam(steam_id)
	Network.register_player_steam(SteamHustle.STEAM_ID)
	Network.player1_chars = Network.char_mods
	Network.player2_chars = Network.steam_oppChars

	Network.assign_players()
	Steam.setLobbyMemberData(LOBBY_ID, "status", "fighting")
	Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", str(OPPONENT_ID))
	Steam.setLobbyMemberData(LOBBY_ID, "player_id", str(PLAYER_SIDE))
