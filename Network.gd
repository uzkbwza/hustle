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

var peer = null

var player_id = 2
var network_id = 0

# Name for my player.
var player_name = "Me"

var network_ids = {}
var multiplayer_active = false

var game = null


var multiplayer_client: MultiplayerClient = null
var multiplayer_host = false

var replay_saved = false
var direct_connect = false
var rematch_menu = false
var ids_synced = false
var turn_synced = false

var ticks = {
	1: null,
	2: null
}

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

var session_id
var session_username

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal start_game()
signal player_turns_synced()
signal character_selected(player_id, character)
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

func _ready():
	get_tree().connect("network_peer_connected", self, "player_connected", [], CONNECT_DEFERRED)
	get_tree().connect("network_peer_disconnected", self,"player_disconnected", [], CONNECT_DEFERRED)
	get_tree().connect("connected_to_server", self, "_connected_ok", [], CONNECT_DEFERRED)
	get_tree().connect("connection_failed", self, "_connected_fail", [], CONNECT_DEFERRED)
	get_tree().connect("server_disconnected", self, "_server_disconnected", [], CONNECT_DEFERRED)
	hole_punch = HolePunch.new()
	hole_punch.connect("hole_punched", self, "_on_hole_punched", [], CONNECT_DEFERRED)
	add_child(hole_punch)
	randomize()

func rpc_(function_name: String, arg=null, type="remotesync"):
	if !multiplayer_active:
		return
#	yield(get_tree().create_timer(rng.randf_range(0.5, 2.0)), "timeout")
	if direct_connect:
		if arg is Array:
			var all_args = [function_name]
			all_args.append_array(arg)
			callv("rpc", all_args)
		elif arg != null:
			rpc(function_name, arg)
		else:
			rpc(function_name)
	else:
		if !(multiplayer_client and multiplayer_client.connected):
			return
		if type == "remote":
			rpc_id(1, "relay", function_name, arg)
		
		if type == "remotesync":
			rpc_id(1, "relay", function_name, arg)
			if arg is Array:
				callv(function_name, arg)
			elif arg != null:
				call(function_name, arg)
			else:
				call(function_name)

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
	rpc_("register_player", [new_player_name, get_tree().get_network_unique_id(), Global.VERSION])

func join_game_direct(ip, port, new_player_name):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	multiplayer_active = true
	direct_connect = true
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
#	rpc_("register_player", [new_player_name, get_tree().get_network_unique_id()])
	
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

	game = null
	multiplayer_client = null
	multiplayer_host = false

	replay_saved = false
	direct_connect = false
	rematch_menu = false

	ticks = {
		1: null,
		2: null
	}

	# Names for remote players in id:name format.
	players = {}
	players_ready = []
	
	action_button_panels = {
		1: null,
		2: null,
	}

	turns_ready = {
		1: false,
		2: false
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
	
	ids_synced = false
	turn_synced = false
	
	get_tree().set_network_peer(null)

# Callback from SceneTree.
func player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	if direct_connect:
		rpc_("register_player", [player_name, id, Global.VERSION])

func pid_to_username(player_id):
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
	emit_signal("player_disconnected")
	if is_host():
		if players.has(id):
			emit_signal("game_error", "Player " + players[id] + " disconnected")
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)
	end_game()

func _process(_delta):
	if multiplayer_client:
		multiplayer_client.poll()
	pass

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

func request_match_list():
	if multiplayer_client and multiplayer_client.connected:
		rpc_id(1, "fetch_match_list")

func is_host():
	if direct_connect:
		return get_tree().is_network_server()
	return multiplayer_host

func assign_players():
	if is_host():
		var network_ids = {}
		var player_ids = players.keys()
		assert(player_ids.size() == 2)
		player_ids.shuffle()
		network_ids[1] = player_ids[0]
		network_ids[2] = player_ids[1]
		rpc_("sync_ids", network_ids)

func select_character(character):
	rpc_("sync_character_selection", [player_id, character])

func begin_game():
	rematch_menu = false
	if is_host():
		rematch_requested = {
			1: false,
			2: false,
		}
#		emit_signal("start_game")
		rpc_("open_chara_select")

func end_game():
	if multiplayer_active:
		stop_multiplayer()

func autosave_match_replay(match_data):
	if !replay_saved:
		replay_saved = true
		ReplayManager.save_replay_mp(match_data, pid_to_username(1), pid_to_username(2))

func stop_multiplayer():
	print("stopping multiplayer")
	multiplayer_active = false
	if peer:
		peer.close_connection()
	_reset()

remote func receive_match_code(code):
	emit_signal("match_code_received")

remote func send_action(action, data, extra, id):
		print("received action: " + str(action))
		action_inputs[id]["action"] = null
		action_inputs[id]["data"] = null
		action_inputs[id]["extra"] = null
		player_objects[id].on_action_selected(action, data, extra)

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
#		if rng.percent(60):
		emit_signal("player_turns_synced")

remotesync func multiplayer_turn_ready(id):
	Network.turns_ready[id] = true
	print("turn ready for player " + str(id))
	emit_signal("player_turn_ready", id)
	if turn_ready(id):
		print("sending action")
		var action_input = action_inputs[player_id]
		rpc_("send_action", [action_input["action"], action_input["data"], action_input["extra"], player_id], "remote")
		emit_signal("turn_ready")
		turn_synced = false

remotesync func check_players_ready():
	emit_signal("check_players_ready")
	pass

remotesync func register_player(new_player_name, id, version):
	if version != Global.VERSION:
		emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. Visit ivysly.itch.io/yomi-hustle to download the newest version." % [Global.VERSION, version])
		return
	if get_tree().get_network_unique_id() == id:
		network_id = id
	print("registering player: " + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")

remotesync func sync_ids(network_ids):
	self.network_ids = network_ids
	for player in network_ids:
		if network_ids[player] == get_tree().get_network_unique_id():
			player_id = player
	ids_synced = true
	emit_signal("player_ids_synced")

remotesync func send_rematch_request(player_id):
	rematch_requested[player_id] = true
	if rematch_requested[1] and rematch_requested[2]:
		if is_host():
			ReplayManager.init()
			begin_game()

remotesync func sync_character_selection(player_id, character):
	print("player %s selected character" % [str(player_id)])
	emit_signal("character_selected", player_id, character)

remotesync func open_chara_select():
	emit_signal("start_game")

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
	rpc_("register_player", [player_name, get_tree().get_network_unique_id(), Global.VERSION])
