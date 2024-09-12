extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 52450
#const SERVER_IP = "168.235.86.185"
#const SERVER_IP = "67.171.216.91"
#const SERVER_IP = "localhost"

# Max number of players.
const MAX_PEERS = 1

const NETWORK_TIMER_CYCLE = 3

var peer = null

var player_id = 2
var network_id = 0

# Name for my player.
var player_name = "Me"

var network_ids = {}
var multiplayer_active = false setget ,get_multiplayer_active

var game = null

var multiplayer_client: MultiplayerClient = null
var multiplayer_host = false


var replay_saved = false
var direct_connect = false
var rematch_menu = false
var ids_synced = false
var turn_synced = false
var send_ready = false
var can_open_action_buttons = true
var action_submitted = false
var possible_softlock = false
var steam = false
var forfeiter = 0
var last_action_sent_tick = 0

var ticks = {
	1: null,
	2: null
}

var styles = {
	1: null,
	2: null
}

var auto = false

# Names for remote players in id:name format.
var players = {}
var players_ready = []

var action_button_panels = {}
var turns_ready = {}
var action_inputs = {}
var player_objects = {}
var player_ids = {}
var rematch_requested = {}
var hole_punch: HolePunch
var rng = BetterRng.new()

var p1_turn_time = 0
var p2_turn_time = 0

var last_action = null
var undo = false
var undo_match_data = null

var p1_undo_action = null
var p2_undo_action = null

var session_id
var session_username

var second_register = false
var player1_hashes
var player2_hashes

var rpc_whitelist = {}
var rpc_blacklist = {
	"_whitelist_rpc_method": true,
	"_blacklist_rpc_method": true,
}

onready var timer = Timer.new()

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal start_game()
signal player_turns_synced()
signal character_selected(player_id, character, style)
signal player_turn_ready(player_id)
signal turn_ready()
signal match_code_received(code)
signal relay_match_joined()
signal match_locked_in(match_data)
signal match_list_received(list)
signal player_ids_synced()
signal player_disconnected()
signal sync_timer_request(id, time)
signal chat_message_received(id, message)
signal check_players_ready()
signal opponent_ready()
signal client_actionable()
signal both_players_actionable()
signal client_turn_end()
signal both_players_turn_end()
signal match_ready(match_data)
signal resim_requested()
signal resim_denied()
signal force_open_action_buttons()
signal player_count_received(playercount)
signal multiplayer_stopped()

func _ready():
	get_tree().connect("network_peer_connected", self, "player_connected", [], CONNECT_DEFERRED)
	get_tree().connect("network_peer_disconnected", self,"player_disconnected", [], CONNECT_DEFERRED)
	get_tree().connect("connected_to_server", self, "_connected_ok", [], CONNECT_DEFERRED)
	get_tree().connect("connection_failed", self, "_connected_fail", [], CONNECT_DEFERRED)
	get_tree().connect("server_disconnected", self, "_server_disconnected", [], CONNECT_DEFERRED)
	hole_punch = HolePunch.new()
	hole_punch.connect("hole_punched", self, "_on_hole_punched", [], CONNECT_DEFERRED)
	add_child(hole_punch)
	timer.autostart = true
	timer.one_shot = false
	timer.connect("timeout", self, "_on_network_timer_timeout")
	add_child(timer)
	timer.start(NETWORK_TIMER_CYCLE)

	randomize()
	_setup_rpc_whitelist()


func get_multiplayer_active():
	return multiplayer_active and !SteamLobby.SPECTATING

func rpc_(function_name: String, arg=null, type="remotesync"):
	if SteamLobby.SPECTATING:
		return
	
	if !multiplayer_active:
		return

	if direct_connect:
		if arg is Array:
			var all_args = [function_name]
			all_args.append_array(arg)
			if check_valid_rpc(function_name):
				callv("rpc", all_args)
		elif arg != null:
			rpc(function_name, arg)
		else:
			rpc(function_name)
	else:
		if !steam and !(multiplayer_client and multiplayer_client.connected):
				return
		if type == "remote":
			if steam:
				rpc_steam(function_name, arg)
			else:
				rpc_id(1, "relay", function_name, arg)
		elif type == "remotesync":
			if steam:
				rpc_steam(function_name, arg)
			else:
				rpc_id(1, "relay", function_name, arg)
			if arg is Array:
				if check_valid_rpc(function_name):
					callv(function_name, arg)
			elif arg != null:
				if check_valid_rpc(function_name):
					call(function_name, arg)
			else:
				if check_valid_rpc(function_name):
					call(function_name)

func _whitelist_rpc_method(function_name):
	rpc_blacklist.erase(function_name)
	rpc_whitelist[function_name] = true

func _blacklist_rpc_method(function_name):
	rpc_whitelist.erase(function_name)
	rpc_blacklist[function_name] = true

func _setup_rpc_whitelist():
	var script: Script = get_script()
	if script != null:
		var method_list = script.get_script_method_list()
		for method in method_list:
			var name = method.name
			if (name in rpc_blacklist):
				continue
			_whitelist_rpc_method(name)

func check_valid_rpc(function_name):
	if !(function_name in rpc_whitelist):
		print("unrecognized method %s for RPC call. modders please use _whitelist_rpc_method() to fix this." % function_name)
		return false
	return true

remotesync func send_match_data(match_data):
	emit_signal("match_locked_in", match_data)

func _on_hole_punched(my_port, hosts_port, hosts_address):
	print("hole punched")
	print("my port: " + str(my_port))
	print("hosts_port: " + str(hosts_port))
	print("hosts_address: " + str(hosts_address))
	pass

func host_game_direct(new_player_name, port):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port), MAX_PEERS)
	get_tree().set_network_peer(peer)
	multiplayer_active = true
	direct_connect = true
	rpc_("register_player", [new_player_name, get_local_id(), Global.VERSION])

func get_local_id():
	if steam:
		return SteamHustle.STEAM_ID
	return get_tree().get_network_unique_id()

func join_game_direct(ip, port, new_player_name):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	multiplayer_active = true
	direct_connect = true
	multiplayer_host = false
	get_tree().set_network_peer(peer)

func setup_relay_multiplayer(address):
	multiplayer_client = MultiplayerClient.new(address)
	multiplayer_active = true
	direct_connect = false
	get_tree().set_network_peer(multiplayer_client.get_client())

func host_game_relay(new_player_name, public=true):
	if !(multiplayer_client and multiplayer_client.connected):
		return
	multiplayer_host = true
	player_name = new_player_name.substr(0, 32)
	rpc_id(1, "create_match", player_name, public)
	yield(self, "match_code_received")

func join_game_relay(new_player_name, room_code):
	if !(multiplayer_client and multiplayer_client.connected):
		return
	multiplayer_host = false
	player_name = new_player_name.substr(0, 32)
	rpc_id(1, "player_join_game", player_name, room_code)
	yield(self, "relay_match_joined")
#	rpc_("register_player", [new_player_name, get_local_id()])

func random_session_id():
	return rng.random_string(8)

func unique_username(username):
	return username + "__" + rng.random_string(8)

func setup_network_ids(player_name):
	self.player_name = player_name
	session_id = random_session_id()
	session_username = unique_username(player_name)
	return session_username

remote func server_error(message):
	emit_signal("game_error", message)

func _reset():
	peer = null
	network_id = 0

	network_ids = {}
	multiplayer_active = false

	possible_softlock = false

	game = null
	multiplayer_client = null
	multiplayer_host = false

	replay_saved = false
	direct_connect = false
	rematch_menu = false

	last_action = null
	
	can_open_action_buttons = true
	last_action_sent_tick = 0
	
	send_ready = false
	
	forfeiter = 0
	
	ticks = {
		1: null,
		2: null
	}
	
	undo = false
	undo_match_data = null
	
	# Names for remote players in id:name format.
	players = {}
	players_ready = []
	
	p1_turn_time = 0
	p2_turn_time = 0
	
	action_button_panels = {
		1: null,
		2: null,
	}
	
	p1_undo_action = null
	p2_undo_action = null

	turns_ready = {
		1: false,
		2: false
	}

	styles = {
		1: null,
		2: null
	}
	
	action_inputs = {
		1: {
			"action": null,
			"data": null,
			"extra": null,
		},
		2: {
			"action": null,
			"data": null,
			"extra": null,
		}
	}
	
	auto = false
	
	player_objects = {
		1: null,
		2: null
	}

	player_ids = {
	}

	rematch_requested = {
		1: false,
		2: false,
	}
	
	action_submitted = false
	
	ids_synced = false
	turn_synced = false
	
	get_tree().set_network_peer(null)

# Callback from SceneTree.
func player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	if direct_connect:
		rpc_("register_player", [player_name, id, Global.VERSION])

func pid_to_username(player_id):
		if player_id != 1 and player_id != 2 or !is_instance_valid(game):
			return ""
		if SteamLobby.SPECTATING or !network_ids.has(player_id):
			return Global.current_game.match_data.user_data["p" + str(player_id)]
		if direct_connect:
			return players[network_ids[opponent_player_id(player_id)]] # idk why i need to do this
		return players[network_ids[player_id]]


func opponent_id(pid=player_id):
	if pid == 1:
		return network_ids[2]
	return network_ids[1]

func opponent_player_id(pid=player_id):
	if pid == 1:
		return 2
	return 1

func reset_action_inputs():
	action_inputs = {
		1: {
			"action": null,
			"data": null,
			"extra": null,
		},
		2: {
			"action": null,
			"data": null,
			"extra": null,
		}
	}
	
	turns_ready = {
		1: false,
		2: false
	}

# Callback from SceneTree.
remote func player_disconnected(id):
#	multiplayer_active = false
	if !(id in players):
		return
	if Global.css_open:
		Global.reload()
		if steam:
			SteamLobby.quit_match()
	emit_signal("player_disconnected")
	if is_host():
		if players.has(id):
			emit_signal("game_error", "Player " + players[id] + " disconnected")
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)
	if !steam:
		end_game()

func _process(_delta):
	if multiplayer_client:
		multiplayer_client.poll()

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	print("server disconnected")
	multiplayer_active = false
	end_game()

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	multiplayer_client = null
	emit_signal("connection_failed")

remotesync func receive_player_timer(id, timer):
	emit_signal("sync_timer_request", id, timer)
	if steam:
		SteamLobby.spectator_sync_timers(id, timer)

func sync_timer(id, time):
	rpc_("receive_player_timer", [id, time], "remotesync")

func submit_action(action, data, extra):
	if multiplayer_active:
		action_inputs[player_id]["action"] = action
		action_inputs[player_id]["data"] = data
		action_inputs[player_id]["extra"] = extra
		rpc_("multiplayer_turn_ready", player_id)
		print("submitting action: " + action)

func turn_ready(id):
	if ticks[1] != ticks[2]:
		print("desync? ticks[1] = " + str(ticks[1]) + ", ticks[2] = " + str(ticks[2]))
		return false
	return Network.turns_ready[id] and (Network.turns_ready[opponent_player_id(id)])

func get_sender_id():
#	if direct_connect:
	return get_tree().get_rpc_sender_id()

func unregister_player(id):
	if !steam:
		players.erase(id)
		print("unregistering player: " + str(id))
		emit_signal("player_list_changed")

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func request_rematch():
	send_rematch_request(player_id)
	rpc_("send_rematch_request", player_id)

remote func receive_match_list(list):
	emit_signal("match_list_received", list)

remote func receive_player_count(count):
	emit_signal("player_count_received", count)

remotesync func player_emote(player_id, message):
	if is_instance_valid(Global.current_game):
		var player = Global.current_game.get_player(player_id)
		if player:
			player.emote(message.split("/em ")[-1])

func request_match_list():
	if multiplayer_client and multiplayer_client.connected:
		rpc_id(1, "fetch_match_list")

func request_player_count():
	if multiplayer_client and multiplayer_client.connected:
		rpc_id(1, "fetch_player_count")


func is_host():
	if direct_connect:
		return get_tree().is_network_server()
	elif steam:
		return SteamLobby.PLAYER_SIDE == 1
	return multiplayer_host

func assign_players():
	print("assigning players")
	if steam:
		player_id = SteamLobby.PLAYER_SIDE
		if SteamLobby.PLAYER_SIDE == 1:
			network_ids[1] = SteamHustle.STEAM_ID
			network_ids[2] = SteamLobby.OPPONENT_ID
		else:
			network_ids[1] = SteamLobby.OPPONENT_ID
			network_ids[2] = SteamHustle.STEAM_ID
#			emit_signal("player_ids_synced")
		begin_game()

	elif is_host():
		var network_ids = {}
		var player_ids = players.keys()
		assert(player_ids.size() == 2)
		player_ids.shuffle()
		network_ids[1] = player_ids[0]
		network_ids[2] = player_ids[1]
		rpc_("sync_ids", network_ids)

func select_character(character, style=null):
	rpc_("sync_character_selection", [player_id, character, style])

func forfeit(opponent=false):
	print("forfeiting")
	if !opponent:
		rpc_("player_forfeit", player_id)
	else:
		if is_instance_valid(game):
			player_forfeit((game.my_id % 2) + 1)
	pass

remotesync func player_forfeit(player_id):
	if is_instance_valid(game):
		game.forfeit(player_id)
		forfeiter = player_id
		if player_id != self.player_id and !SteamLobby.SPECTATING and !ReplayManager.playback:
			SteamHustle.unlock_achievement("ACH_WIN_BY_FORFEIT")
		if steam and !SteamLobby.SPECTATING:
			SteamLobby.spectate_forfeit(player_id)

func begin_game():
	SteamLobby.REMATCHING_ID = 0
	rematch_menu = false
	if is_host() or steam:
		print("starting game")
		rematch_requested = {
			1: false,
			2: false,
		}
#		emit_signal("start_game")
		rpc_("open_chara_select")

func end_game():
	if multiplayer_active:
		stop_multiplayer()

func sync_tick():
	print("notifying opponent")
	rpc_("opponent_tick", null, "remote")
	pass

func sync_unlock_turn():
	print("telling opponent we are actionable")
	rpc_("opponent_sync_check_unlock", null, "remote")

remote func opponent_sync_check_unlock():
	print("opponent is actionable")
	while is_instance_valid(game) and !game.game_paused:
		yield(get_tree(), "idle_frame")
	print("so are we")
	rpc_("confirm_opponent_actionable", null, "remote")

remote func confirm_opponent_actionable():
	print("confirming...")
	rpc_("opponent_sync_unlock", null, "remote")

remote func opponent_sync_unlock():
	print("unlocking action buttons")
	can_open_action_buttons = true
	emit_signal("force_open_action_buttons")

remote func opponent_tick():
	print("opponent ready")
	yield(get_tree(), "idle_frame")
	if is_instance_valid(game):
		game.network_simulate_ready = true


func autosave_match_replay(match_data, user1, user2):
	if !replay_saved:
		replay_saved = true
		ReplayManager.save_replay_mp(match_data, user1, user2)

func stop_multiplayer(leave_steam_lobby=false):
	print("stopping multiplayer")
	multiplayer_active = false
	if peer:
		peer.close_connection()
	_reset()
	if leave_steam_lobby:
		SteamLobby.leave_Lobby()
		steam = false
	else:
		if SteamLobby.LOBBY_ID != 0:
			multiplayer_active = true

	emit_signal("multiplayer_stopped")

func _on_network_timer_timeout():
	pass
#	if multiplayer_active:
#		if possible_softlock:
#			if is_instance_valid(game):
#				if game.current_tick != last_action_sent_tick:
#					return
#			print("asking politely if we softlocked")
#			rpc_("check_opponent_sent_action", null, "remote")

remote func check_opponent_sent_action():
	print("i've been asked politely if we softlocked")
	if action_submitted:
		send_current_action()
	else:
		print("the answer is no")

remote func my_turn_started(player_id):
	if player_id == opponent_player_id(player_id):
		emit_signal("opponent_ready")

remote func receive_match_code(code):
	emit_signal("match_code_received")

remote func send_action(action, data, extra, player_id):
		print("received action: " + str(action))
		action_inputs[player_id]["action"] = action
		action_inputs[player_id]["data"] = data
		action_inputs[player_id]["extra"] = extra
		player_objects[player_id].on_action_selected(action, data, extra)
		rpc_("opponent_received_action", null, "remote")
		

remote func opponent_received_action():
	print("opponent received my action")
	possible_softlock = false

remote func check_tick_sync(tick):
	pass

remotesync func send_chat_message(player_id, message):
	emit_signal("chat_message_received", player_id, message)

remotesync func end_turn_simulation(tick, player_id):
#	if get_sender_id() == network_id:
#		return
	player_id = opponent_player_id(player_id)
	print("ending turn simulation for player " + str(player_id) + " at tick " + str(tick))
	ticks[player_id] = tick
	if ticks[1] == ticks[2]:
		turn_synced = true
		send_ready = false
#		if rng.percent(60):
		emit_signal("player_turns_synced")
#		if is_host():
#			host_start_turn()

func host_start_turn():
	while !game.is_waiting_on_player():
		yield(get_tree(), "idle_frame")
	rpc_("wait_for_client_actionable", null, "remote")
	yield(self, "client_actionable")
#	emit_signal("player_turns_synced")
	rpc_("client_turn_synced")

remote func wait_for_client_actionable():
	while !game.is_waiting_on_player():
		yield(get_tree(), "idle_frame")
	rpc_("client_actionable")

remotesync func client_turn_synced():
	emit_signal("both_players_actionable")

remote func client_actionable():
	emit_signal("client_actionable")

remotesync func multiplayer_turn_ready(id):
	Network.turns_ready[id] = true
	print("turn ready for player " + str(id))
	emit_signal("player_turn_ready", id)
	if steam:
		SteamLobby.spectator_turn_ready(id)
	if turn_ready(id):
		action_submitted = true
#		if is_host():
#			host_end_turn()
#		yield(self, "both_players_turn_end")
		print("sending action")
		var action_input = action_inputs[player_id]
		last_action = action_input
#		if rng.percent(0):
		if is_instance_valid(game):
			last_action_sent_tick = game.current_tick
		send_current_action()
		possible_softlock = true
		emit_signal("turn_ready")
		turn_synced = false
		send_ready = true

func send_current_action():
	if last_action:
#		last_action["extra"] = last_action["extra"].duplicate(true)
#		last_action["extra"].secret = {}
		rpc_("send_action", [last_action["action"], last_action["data"], last_action["extra"], player_id], "remote")

func host_end_turn():
	while !game.is_waiting_on_player():
		yield(get_tree(), "idle_frame")
	rpc_("wait_for_client_turn_end", null, "remote")
	yield(self, "client_turn_end")
	rpc_("client_turn_end_synced")

remote func wait_for_client_turn_end():
	while !game.is_waiting_on_player():
		yield(get_tree(), "idle_frame")
	rpc_("client_turn_end")

remotesync func client_turn_end_synced():
	emit_signal("both_players_turn_end")

remote func client_turn_end():
	emit_signal("client_turn_end")

remotesync func check_players_ready():
	emit_signal("check_players_ready")
	pass

remotesync func register_player(new_player_name, id, version):
	if !((version is String and Global.VERSION is String) or (version is Dictionary and Global.VERSION is Dictionary)):
		emit_signal("game_error", "Failed to make lobby. One player is using mods while the other is not.")
		return
	
	if version != Global.VERSION:
		emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. You or your opponent must update to the newest version." % [Global.VERSION, version])
#		emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. Get the newest version at ivysly.itch.io." % [Global.VERSION, version])
		return
	if get_local_id() == id:
		network_id = id
	print("registering player: " + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")

remotesync func sync_ids(network_ids):
	self.network_ids = network_ids
	for player in network_ids:
		if network_ids[player] == get_local_id():
			player_id = player
	ids_synced = true
	emit_signal("player_ids_synced")

remotesync func send_rematch_request(player_id):
	rematch_requested[player_id] = true
	if rematch_requested[1] and rematch_requested[2]:
		forfeiter = 0
		if is_host() or steam:
			ReplayManager.init()
			if steam:
				SteamLobby.REMATCHING_ID = SteamLobby.OPPONENT_ID
#				Global.reload()
#				begin_game()
				SteamLobby.exit_match_from_button()
			else:
				begin_game()

remotesync func sync_character_selection(player_id, character, style=null):
	print("player %s selected character" % [str(player_id)])
	styles[player_id] = style
	emit_signal("character_selected", player_id, character, style)

remotesync func open_chara_select():
	print("opening character select")
	emit_signal("start_game")

func request_softlock_fix():
	if multiplayer_active:
		rpc_("send_resim_request", null, "remote")

remote func send_resim_request():
	emit_signal("resim_requested")

func answer_resim_request(answer: bool):
	if answer:
		rpc_("multiplayer_resim", null, "remote")
	else:
		rpc_("deny_resim", null, "remote")

remote func deny_resim():
	rpc_("send_chat_message", [opponent_player_id(player_id), "-- denied resync request."])
	emit_signal("resim_denied")

remote func multiplayer_resim():
	auto = true
	undo = true
	rpc_("send_opponent_replay_for_resim", [ReplayManager.frames, p1_undo_action, p2_undo_action], "remote")

remote func send_opponent_replay_for_resim(replay, p1_undo_action, p2_undo_action):
#	self.p1_undo_action = p1_undo_action
#	self.p2_undo_action = p2_undo_action
	ReplayManager.frames = replay
	undo = true	
	auto = true
	rpc_("finalize_resim")
 
remotesync func finalize_resim():
	if is_instance_valid(game):
		game.undo(false)

func undo_finished():
	undo = false

# relay stuff
remote func test_relay():
	print("relay test")

remote func room_join_confirm():
	emit_signal("relay_match_joined")

remote func room_join_deny(message):
	emit_signal("game_error", message)

remote func receive_match_id(match_id):
	print("received match id: %s" % [match_id])
	emit_signal("match_code_received", match_id)

remote func player_connected_relay():
	rpc_("register_player", [player_name, get_local_id(), Global.VERSION])

func is_modded():
	return false

func on_turn_started():
	if steam:
		SteamLobby.update_spectators(ReplayManager.frames)

func rpc_steam(function_name, arg):
	SteamLobby.rpc_(function_name, arg)
	pass

func start_steam_mp():
	multiplayer_active = true
	steam = true

func start_game_steam():
	pass
	
func register_player_steam(steam_id):
	if SteamLobby.SPECTATING:
		return
	if SteamHustle.STEAM_ID == steam_id:
		network_id = steam_id
	print("registering player: " + str(steam_id))
	players[steam_id] = Steam.getFriendPersonaName(steam_id)
	emit_signal("player_list_changed")

func _get_hashes(active_mods):
	return []
