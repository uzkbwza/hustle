extends "res://Network.gd"

func is_modded():
	return !_get_hashes(ModLoader.active_mods).empty()
#
func _get_hashes(active_mods):
#	return []
	var hashes = []
	for item in active_mods:
		if !item[1].has("client_side"):
			item[1].merge({"client_side":false})
		if item[1].client_side == false:
			hashes.append(item[0])
		else:
			print("%s mod was client sided" % item[1].name)
	return hashes

#func _compare_checksum():
#	return true
#	player1_hashes.sort()
#	player2_hashes.sort()
#	print("player1_hashes: " + str(player1_hashes))
#	print("player2_hashes: " + str(player2_hashes))
#
#	return player1_hashes == player2_hashes
