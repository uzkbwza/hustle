extends "res://main.gd"

# delete character cache button
func _ready():
	var mod_toggle = $"%ModToggle" if has_node("%ModToggle") else null
	var container = mod_toggle.get_parent() if mod_toggle else null

	if container and container.get_node_or_null("DeleteCache") == null:
		var btt = Button.new()
		btt.name = "DeleteCache"
		btt.text = "delete character cache"
		container.add_child(btt)
		container.move_child(btt, mod_toggle.get_index())
		btt.connect("pressed", self, "_delete_char_cache", [btt])

func _delete_char_cache(btt):
	var dir = Directory.new()
	_Global.css_instance.charPackages = {}
	if dir.dir_exists("user://char_cache"):
		for f in ModLoader._get_all_files("user://char_cache"):
			dir.remove(f)
		dir.remove("user://char_cache")
	if dir.dir_exists("user://mod_temp_packs"):
		for f in ModLoader._get_all_files("user://mod_temp_packs"):
			dir.remove(f)
		dir.remove("user://mod_temp_packs")
	get_tree().quit()

# these just load the necessary custom characters through characterSelect.gd
func _on_loaded_replay(match_data):
	_Global.css_instance.net_loadReplayChars([match_data.selected_characters[1]["name"], match_data.selected_characters[2]["name"], match_data])
	match_data["replay"] = true
	_on_match_ready(match_data)

func _on_received_spectator_match_data(data):
	get_node("/root/SteamLobby/LoadingSpectator/Label").text = "Spectating...\n(Loading Characters, this may take a while)"
	_Global.css_instance.net_loadReplayChars([data.selected_characters[1]["name"], data.selected_characters[2]["name"], data])
	data["spectating"] = true
	_on_match_ready(data)
