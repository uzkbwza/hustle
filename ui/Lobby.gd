extends Control

onready var join_button = $"%JoinButton"
onready var host_button = $"%HostButton"
onready var start_button = $"%NetworkStartButton"

onready var name_edit = $"%NameEdit"
onready var ip_edit = $"%IPEdit"
onready var port_edit = $"%PortEdit"

onready var item_list = $"%PlayerList"
onready var error_label = $"%NetworkErrorLabel"
onready var connect_container = $"%ConnectContainer"

signal quit_on_rematch()

export var direct_connect = true

var show_match_list = true
var showing = false

var match_list = []

var experimental_mode = false

var servers = [
	"ws://168.235.81.168:52450",
	"ws://168.235.86.185:52450",
	"ws://176.56.237.81:52450",
	"ws://localhost:52450"
]

var steam_dojo = "ws://168.235.89.33:52450"

func _ready():
	# Called every time the node is added to the scene.
	Network.connect("connection_failed", self, "_on_connection_failed")
	Network.connect("connection_succeeded", self, "_on_connection_success")
	Network.connect("player_list_changed", self, "refresh_lobby")
	if !direct_connect:
		Network.connect("match_list_received", self, "_on_match_list_received")
		Network.connect("player_count_received", self, "_on_player_count_received")
#	Network.connect("game_ended", self, "_on_game_ended")
	Network.connect("game_error", self, "_on_game_error")
#	Network.connect("game_start", self, "_on_game_start")
	join_button.connect("pressed", self, "_on_join_pressed")
	host_button.connect("pressed", self, "_on_host_pressed")
	start_button.connect("pressed", self, "_on_start_pressed")
	item_list.connect("item_selected", self, "_on_match_clicked")
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	$"%RefreshTimer".connect("timeout", self, "_on_refresh_timer_timeout")
	$"%RoomCodeEdit".connect("text_changed", self, "_on_room_code_edit_text_changed")
	$"%IPEdit".connect("text_changed", self, "_on_ip_edit_text_changed")
	$"%ServerList".connect("item_selected", self, "refresh_multiplayer")
	$"%ServerList".connect("item_selected", self, "_on_server_list_item_selected")
	experimental_mode = "unstable" in Global.VERSION
	if experimental_mode:
		$MatchmakingDisabledLabel.show()

func _on_server_list_item_selected(item):
	Global.save_option(item, "default_dojo")

func refresh_multiplayer(_index=null):
	Network.stop_multiplayer()
	item_list.clear()
	$"%ActivePlayers".clear()
	$"%ConnectingLabel".show()
	Network.setup_relay_multiplayer(get_server_address())
	yield(Network.multiplayer_client, "connection_succeeded")
	$"%ConnectingLabel".hide()
	show()

func _on_refresh_timer_timeout():
	if show_match_list:
		refresh_match_list()
	else:
		$"%RefreshTimer".stop()

func get_server_address():
	if SteamHustle.STARTED:
		return steam_dojo
	else:
		return servers[$"%ServerList".selected]

func _on_room_code_edit_text_changed(text):
	if !direct_connect:
		join_button.disabled = (text.strip_edges() == "")

func _on_ip_edit_text_changed(text):
	if direct_connect:
		join_button.disabled = (text.strip_edges() == "")

func show():
	.show()
	showing = true
	var player_data = Global.get_player_data()
	if player_data.has("username"):
		name_edit.text = player_data.username
	name_edit.show()
	name_edit.editable = true
	join_button.show()
	host_button.show()
	connect_container.show()
	if !direct_connect:
		$"%ServerList".select(Global.default_dojo)
		$"%IPEdit".hide()
		$"%PortEdit".hide()
#		$"%RoomCodeDisplay".show()
		$"%RoomCodeEdit".show()
		$"%PublicButton".show()
		Network.setup_relay_multiplayer(get_server_address())
		show_match_list = true
		host_button.disabled = true
		join_button.disabled = true
		$"%ConnectingLabel".show()
		if SteamHustle.STARTED:
			$"%ServerList".disabled = true
			$"%ServerList".text = "Steam Dojo"
			
		yield(Network.multiplayer_client, "connection_succeeded")
		$"%ConnectingLabel".hide()
		$"%RefreshTimer".start()
		host_button.disabled = false
#		join_button.disabled = false
		if !experimental_mode:
			refresh_match_list()
#		else:
#			item_list.modulate.a = 0
		$"%DirectConnectWarning".hide()
		$"%PublicButton".pressed = true
		if experimental_mode:
			$"%PublicButton".pressed = false
			$"%PublicButton".disabled = true
		$"%ServerList".show()
		$"%RoomCodeDisplay".hide()
		$"%NetworkStartButton".hide()
	else:
		$"%DirectConnectWarning".show()
		$"%RoomCodeEdit".hide()
		$"%PublicButton".hide()
		$"%ServerList".hide()
		connect_container.show()

	name_edit.editable = true

func refresh_match_list():
	Network.request_match_list()
	Network.request_player_count()

func _on_host_pressed():
	if name_edit.text == "":
		error_label.text = "Invalid username!"
		$AnimationPlayer.stop()
		$AnimationPlayer.play("invalid_username")
		return

	start_button.show()
	start_button.disabled = true
	error_label.text = ""
	if !direct_connect:
		connect_container.hide()
	name_edit.editable = false
	name_edit.hide()
	join_button.hide()
	host_button.hide()
	$"%RoomCodeEdit".hide()
	var player_name = ProfanityFilter.filter(name_edit.text)
	if direct_connect:
		Network.host_game_direct(player_name, port_edit.text)
	else:
		Network.setup_network_ids(player_name)
		Network.host_game_relay(player_name, $"%PublicButton".pressed)
		var room_code = yield(Network, "match_code_received")
		$"%RoomCodeDisplay".show()
		$"%RoomCodeDisplay".text = "room code: " + str(room_code)
	show_match_list = false
	refresh_lobby()
	save_username()

func _on_join_pressed():
	if name_edit.text == "":
		error_label.text = "Invalid username!"
		return
	error_label.text = ""
	host_button.disabled = true
	join_button.disabled = true
#	name_edit.editable = false
	name_edit.hide()
	var player_name = ProfanityFilter.filter(name_edit.text)
	if direct_connect:
		var ip = ip_edit.text
		var port = port_edit.text
		if not ip.is_valid_ip_address():
			error_label.text = "Invalid IP address!"
			return
		Network.join_game_direct(ip, port, player_name)
	else:
		Network.setup_network_ids(player_name)
		var code = $"%RoomCodeEdit".text
		Network.join_game_relay(player_name, code)
	show_match_list = false
	save_username()

func save_username():
	if name_edit.text.strip_edges() == "":
		name_edit.text = "username"
	Global.save_player_data({"username": ProfanityFilter.filter(name_edit.text.strip_edges())})

func _on_match_clicked(index):
	if show_match_list:
		var match_ = match_list[index]
		$"%RoomCodeEdit".text = match_.code
		$"%JoinButton".disabled = false

func _on_player_count_received(count):
	if show_match_list:
		var color = Color.green
		if count > 200:
			color = Color.greenyellow
		if count > 400:
			color = Color.yellow
		if count > 600:
			color = Color.orange
		if count > 800:
			color = Color.red
		$"%ActivePlayers".clear()
		$"%ActivePlayers".append_bbcode("[color=#" + color.to_html() + "]Connected players: " + str(count) + "[/color]")
#		$"%ActivePlayers".modulate = color

func _on_match_list_received(list):
	if show_match_list:
		item_list.clear()
		match_list = list
		for match_ in list:
#			for i in range(100):
			item_list.add_item("%s's room - %s" % [match_.host, match_.code])
			
func _on_back_button_pressed():
	Network.stop_multiplayer()
	Global.reload()

func _on_connection_success():
	refresh_lobby()
	pass

func _on_connection_failed():
	host_button.disabled = false
	join_button.disabled = false
	error_label.set_text("Connection failed.")

func refresh_lobby():
	var players = Network.get_player_list()
	players.sort()
	item_list.clear()
#	item_list.add_item(Network.get_player_name() + " (You)")
	for p in players:
		item_list.add_item(p)
	
	var prev_disabled = start_button.disabled
	if Network.direct_connect:
		start_button.disabled = item_list.get_item_count() <= 1 or not get_tree().is_network_server()
	else:
		start_button.disabled = item_list.get_item_count() <= 1
	if !start_button.disabled and prev_disabled:
		$ChallengeSound.play()

func _on_game_start():
	hide()

func _on_start_pressed():
	hide()
	Network.assign_players()
	if !Network.ids_synced:
		yield(Network, "player_ids_synced")
	Network.begin_game()

func _on_game_error(what):
	if !showing:
		return
#	Network.stop_multiplayer()
	print(what)
	if !Network.rematch_menu:
#		Network.stop_multiplayer()
#		refresh_multiplayer()
		error_label.set_text(what)
		join_button.disabled = false
		host_button.disabled = false
		if !Network.game and !visible:
			Global.reload()
#		show()
#		Global.reload()
	else:
		emit_signal("quit_on_rematch")
#func _on_find_public_ip_pressed():
#	OS.shell_open("https://icanhazip.com/")
