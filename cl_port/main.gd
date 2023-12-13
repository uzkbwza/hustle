extends "res://main.gd"

# delete character cache button
func _ready():
	var container = $"%OptionsContainer".get_node("VBoxContainer").get_node("Contents").get_node("VBoxContainer").get_node("VBoxContainer")

	if (container.get_node_or_null("LoadOnStart") == null):
		var btt = Button.new()
		btt.name = "DeleteCache"
		btt.text = "delete character cache"
		container.add_child(btt)
		container.move_child(btt, len(container.get_children()) - 4)
		btt.connect("pressed", self, "_delete_char_cache", [btt])

func _delete_char_cache(btt):
	var dir = Directory.new()
	_Global.css_instance.charPackages = {}
	for f in ModLoader._get_all_files("user://char_cache", "pck"):
		dir.remove(f)
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
