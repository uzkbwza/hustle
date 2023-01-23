extends "res://Network.gd"
# MODLOADER V1.1 

var second_register = false
var player1_hashes
var player2_hashes

remotesync func register_player(new_player_name, id, mods):
	#if the other player is unmodded, for use of a player only using client sided mods
	if typeof(mods) == TYPE_STRING:
			if mods != Global.VERSION.replace(" Modded", ""):
				emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. You or your opponent must update to the newest version." % [Global.VERSION, mods])
				return 
			if get_local_id() == id:
				network_id = id
			print("registering player: " + str(id))
			players[id] = new_player_name
			emit_signal("player_list_changed")
	else:
		if !second_register:
			player1_hashes = _get_hashes(mods.active_mods)
			second_register = true
		elif second_register:
			print("This is the other player")
			player2_hashes = _get_hashes(mods.active_mods)
			#other_player_mods = mods.active_mods
			if !_compare_checksum():
				emit_signal("game_error", "Mismatched mod versions. Verify that both players have the same version of the mod.")
				return 
		if mods.version != Global.VERSION or mods.version != null:
			emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. You or your opponent must update to the newest version." % [Global.VERSION, mods.version])
			return
		if get_tree().get_network_unique_id() == id:
			network_id = id
		print("registering player: " + str(id))
		players[id] = new_player_name
		emit_signal("player_list_changed")
		#.register_player(new_player_name, id, version)

remote func player_connected_relay():
	var activeCheck = _get_hashes(ModLoader.active_mods)
	if !activeCheck.empty():
		rpc_("register_player", [player_name, get_local_id(), {"active_mods":ModLoader.active_mods,"version":Global.VERSION}])
	else:
		rpc_("register_player", [player_name, get_local_id(), Global.VERSION.replace(" Modded", "")])

#remotesync func send_match_data(match_data):
	#compare character mod hashes here in future maybe
	#emit_signal("match_locked_in", match_data)

func is_modded():
	return !_get_hashes(ModLoader.active_mods).empty()

func _get_hashes(active_mods):
	var hashes = []
	for item in active_mods:
		if !item[1].has("client_side"):
			item[1].merge({"client_side":false})
		if item[1].client_side == false:
			hashes.append(item[0])
		else:
			print("%s mod was client sided" % item[1].name)
	return hashes

func _compare_checksum():
	player1_hashes.sort()
	player2_hashes.sort()
	print("player1_hashes: " + str(player1_hashes))
	print("player2_hashes: " + str(player2_hashes))

	return player1_hashes == player2_hashes
