extends "res://Network.gd"

func is_modded():
	return !_get_hashes(ModLoader.active_mods).empty()
#
func _get_hashes(active_mods):
#	return []
	var hashes = []
	for item in active_mods:
		var is_character = item[1]
		if !item[1].has("client_side"):
			item[1].merge({"client_side":false})
		if item[1].client_side == false:
			hashes.append(item[0])
		else:
			print("%s mod was client sided" % item[1].name)
	return hashes
