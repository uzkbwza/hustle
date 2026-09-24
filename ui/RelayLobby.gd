extends Control

onready var join_button = $"%JoinButton"
onready var host_button = $"%HostButton"
onready var start_button = $"%NetworkStartButton"
onready var spectate_button = $"%SpectateButton"

onready var name_edit = $"%NameEdit"
onready var ip_edit = $"%IPEdit"
onready var port_edit = $"%PortEdit"

onready var item_list = $"%PlayerList"
onready var error_label = $"%NetworkErrorLabel"
onready var connect_container = $"%ConnectContainer"

onready var spectate_status = $"%SpectateStatusLabel"

onready var room_lobby = $"%RoomLobby"
onready var room_title_label = $"%RoomTitleLabel"
onready var room_code_label = $"%RoomCodeLabel"
onready var room_players_label = $"%RoomPlayersLabel"
onready var room_spectators_label = $"%RoomSpectatorsLabel"
onready var room_start_button = $"%RoomStartButton"
onready var leave_room_button = $"%LeaveRoomButton"
onready var room_info_timer = $"%RoomInfoTimer"

signal quit_on_rematch()

export var direct_connect = true

const MAX_SPECTATORS = 64

var show_match_list = true
var showing = false

var match_list = []

var match_list_request_in_flight = false
var _last_match_list_signature = ""

var current_room_code = ""

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
	spectate_button.connect("pressed", self, "_on_spectate_code_pressed")
	item_list.connect("item_selected", self, "_on_match_clicked")
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	$"%RefreshTimer".connect("timeout", self, "_on_refresh_timer_timeout")
	$"%RoomCodeEdit".connect("text_changed", self, "_on_room_code_edit_text_changed")
	$"%IPEdit".connect("text_changed", self, "_on_ip_edit_text_changed")
	$"%ServerList".connect("item_selected", self, "refresh_multiplayer")
	$"%ServerList".connect("item_selected", self, "_on_server_list_item_selected")
	Network.connect("spectate_declined", self, "_on_spectate_declined")
	Network.connect("spectator_error", self, "_on_spectator_error")
	Network.connect("received_spectator_match_data", self, "_on_spectate_accepted")
	Network.connect("relay_match_joined", self, "_on_relay_match_joined")
	Network.connect("room_info_received", self, "_on_room_info_received")
	Network.connect("room_player_left", self, "_on_room_player_left")
	room_start_button.connect("pressed", self, "_on_start_pressed")
	leave_room_button.connect("pressed", self, "_on_leave_room_pressed")
	room_info_timer.connect("timeout", self, "_on_room_info_timer_timeout")
	room_code_label.connect("pressed", self, "_on_room_code_pressed")
	$"%RefreshTimer".wait_time = 2.0
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
	return "ws://localhost:52450"
#	if SteamHustle.STARTED:
#		return steam_dojo
#	else:
#		return servers[$"%ServerList".selected]

func _on_room_code_edit_text_changed(text):
	if !direct_connect:
		var empty = (text.strip_edges() == "")
		join_button.disabled = empty
		spectate_button.disabled = empty

func _on_ip_edit_text_changed(text):
	if direct_connect:
		join_button.disabled = (text.strip_edges() == "")

func show():
	.show()
	showing = true
	_exit_room_view()
	match_list_request_in_flight = false
	_last_match_list_signature = ""
	_restore_browse_ui()
	var player_data = Global.get_player_data()
	if player_data.has("username"):
		name_edit.text = player_data.username
	name_edit.show()
	name_edit.editable = true
	join_button.show()
	host_button.show()
	connect_container.show()
	if !direct_connect:
		$"%PlayerList".hide()
		$"%UserListPanel".hide()
		$"%MatchListPanel".show()
		$"%LobbyLabel".text = "Steam Dojo"
		$"%ServerList".select(0)
		$"%IPEdit".hide()
		$"%PortEdit".hide()
		$"%RoomCodeEdit".show()
		$"%RoomNameEdit".show()
		$"%SpectateButton".show()
		$"%PublicButton".show()
		Network.setup_relay_multiplayer(get_server_address())
		show_match_list = true
		host_button.disabled = true
		join_button.disabled = true
		$"%ConnectingLabel".show()
#		if SteamHustle.STARTED:
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
		$"%NetworkStartButton".hide()
	else:
		$"%PlayerList".show()
		$"%UserListPanel".show()
		$"%MatchListPanel".hide()
		$"%LobbyLabel".text = "Direct Connect"
		$"%DirectConnectWarning".show()
		$"%RoomCodeEdit".hide()
		$"%RoomNameEdit".hide()
		$"%SpectateButton".hide()
		$"%PublicButton".hide()
		$"%ServerList".hide()
		connect_container.show()

	name_edit.editable = true

func refresh_match_list():
	if match_list_request_in_flight:
		return
	match_list_request_in_flight = true
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
	$"%RoomNameEdit".hide()
	var player_name = ProfanityFilter.filter(name_edit.text)
	if direct_connect:
		Network.host_game_direct(player_name, port_edit.text)
	else:
		var room_name = ProfanityFilter.filter($"%RoomNameEdit".text.strip_edges())
		Network.setup_network_ids(player_name)
		Network.host_game_relay(player_name, $"%PublicButton".pressed, room_name)
		var room_code = yield(Network, "match_code_received")
		_enter_room_view(room_code)
	show_match_list = false
	if direct_connect:
		start_button.show()
	start_button.disabled = true
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
	$"%RoomNameEdit".hide()
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
		var code = $"%RoomCodeEdit".text.strip_edges().to_upper()
		current_room_code = code
		Network.join_game_relay(player_name, code)
	show_match_list = false
	$"%MatchListContainer".hide()
	save_username()

func save_username():
	if name_edit.text.strip_edges() == "":
		name_edit.text = "username"
	Global.save_player_data({"username": ProfanityFilter.filter(name_edit.text.strip_edges())})

func hide():
	room_info_timer.stop()
	if is_instance_valid(room_lobby):
		room_lobby.hide()
	.hide()

func _exit_room_view():
	current_room_code = ""
	room_info_timer.stop()
	if is_instance_valid(room_lobby):
		room_lobby.hide()

func _enter_room_view(code, spectating=false):
	current_room_code = code
	_hide_browse_ui()
	$"%RefreshTimer".stop()
	$"%MatchListContainer".hide()
	$"%PlayerList".hide()
	$"%RoomCodeEdit".hide()
	$"%RoomNameEdit".hide()
	connect_container.hide()
	host_button.hide()
	join_button.hide()
	name_edit.editable = false
	room_title_label.text = "Spectating" if spectating else "Waiting Room"
	room_players_label.text = "Players\n  (waiting for players)"
	room_spectators_label.text = "Spectators\n  (none)"
	if spectating:
		room_code_label.text = "Room: " + code
		room_code_label.show()
		room_start_button.hide()
		leave_room_button.show()
		spectate_status.text = "Requesting to spectate..."
		spectate_status.show()
	else:
		room_code_label.text = "Room: " + code
		room_code_label.show()
		room_start_button.disabled = true
		room_start_button.show()
		leave_room_button.show()
		spectate_status.hide()
	room_lobby.show()
	$"%NetworkStartButton".hide()
	$"%BackButton".hide()
	Network.request_room_info(code)
	room_info_timer.start()

func _on_room_code_pressed():
	if current_room_code == "":
		return
	var base = "Room: " + current_room_code
	OS.clipboard = current_room_code
	room_code_label.text = base + "  (copied!)"
	yield(get_tree().create_timer(1.0), "timeout")
	if is_instance_valid(room_code_label) and current_room_code != "":
		room_code_label.text = base

func _hide_browse_ui():
	name_edit.hide()
	$"%LobbyLabel".hide()
	$"%ServerList".hide()
	$"%MatchListPanel".hide()
	$"%UserListPanel".hide()

func _restore_browse_ui():
	$"%LobbyLabel".show()
	if direct_connect:
		$"%ServerList".hide()
	else:
		$"%ServerList".show()
		$"%MatchListPanel".show()

func _on_relay_match_joined():
	if showing and !direct_connect and current_room_code != "":
		_enter_room_view(current_room_code)

func _on_leave_room_pressed():
	if direct_connect:
		_on_back_button_pressed()
		return
	Network.leave_match()
	_return_to_lobby_browse()

func _on_room_player_left(_id):
	if !showing:
		return
	if is_instance_valid(room_lobby) and room_lobby.visible:
		_return_to_lobby_browse()

func _return_to_lobby_browse():
	Network.cancel_spectate_request()
	current_room_code = ""
	room_info_timer.stop()
	if is_instance_valid(room_lobby):
		room_lobby.hide()
	show_match_list = true
	match_list_request_in_flight = false
	_last_match_list_signature = ""
	name_edit.editable = true
	name_edit.show()
	join_button.show()
	host_button.show()
	host_button.disabled = false
	connect_container.show()
	if direct_connect:
		$"%RoomNameEdit".hide()
		$"%NetworkStartButton".show()
		$"%BackButton".show()
		_on_ip_edit_text_changed($"%IPEdit".text)
	else:
		$"%RoomNameEdit".show()
		$"%BackButton".show()
		$"%PlayerList".hide()
		$"%UserListPanel".hide()
		$"%MatchListPanel".show()
		$"%MatchListContainer".show()
		if !experimental_mode:
			$"%PublicButton".show()
		$"%SpectateButton".show()
		$"%RoomCodeEdit".show()
		_on_room_code_edit_text_changed($"%RoomCodeEdit".text)
		$"%RefreshTimer".start()
		refresh_match_list()
	_restore_browse_ui()

func _on_spectator_error(message):
	_return_to_lobby_browse()
	error_label.text = message

func _on_spectate_declined():
	_return_to_lobby_browse()

func _on_room_info_timer_timeout():
	if current_room_code != "":
		Network.request_room_info(current_room_code)

func _on_room_info_received(info):
	if !showing:
		return
	if !(info is Dictionary):
		return
	if info.get("code", "") != current_room_code:
		return
	var players = info.get("players", [])
	var spectators = info.get("spectators", [])
	if is_instance_valid(room_lobby) and room_lobby.visible:
		var room_name = info.get("name", "")
		if room_name != "":
			room_title_label.text = room_name
		room_players_label.text = _format_players(players)
		room_spectators_label.text = _format_spectators(spectators)
		if Network.is_host():
			room_start_button.disabled = players.size() < 2

func _format_players(players):
	var text = "Players\n"
	if players.size() == 0:
		text += "  (waiting for players)\n"
	for p in players:
		text += "  " + str(p) + "\n"
	return text

func _format_spectators(spectators):
	var text = "Spectators\n"
	if spectators.size() == 0:
		text += "  (none)\n"
	for s in spectators:
		text += "  " + str(s) + "\n"
	return text

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
	match_list_request_in_flight = false
	if !show_match_list:
		return
	var signature = JSON.print(list)
	if signature != null and signature == _last_match_list_signature:
		return
	_last_match_list_signature = signature
	match_list = list
	_populate_match_rows(list)

func _populate_match_rows(list):
	var container = $"%MatchListContainer"
	for child in container.get_children():
		child.queue_free()
	container.visible = show_match_list and list.size() > 0
	for match_ in list:
		var row = create_match_row(match_)
		container.add_child(row)

func create_match_row(match_):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = 3
	row.size_flags_vertical = 0
	var in_match = match_.get("started", false)
	var spectators = int(match_.get("spectators", 0))
	var room_name = str(match_.get("name", ""))
	if room_name == "":
		room_name = "%s's room" % match_.host
	var name_btn = Button.new()
	name_btn.text = "%s - %s" % [room_name, match_.code]
	name_btn.size_flags_horizontal = 3
	name_btn.rect_min_size.y = 32
	name_btn.clip_text = true
	if in_match:
		name_btn.disabled = true
	name_btn.connect("pressed", self, "_on_row_join_pressed", [match_.code])
	row.add_child(name_btn)
	if direct_connect:
		return row
	var spec_btn = Button.new()
	spec_btn.text = "spectate" if spectators == 0 else "spectate (%d)" % spectators
	spec_btn.rect_min_size = Vector2(0, 32)
	if spectators >= MAX_SPECTATORS:
		spec_btn.disabled = true
	spec_btn.connect("pressed", self, "_on_spectate_pressed", [match_.code])
	row.add_child(spec_btn)
	return row

func _on_row_join_pressed(match_code):
	$"%RoomCodeEdit".text = match_code
	_on_join_pressed()

func _on_spectate_pressed(match_code):
	match_code = match_code.strip_edges().to_upper()
	if name_edit.text == "":
		error_label.text = "Invalid username!"
		$AnimationPlayer.stop()
		$AnimationPlayer.play("invalid_username")
		return
	error_label.text = ""
	Network.player_name = ProfanityFilter.filter(name_edit.text)
	Network.request_spectate(match_code)
	_enter_room_view(match_code, true)
	save_username()
	while Network.relay_spectate_pending:
		yield(get_tree().create_timer(2.0), "timeout")
		if Network.relay_spectate_pending:
			Network.request_spectate(match_code)

func _on_spectate_code_pressed():
	var code = $"%RoomCodeEdit".text.strip_edges()
	if code == "":
		return
	if name_edit.text == "":
		error_label.text = "Invalid username!"
		$AnimationPlayer.stop()
		$AnimationPlayer.play("invalid_username")
		return
	_on_spectate_pressed(code)

func _on_spectate_accepted(_data):
	$"%RefreshTimer".stop()
	spectate_status.text = "Spectating...\n(Loading Characters, this may take a while)"
	leave_room_button.hide()
			
func _on_back_button_pressed():
	Network.cancel_spectate_request()
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
	if !Network.is_host():
		return
	var attempts = 0
	while Network.get_player_list().size() < 2:
		if attempts >= 10:
			return
		attempts += 1
		yield(get_tree().create_timer(0.2), "timeout")
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
