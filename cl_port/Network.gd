extends "res://Network.gd"

var _Global = self

# these variables are only here bc Network is the only global script that modloader can extend
var default_chars = 0
var css_instance = null # instance of the charater select script that is currently running
var ogVersion = Global.VERSION
var isSteamGame = false
var steam_errorMsg = ""

var retro_P2P_doFix = false


# these var declarations are necessary to force ModHashCheck.gd to not run, otherwise all of this code gets replaced

#

var player1_hash_to_folder
var player2_hash_to_folder

var player1_chars = []
var player2_chars = []

var steam_oppChars = []

var normal_mods = []
var char_mods = []
var normal_folders = []
var char_folders = []
#var generated_modlist = false

var player1_folders = null
var player2_folders = null
var player1_char_folders = null
var player2_char_folders = null

var hash_to_folder = {}

var diff = ""

var steam_isHost = false

remotesync func register_player(new_player_name, id, mods, isSteam = false):
	# failsafe in case you connect to a non-modded player, it'll show up as having no mods
	if (typeof(mods) != TYPE_DICTIONARY):
		mods = {"version" : mods, "active_mods":[]}

	if (mods.has("normal_mods")):
		var mod_folders = mods.get("normal_folders", null)
		var char_folders_remote = mods.get("char_folders", null)
		if not second_register:
			player1_hashes = mods.normal_mods
			player1_chars = mods.char_mods
			player1_hash_to_folder = mods.hash_to_folder
			player1_folders = mod_folders
			player1_char_folders = char_folders_remote
			
			second_register = true
		elif second_register:
			player2_hashes = mods.normal_mods
			player2_chars = mods.char_mods
			player2_hash_to_folder = mods.hash_to_folder
			player2_folders = mod_folders
			player2_char_folders = char_folders_remote
			
			if not _compare_checksum():
				update_diffList()
				emit_signal("game_error", "Can't connect, you both need to share every server-side mod that isn't a character.\nDifferences: " + diff)
				return 
	else:
		second_register = true
	if Global.base_version(mods.version) != Global.base_version(Global.VERSION):
		emit_signal("game_error", "Mismatched game versions.\nYou: %s, Opponent: %s." % [Global.VERSION, mods.version])
		return 
	
	if (get_tree().get_network_unique_id() == id):
		network_id = id
	
	_Global.isSteamGame = false

	print("registering player: " + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")

func update_diffList():
	var diffList = []
	var namesList = []
	diff = ""
	if player1_folders != null and player2_folders != null:
		var allFolders = player1_folders + player2_folders
		for folder in allFolders:
			if !(folder in player1_folders) or !(folder in player2_folders):
				diffList.append(folder)
				if !(folder in namesList):
					namesList.append(folder)
	else:
		var allHashes = player1_hashes + player2_hashes
		for h in allHashes:
			if (!(h in player1_hashes) or !(h in player2_hashes)):
				diffList.append(h)

				var modName
				if (player1_hash_to_folder.has(h)):
					modName = player1_hash_to_folder[h]
				else:
					modName = player2_hash_to_folder[h]
				if !(modName in namesList):
					namesList.append(modName)
				else:
					namesList[namesList.find(modName)] += " (diff. versions)"

	for i in len(namesList):
		var m = namesList[i]
		if i > 0:
			diff += ", "

		diff += m.replace("res://", "")
# steam shits
#func register_player_steam(steam_id, mods = {}):
#    if SteamLobby.SPECTATING:
#        return 
#    register_player(Steam.getFriendPersonaName(steam_id), steam_id, mods, true)
	

# these 3 function overwrites are for hash_to_folder, normal_mods and char_mods to get sent alongside active_mods
# hash_to_folder will tell what mod names the other player should display when they differ in server-sided non-character mods (the other player doesn't know the names of the mods they don't have)
remote func player_connected_relay():
	rpc_("register_player", [player_name, get_tree().get_network_unique_id(), {"active_mods": ModLoader.active_mods, "normal_mods":normal_mods, "normal_folders":normal_folders, "hash_to_folder":hash_to_folder, "char_mods":char_mods, "char_folders":char_folders, "version":Global.VERSION}])

func _direct_mod_payload():
	return {"active_mods": ModLoader.active_mods, "normal_mods":normal_mods, "normal_folders":normal_folders, "hash_to_folder":hash_to_folder, "char_mods":char_mods, "char_folders":char_folders, "version":Global.VERSION}

func player_connected(id):
	pass

func _connected_ok():
	if direct_connect:
		rpc_("register_player", [player_name, get_self_id(), _direct_mod_payload()])
		rpc_id(1, "request_direct_registration")
	emit_signal("connection_succeeded")

remote func request_direct_registration():
	if direct_connect and is_host():
		rpc_id(get_sender_id(), "register_player", player_name, get_self_id(), _direct_mod_payload())

func host_game_direct(new_player_name, port):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	var err = peer.create_server(int(port), MAX_PEERS)
	if err != OK:
		peer = null
		_connected_fail()
		emit_signal("game_error", "Could not host on port " + str(port) + ". Is another game already using it?")
		return err
	get_tree().set_network_peer(peer)
	multiplayer_active = true
	direct_connect = true
	multiplayer_host = true # this is the on
	rpc_("register_player", [new_player_name, get_self_id(), _direct_mod_payload()])
	return OK

# had to overwrite this whole function just because ivy forgot to set multiplayer_host to false
func join_game_direct(ip, port, new_player_name):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	var err = peer.create_client(ip, int(port))
	if err != OK:
		peer = null
		_connected_fail()
		emit_signal("game_error", "Could not connect to " + str(ip) + ":" + str(port) + ".")
		return err
	multiplayer_active = true
	direct_connect = true
	multiplayer_host = false
	get_tree().set_network_peer(peer)
	return OK

# now player hashes only correspond to non-character mods
func _compare_checksum():
	if player1_folders != null and player2_folders != null:
		var folders1 = player1_folders.duplicate()
		var folders2 = player2_folders.duplicate()
		folders1.sort()
		folders2.sort()
		return folders1 == folders2
	player1_hashes.sort()
	player2_hashes.sort()

	return player1_hashes == player2_hashes

# when the client finishes loading the host's character, it will send a signal that will call this function, ensuring the Go button becomes available for the host
remotesync func go_button_activate():
	do_button_activate()

# when the host presses the Go button, a signal is emmitted that calls this function
remotesync func go_button_pressed():
	do_button_pressed()

# these get called separately, from different functions depending on if it's legacy (here with rpc) or steam (on SteamLobby with send_P2P_Packet)
func do_button_activate():
	if multiplayer_host:
		var goBtt = _Global.css_instance.get_node("GoButton")
		if !goBtt.visible:
			goBtt.show()
			_Global.css_instance.enable_online_go = true # this variable serves as a buffered check to enable the Go button in characterSelect's _process()
		else:
			goBtt.disabled = false

func do_button_pressed():
	if !multiplayer_host:
		_Global.css_instance.buffer_go = true # this variable serves as a buffered check to call the go() function in characterSelect's _process()

remotesync func character_list(chars):
	steam_oppChars = chars
