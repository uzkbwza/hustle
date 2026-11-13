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

onready var room_chat_scroll = $"%RoomChatScroll"
onready var room_chat_history = $"%RoomChatHistory"
onready var room_chat_edit = $"%RoomChatEdit"
onready var room_chat_send_button = $"%RoomChatSendButton"

var replay_challenge_button: Button
var replay_side_overlay: Control
var replay_side_label: Label
var replay_side_p1_button: Button
var replay_side_p2_button: Button
var replay_side_restore_timers: CheckBox
var replay_side_cancel: Button
var incoming_challenge_overlay: Control
var incoming_challenge_label: Label
var incoming_challenge_accept: Button
var incoming_challenge_decline: Button
var pending_replay_match_data = null
var pending_replay_path = ""

signal quit_on_rematch()

export var direct_connect = true

const MAX_SPECTATORS = 64

var show_match_list = true
var showing = false

var match_list = []

var match_list_request_in_flight = false
var _last_match_list_signature = ""

var current_room_code = ""

var room_code_prefix = "Room: "

var lan_room_name = ""
var lan_room_address = ""
var lan_room_port = 0
var pending_lan_room_name = ""

var experimental_mode = false

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
	if UIManager.is_connected("swiped_back", self, "_on_back_button_pressed"):
		UIManager.disconnect("swiped_back", self, "_on_back_button_pressed")
	UIManager.connect("swiped_back", self, "_on_back_button_pressed")
	$"%RefreshTimer".connect("timeout", self, "_on_refresh_timer_timeout")
	$"%RoomCodeEdit".connect("text_changed", self, "_on_room_code_edit_text_changed")
	$"%IPEdit".connect("text_changed", self, "_on_ip_edit_text_changed")
	Network.connect("spectate_declined", self, "_on_spectate_declined")
	Network.connect("spectator_error", self, "_on_spectator_error")
	Network.connect("received_spectator_match_data", self, "_on_spectate_accepted")
	Network.connect("relay_match_joined", self, "_on_relay_match_joined")
	Network.connect("room_info_received", self, "_on_room_info_received")
	Network.connect("opponent_left", self, "_on_opponent_left")
	Network.connect("room_chat_received", self, "_on_room_chat_received")
	Network.connect("room_chat_history_received", self, "_on_room_chat_history_received")
	Network.connect("relay_replay_challenge_received", self, "_on_relay_replay_challenge_received")
	Network.connect("relay_replay_challenge_declined", self, "_on_relay_replay_challenge_declined")
	Network.connect("relay_replay_challenge_cancelled", self, "_on_relay_replay_challenge_cancelled")
	if direct_connect:
		Network.connect("lan_rooms_changed", self, "_on_lan_rooms_changed")
		Network.connect("multiplayer_stopped", self, "_on_multiplayer_stopped")
	room_start_button.connect("pressed", self, "_on_start_pressed")
	leave_room_button.connect("pressed", self, "_on_leave_room_pressed")
	room_info_timer.connect("timeout", self, "_on_room_info_timer_timeout")
	room_code_label.connect("pressed", self, "_on_room_code_pressed")
	room_chat_edit.connect("text_entered", self, "_on_room_chat_text_entered")
	room_chat_send_button.connect("pressed", self, "_on_room_chat_send_pressed")
	$"%RefreshTimer".wait_time = 2.0
	experimental_mode = "unstable" in Global.VERSION
	if experimental_mode:
		$MatchmakingDisabledLabel.show()
	_create_replay_challenge_ui()

	UIManager.register_menu(self, [
		$"%NameEdit", $"%RoomNameEdit",
		$"%ConnectContainer", $MarginContainer/HBoxContainer/VBoxContainer/ConnectContainer/HostRow, $"%JoinContainer", $"%JoinButtons",		$"%HostButton", $"%PublicButton", $"%JoinButton", $"%SpectateButton",
		$"%IPEdit", $"%PortEdit", $"%RoomCodeEdit",
		$"%NetworkStartButton", $"%BackButton",
		$"%RoomCodeLabel", $"%RoomStartButton", $"%LeaveRoomButton",
		$"%RoomChatContainer", $"%RoomChatEdit", $"%RoomChatSendButton",
	])

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
		if direct_connect:
			Network.refresh_lan_rooms()
		else:
			refresh_match_list()
	else:
		$"%RefreshTimer".stop()

func get_server_address():
	return "ws://168.235.104.144:52450"

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
	match_list_request_in_flight = false
	_last_match_list_signature = ""
	if direct_connect and Network.lan_room_active:
		_enter_lan_room_view()
		return
	if !direct_connect and Network.relay_room_code != "" and !Network.relay_spectating:
		_enter_room_view(Network.relay_room_code)
		return
	_exit_room_view()
	_restore_browse_ui()
	var player_data = Global.get_player_data()
	if player_data.has("username"):
		name_edit.text = Global.get_display_name(player_data.username)
	name_edit.show()
	name_edit.editable = true
	join_button.show()
	host_button.show()
	connect_container.show()
	if !direct_connect:
		$"%PlayerList".hide()
		$"%UserListPanel".hide()
		$"%MatchListPanel".show()
		$"%IPEdit".hide()
		$"%PortEdit".hide()
		$"%RoomCodeEdit".show()
		$"%RoomNameEdit".show()
		$"%SpectateButton".show()
		$"%PublicButton".show()
		Network.stop_multiplayer()
		Network.setup_relay_multiplayer(get_server_address())
		show_match_list = true
		host_button.disabled = true
		join_button.disabled = true
		$"%ConnectingLabel".show()
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
		$"%NetworkStartButton".hide()
	else:
		$"%PlayerList".hide()
		$"%UserListPanel".hide()
		$"%MatchListPanel".show()
		$"%MatchListContainer".show()
		$"%LobbyLabel".text = "Direct Connect"
		$"%LobbyLabel".show()
		$"%DirectConnectWarning".text = "host on the same Wi-Fi network, or type an IP and port to join. If no rooms appear, allow the game through your firewall."
		$"%DirectConnectWarning".show()
		$"%RoomCodeEdit".hide()
		$"%RoomNameEdit".show()
		$"%SpectateButton".hide()
		$"%PublicButton".hide()
		$"%IPEdit".show()
		$"%PortEdit".show()
		$"%JoinButtons".show()
		$"%JoinButton".show()
		$"%NetworkStartButton".hide()
		$"%ConnectingLabel".hide()
		$"%ActivePlayers".clear()
		$"%BackButton".show()
		_on_ip_edit_text_changed($"%IPEdit".text)
		Network.start_lan_browsing()
		$"%RefreshTimer".start()
		_refresh_lan_rows(Network.get_lan_rooms())
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
		var port_text = port_edit.text.strip_edges()
		if !port_text.is_valid_integer():
			port_text = "52450"
		var port = int(port_text)
		if port <= 0 or port > 65535:
			port = 52450
		lan_room_name = ProfanityFilter.filter($"%RoomNameEdit".text.strip_edges())
		if lan_room_name == "":
			lan_room_name = player_name + "'s room"
		lan_room_address = Network.get_local_lan_address()
		lan_room_port = port
		var host_err = Network.host_game_direct(player_name, str(port))
		if host_err != OK:
			_return_to_lobby_browse()
			return
		Network.start_lan_hosting(lan_room_name, lan_room_address, lan_room_port, 1)
		_enter_lan_room_view()
	else:
		var room_name = ProfanityFilter.filter($"%RoomNameEdit".text.strip_edges())
		Network.setup_network_ids(player_name)
		Network.host_game_relay(player_name, $"%PublicButton".pressed, room_name)
		var room_code = yield(Network, "match_code_received")
		_enter_room_view(room_code)
	show_match_list = false
	start_button.hide()
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
		var ip = ip_edit.text.strip_edges()
		var port_text = port_edit.text.strip_edges()
		if not ip.is_valid_ip_address():
			error_label.text = "Invalid IP address!"
			host_button.disabled = false
			join_button.disabled = false
			name_edit.show()
			$"%RoomNameEdit".show()
			return
		if !port_text.is_valid_integer() or int(port_text) <= 0 or int(port_text) > 65535:
			error_label.text = "Invalid port!"
			host_button.disabled = false
			join_button.disabled = false
			name_edit.show()
			$"%RoomNameEdit".show()
			return
		var join_err = Network.join_game_direct(ip, port_text, player_name)
		if join_err != OK:
			_return_to_lobby_browse()
			return
		Network.lan_room_active = true
		Network.lan_room_name = pending_lan_room_name
		pending_lan_room_name = ""
		Network.lan_room_address = ip
		Network.lan_room_port = int(port_text)
		_enter_lan_room_view()
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
	var chosen = ProfanityFilter.filter(name_edit.text.strip_edges())
	Global.custom_name = chosen
	Global.save_player_data({"username": chosen})

func hide():
	room_info_timer.stop()
	_hide_replay_challenge_ui()
	if is_instance_valid(room_lobby):
		room_lobby.hide()
	if direct_connect:
		Network.stop_lan_browsing()
	.hide()

func _exit_room_view():
	current_room_code = ""
	room_code_prefix = "Room: "
	pending_lan_room_name = ""
	room_info_timer.stop()
	_hide_replay_challenge_ui()
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
	replay_challenge_button.hide()
	$"%NetworkStartButton".hide()
	$"%BackButton".hide()
	if is_instance_valid(room_chat_history):
		room_chat_history.clear()
		for entry in Network.relay_room_chat_history:
			if entry is Dictionary:
				_render_room_chat(entry.get("name", ""), entry.get("message", ""), entry.get("color", ""))
		if is_instance_valid(room_chat_edit):
			room_chat_edit.clear()
	Network.request_room_info(code)
	room_info_timer.start()

func _enter_lan_room_view():
	show_match_list = false
	Network.stop_lan_browsing()
	match_list = []
	_last_match_list_signature = ""
	var rows = $"%MatchListContainer"
	for child in rows.get_children():
		child.queue_free()
	$"%RefreshTimer".stop()
	$"%MatchListPanel".hide()
	$"%MatchListContainer".hide()
	$"%PlayerList".hide()
	$"%UserListPanel".hide()
	$"%RoomCodeEdit".hide()
	$"%RoomNameEdit".hide()
	$"%IPEdit".hide()
	$"%PortEdit".hide()
	$"%JoinButtons".hide()
	$"%SpectateButton".hide()
	$"%LobbyLabel".hide()
	$"%DirectConnectWarning".hide()
	$"%ConnectingLabel".hide()
	$"%NetworkStartButton".hide()
	$"%BackButton".hide()
	connect_container.hide()
	host_button.hide()
	join_button.hide()
	name_edit.hide()
	name_edit.editable = false
	current_room_code = "%s:%d" % [Network.lan_room_address, Network.lan_room_port]
	room_code_prefix = "Address: "
	room_title_label.text = Network.lan_room_name if Network.lan_room_name != "" else "LAN Room"
	room_code_label.text = room_code_prefix + current_room_code
	room_code_label.show()
	room_players_label.text = "Players\n  (waiting for players)"
	room_spectators_label.text = "Spectators\n  (not available on LAN)"
	room_start_button.disabled = true
	room_start_button.show()
	leave_room_button.show()
	spectate_status.hide()
	room_lobby.show()
	replay_challenge_button.hide()
	if is_instance_valid(room_chat_history):
		room_chat_history.clear()
		for entry in Network.relay_room_chat_history:
			if entry is Dictionary:
				_render_room_chat(entry.get("name", ""), entry.get("message", ""), entry.get("color", ""))
	if is_instance_valid(room_chat_edit):
		room_chat_edit.clear()
	_update_lan_room_info()

func _lan_player_names():
	var names = []
	for id in Network.players.keys():
		names.append(str(Network.players[id]))
	names.sort()
	return names

func _update_lan_room_info():
	if !direct_connect or !is_instance_valid(room_lobby) or !room_lobby.visible:
		return
	var names = _lan_player_names()
	room_players_label.text = _format_players(names)
	if Network.is_host():
		room_start_button.disabled = names.size() < 2
		Network.update_lan_hosting_players(names.size())
	else:
		room_start_button.disabled = true

func _on_lan_rooms_changed(rooms):
	if !direct_connect or !show_match_list:
		return
	_refresh_lan_rows(rooms)

func _refresh_lan_rows(rooms):
	if !is_instance_valid($"%MatchListContainer"):
		return
	var list = []
	for room in rooms:
		if !(room is Dictionary):
			continue
		var ip = str(room.get("ip", ""))
		var port = int(room.get("port", 0))
		if ip == "" or port <= 0:
			continue
		var room_name = str(room.get("name", ""))
		if room_name == "":
			room_name = str(room.get("host", "")) + "'s room"
		list.append({
			"code": "%s:%d" % [ip, port],
			"ip": ip,
			"port": port,
			"name": room_name,
			"host": str(room.get("host", "")),
			"started": int(room.get("players", 1)) >= 2,
			"spectators": 0,
		})
	match_list = list
	_populate_match_rows(list)

func _on_room_code_pressed():
	if current_room_code == "":
		return
	var base = room_code_prefix + current_room_code
	OS.clipboard = current_room_code
	room_code_label.text = base + "  (copied!)"
	yield(get_tree().create_timer(1.0), "timeout")
	if is_instance_valid(room_code_label) and current_room_code != "":
		room_code_label.text = base

func _on_room_chat_text_entered(text):
	_submit_room_chat(text)

func _on_room_chat_send_pressed():
	_submit_room_chat(room_chat_edit.text)

func _submit_room_chat(text):
	if text.strip_edges() == "":
		return
	Network.send_room_chat(text)
	room_chat_edit.clear()

func _on_room_chat_received(sender_name, message):
	_render_room_chat(sender_name, message)
	_scroll_room_chat_to_bottom()

func _on_room_chat_history_received(history):
	if !is_instance_valid(room_chat_history):
		return
	room_chat_history.clear()
	for entry in history:
		if entry is Array and entry.size() >= 3:
			_render_room_chat(entry[0], entry[2], entry[1])
		elif entry is Array and entry.size() >= 2:
			_render_room_chat(entry[0], entry[1])
	_scroll_room_chat_to_bottom()

func _render_room_chat(sender_name, message, color=""):
	if !is_instance_valid(room_chat_history):
		return
	if color == "":
		color = Network.name_color_for(str(sender_name))
	var text = ProfanityFilter.filter("<[color=#%s]%s[/color]> %s" % [color, str(sender_name), str(message)])
	room_chat_history.append_bbcode(text + "\n")

func _scroll_room_chat_to_bottom():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	if is_instance_valid(room_chat_scroll):
		room_chat_scroll.scroll_vertical = 10000000000000000

func _create_replay_challenge_ui():
	replay_challenge_button = Button.new()
	replay_challenge_button.rect_min_size.y = 24
	replay_challenge_button.text = "Replay Challenge (WIP)"
	replay_challenge_button.connect("pressed", self, "_on_replay_challenge_pressed")
	var buttons_column = $"%RoomStartButton".get_parent()
	buttons_column.add_child(replay_challenge_button)
	buttons_column.move_child(replay_challenge_button, $"%RoomStartButton".get_index())
	replay_challenge_button.hide()

	var side_parts = _create_dialog_overlay("ReplayChallengeSidePicker")
	replay_side_overlay = side_parts[0]
	var side_box = side_parts[1]
	replay_side_label = Label.new()
	replay_side_label.align = Label.ALIGN_CENTER
	side_box.add_child(replay_side_label)
	var side_buttons = HBoxContainer.new()
	side_buttons.alignment = BoxContainer.ALIGN_CENTER
	side_box.add_child(side_buttons)
	replay_side_p1_button = Button.new()
	replay_side_p1_button.connect("pressed", self, "_on_replay_side_picked", [1])
	side_buttons.add_child(replay_side_p1_button)
	replay_side_p2_button = Button.new()
	replay_side_p2_button.connect("pressed", self, "_on_replay_side_picked", [2])
	side_buttons.add_child(replay_side_p2_button)
	replay_side_restore_timers = CheckBox.new()
	replay_side_restore_timers.text = "restore timers"
	side_box.add_child(replay_side_restore_timers)
	replay_side_cancel = Button.new()
	replay_side_cancel.text = "cancel"
	replay_side_cancel.connect("pressed", self, "_on_replay_side_cancelled")
	side_box.add_child(replay_side_cancel)

	var incoming_parts = _create_dialog_overlay("ReplayChallengeIncoming")
	incoming_challenge_overlay = incoming_parts[0]
	var incoming_box = incoming_parts[1]
	incoming_challenge_label = Label.new()
	incoming_challenge_label.align = Label.ALIGN_CENTER
	incoming_challenge_label.autowrap = true
	incoming_challenge_label.rect_min_size = Vector2(320, 0)
	incoming_box.add_child(incoming_challenge_label)
	var incoming_buttons = HBoxContainer.new()
	incoming_buttons.alignment = BoxContainer.ALIGN_CENTER
	incoming_box.add_child(incoming_buttons)
	incoming_challenge_accept = Button.new()
	incoming_challenge_accept.text = "accept"
	incoming_challenge_accept.connect("pressed", self, "_on_incoming_challenge_accept")
	incoming_buttons.add_child(incoming_challenge_accept)
	incoming_challenge_decline = Button.new()
	incoming_challenge_decline.text = "decline"
	incoming_challenge_decline.connect("pressed", self, "_on_incoming_challenge_decline")
	incoming_buttons.add_child(incoming_challenge_decline)

	UIManager.register_menu(self, [
		replay_challenge_button,
		replay_side_p1_button, replay_side_p2_button, replay_side_restore_timers, replay_side_cancel,
		incoming_challenge_accept, incoming_challenge_decline,
	])

func _create_dialog_overlay(node_name):
	var overlay = ColorRect.new()
	overlay.name = node_name
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.hide()
	add_child(overlay)
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var panel = PanelContainer.new()
	center.add_child(panel)
	var margin = MarginContainer.new()
	margin.add_constant_override("margin_left", 16)
	margin.add_constant_override("margin_top", 12)
	margin.add_constant_override("margin_right", 16)
	margin.add_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	var box = VBoxContainer.new()
	box.rect_min_size = Vector2(320, 0)
	box.add_constant_override("separation", 8)
	margin.add_child(box)
	return [overlay, box]

func _relay_opponent_name() -> String:
	for id in Network.players:
		if id != Network.get_self_id():
			return str(Network.players[id])
	return ""

func _relay_can_challenge() -> bool:
	if direct_connect or Network.steam:
		return false
	if !showing or current_room_code == "":
		return false
	if Network.relay_spectating or is_instance_valid(Network.game):
		return false
	return Network.relay_opponent_id() != 0

func _on_replay_challenge_pressed():
	if !_relay_can_challenge():
		return
	var ui_layer = get_parent()
	if !ui_layer.is_connected("replay_picked_for_challenge", self, "_on_replay_picked_for_challenge"):
		ui_layer.connect("replay_picked_for_challenge", self, "_on_replay_picked_for_challenge")
	ui_layer.open_replay_picker_for_challenge(_relay_opponent_name())

func _on_replay_picked_for_challenge(match_data, path):
	if direct_connect or Network.steam:
		return
	if !(match_data is Dictionary) or !_relay_can_challenge():
		return
	pending_replay_match_data = match_data
	pending_replay_path = path
	_show_replay_side_picker()

func _show_replay_side_picker():
	var p1_name = "P1"
	var p2_name = "P2"
	if pending_replay_match_data and pending_replay_match_data.get("selected_characters") is Dictionary:
		var sc = pending_replay_match_data.selected_characters
		if sc.get(1) is Dictionary and sc[1].has("name"):
			p1_name = Global.character_display_name(sc[1]["name"])
		if sc.get(2) is Dictionary and sc[2].has("name"):
			p2_name = Global.character_display_name(sc[2]["name"])
	replay_side_label.text = "Pick your side\n%s vs %s" % [p1_name, p2_name]
	replay_side_p1_button.text = "P1 (" + p1_name + ")"
	replay_side_p2_button.text = "P2 (" + p2_name + ")"
	var has_timer = false
	if pending_replay_match_data:
		var mode = pending_replay_match_data.get("timer_mode", null)
		if mode == null:
			has_timer = pending_replay_match_data.get("chess_timer", false)
		else:
			has_timer = mode != "none"
	var has_timer_state = has_timer and pending_replay_match_data.has("chess_timer_state")
	replay_side_restore_timers.visible = has_timer_state
	replay_side_restore_timers.pressed = has_timer_state
	replay_side_overlay.show()

func _on_replay_side_picked(side):
	if pending_replay_match_data == null:
		return
	pending_replay_match_data["restore_timers"] = replay_side_restore_timers.visible and replay_side_restore_timers.pressed
	Network.send_relay_replay_challenge(pending_replay_match_data, side)
	_clear_pending_replay()
	replay_side_overlay.hide()

func _on_replay_side_cancelled():
	_clear_pending_replay()
	replay_side_overlay.hide()

func _clear_pending_replay():
	pending_replay_match_data = null
	pending_replay_path = ""

func _on_relay_replay_challenge_received(challenger_name, replay_data, challenger_side):
	var p1_name = "P1"
	var p2_name = "P2"
	if replay_data.get("selected_characters") is Dictionary:
		var sc = replay_data.selected_characters
		if sc.get(1) is Dictionary and sc[1].has("name"):
			p1_name = Global.character_display_name(sc[1]["name"])
		if sc.get(2) is Dictionary and sc[2].has("name"):
			p2_name = Global.character_display_name(sc[2]["name"])
	var their_char = p1_name if challenger_side == 1 else p2_name
	var your_side = 2 if challenger_side == 1 else 1
	var your_char = p2_name if challenger_side == 1 else p1_name
	incoming_challenge_label.text = "%s wants to replay-challenge you.\n%s vs %s\nThey'd play P%d (%s) — you'd play P%d (%s)." % [challenger_name, p1_name, p2_name, challenger_side, their_char, your_side, your_char]
	incoming_challenge_accept.show()
	incoming_challenge_decline.text = "decline"
	incoming_challenge_overlay.show()
	if visible:
		$ChallengeSound.play()

func _on_incoming_challenge_accept():
	Network.accept_relay_replay_challenge()
	incoming_challenge_overlay.hide()

func _on_incoming_challenge_decline():
	if Network.relay_replay_challenge_pending:
		Network.decline_relay_replay_challenge()
	incoming_challenge_overlay.hide()

func _on_relay_replay_challenge_declined(reason, detail):
	var msg = "Replay challenge declined."
	if reason == "missing_mods":
		var missing = []
		if detail is Array:
			for n in detail:
				missing.append(str(n))
		msg = "Opponent is missing required mods:\n%s" % ", ".join(missing)
	elif reason == "version":
		msg = "Opponent is on a different game version (%s)." % str(detail)
	elif reason == "busy":
		msg = "Opponent is busy right now."
	incoming_challenge_label.text = msg
	incoming_challenge_accept.hide()
	incoming_challenge_decline.text = "ok"
	incoming_challenge_overlay.show()

func _on_relay_replay_challenge_cancelled():
	incoming_challenge_overlay.hide()

func _hide_replay_challenge_ui():
	if is_instance_valid(replay_challenge_button):
		replay_challenge_button.hide()
	if is_instance_valid(replay_side_overlay):
		replay_side_overlay.hide()
	if is_instance_valid(incoming_challenge_overlay):
		incoming_challenge_overlay.hide()
	_clear_pending_replay()

func _hide_browse_ui():
	name_edit.hide()
	$"%LobbyLabel".hide()
	$"%MatchListPanel".hide()
	$"%UserListPanel".hide()

func _restore_browse_ui():
	$"%LobbyLabel".show()
	if !direct_connect:
		$"%MatchListPanel".show()

func _on_relay_match_joined():
	if showing and !direct_connect and current_room_code != "":
		_enter_room_view(current_room_code)

func _on_leave_room_pressed():
	if direct_connect:
		Network.stop_lan_hosting()
		Network.lan_room_active = false
		if Network.multiplayer_active or Network.peer != null:
			Network.stop_multiplayer()
		else:
			_return_to_lobby_browse()
		return
	if Network.relay_replay_challenge_pending:
		Network.decline_relay_replay_challenge()
	else:
		Network.cancel_relay_replay_challenge()
	if Network.relay_spectating:
		Network.end_spectate()
	else:
		Network.leave_match()
	_return_to_lobby_browse()

func _on_opponent_left(_username, _reason):
	if !showing:
		return
	if !direct_connect:
		if Network.relay_replay_challenge_pending:
			Network.decline_relay_replay_challenge()
		else:
			Network.cancel_relay_replay_challenge()
	_hide_replay_challenge_ui()
	if is_instance_valid(room_lobby) and room_lobby.visible:
		replay_challenge_button.hide()
		if direct_connect:
			if Network.is_host():
				_update_lan_room_info()
			else:
				_return_to_lobby_browse()
			return
		if Network.is_host():
			Network.request_room_info(current_room_code)
			return
		_return_to_lobby_browse()

func _on_multiplayer_stopped():
	if !direct_connect:
		return
	if is_instance_valid(room_lobby) and room_lobby.visible:
		_return_to_lobby_browse()

func _return_to_lobby_browse():
	Network.cancel_spectate_request()
	current_room_code = ""
	room_code_prefix = "Room: "
	pending_lan_room_name = ""
	Network.relay_room_code = ""
	Network.relay_room_info = {}
	room_info_timer.stop()
	_hide_replay_challenge_ui()
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
		Network.stop_lan_hosting()
		Network.lan_room_active = false
		$"%MatchListPanel".show()
		$"%MatchListContainer".show()
		$"%RoomNameEdit".show()
		$"%IPEdit".show()
		$"%PortEdit".show()
		$"%JoinButtons".show()
		$"%JoinButton".show()
		$"%NetworkStartButton".hide()
		$"%BackButton".show()
		$"%DirectConnectWarning".show()
		$"%LobbyLabel".text = "Direct Connect"
		$"%LobbyLabel".show()
		join_button.disabled = false
		host_button.disabled = false
		_on_ip_edit_text_changed($"%IPEdit".text)
		Network.start_lan_browsing()
		$"%RefreshTimer".start()
		_refresh_lan_rows(Network.get_lan_rooms())
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
		var can_challenge = !direct_connect and !Network.steam and players.size() >= 2 and !Network.relay_spectating and !is_instance_valid(Network.game)
		replay_challenge_button.visible = can_challenge

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
	name_btn.rect_min_size.y = 24
	name_btn.clip_text = true
	if in_match:
		name_btn.disabled = true
	name_btn.connect("pressed", self, "_on_row_join_pressed", [match_.code])
	row.add_child(name_btn)
	if direct_connect:
		return row
	var spec_btn = Button.new()
	spec_btn.text = "spectate" if spectators == 0 else "spectate (%d)" % spectators
	spec_btn.rect_min_size = Vector2(0, 24)
	if spectators >= MAX_SPECTATORS:
		spec_btn.disabled = true
	spec_btn.connect("pressed", self, "_on_spectate_pressed", [match_.code])
	row.add_child(spec_btn)
	return row

func _on_row_join_pressed(match_code):
	if direct_connect:
		var parts = str(match_code).split(":")
		if parts.size() < 2:
			return
		pending_lan_room_name = ""
		for entry in match_list:
			if str(entry.get("code", "")) == str(match_code):
				pending_lan_room_name = str(entry.get("name", ""))
				break
		ip_edit.text = parts[0]
		port_edit.text = parts[1]
		_on_join_pressed()
		return
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
	if not visible: return
	if Network.relay_spectating:
		Network.end_spectate()
	Network.cancel_spectate_request()
	Network.stop_multiplayer()
	if direct_connect:
		Network.stop_lan_browsing()
	Global.reload()

func _on_connection_success():
	refresh_lobby()
	if direct_connect:
		_update_lan_room_info()
	pass

func _on_connection_failed():
	host_button.disabled = false
	join_button.disabled = false
	if direct_connect:
		Network.lan_room_active = false
		Network.lan_room_name = ""
		Network.lan_room_address = ""
		Network.lan_room_port = 0
		Network.stop_multiplayer()
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
	if direct_connect:
		_update_lan_room_info()

func _on_game_start():
	hide()

func _on_start_pressed():
	if !Network.is_host():
		return
	if direct_connect:
		Network.stop_lan_hosting()
		Network.lan_room_active = false
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
		if direct_connect:
			_update_lan_room_info()
		if !Network.game and !visible:
			Global.reload()
#		show()
#		Global.reload()
	else:
		emit_signal("quit_on_rematch")
#func _on_find_public_ip_pressed():
#	OS.shell_open("https://icanhazip.com/")
