extends Control

onready var join_button = $"%JoinButton"
onready var host_button = $"%HostButton"
onready var start_button = $"%NetworkStartButton"

onready var name_edit = $"%NameEdit"
onready var ip_edit = $"%IPEdit"

onready var player_list = $"%PlayerList"

onready var error_label = $"%NetworkErrorLabel"

onready var connect_container = $"%ConnectContainer"

func _ready():
	# Called every time the node is added to the scene.
	Network.connect("connection_failed", self, "_on_connection_failed")
	Network.connect("connection_succeeded", self, "_on_connection_success")
	Network.connect("player_list_changed", self, "refresh_lobby")
#	Network.connect("game_ended", self, "_on_game_ended")
	Network.connect("game_error", self, "_on_game_error")
	join_button.connect("pressed", self, "_on_join_pressed")
	host_button.connect("pressed", self, "_on_host_pressed")
	start_button.connect("pressed", self, "_on_start_pressed")


func _on_host_pressed():

	if name_edit.text == "":
		error_label.text = "Invalid name!"
		return

	start_button.show()
	start_button.disabled = true
	error_label.text = ""
	connect_container.hide()
	name_edit.hide()
	var player_name = name_edit.text
	Network.host_game(player_name)
	refresh_lobby()


func _on_join_pressed():
	if name_edit.text == "":
		error_label.text = "Invalid name!"
		return

	var ip = ip_edit.text
	if not ip.is_valid_ip_address():
		error_label.text = "Invalid IP address!"
		return

	error_label.text = ""
	host_button.disabled = true
	join_button.disabled = true
#	name_edit.editable = false
	name_edit.hide()
	var player_name = name_edit.text
	Network.join_game(ip, player_name)


func _on_connection_success():
	refresh_lobby()
	pass
	
#	$Players.show()


func _on_connection_failed():
	host_button.disabled = false
	join_button.disabled = false
	error_label.set_text("Connection failed.")

func refresh_lobby():
	
	var players = Network.get_player_list()
	players.sort()
	player_list.clear()
#	player_list.add_item(Network.get_player_name() + " (You)")
	for p in players:
		player_list.add_item(p)

	start_button.disabled = player_list.get_item_count() <= 1 or not get_tree().is_network_server()


func _on_start_pressed():
	Network.begin_game()


func _on_game_error(what):
	Network.stop_multiplayer()
	get_tree().reload_current_scene()

#func _on_find_public_ip_pressed():
#	OS.shell_open("https://icanhazip.com/")
