extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 1209

# Max number of players.
const MAX_PEERS = 1

var peer = null

var player_id = 2
var network_id = 0

# Name for my player.
var player_name = "Me"

var network_ids = {}
var multiplayer_active = false

var game

var replay_saved = false

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


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	hole_punch = HolePunch.new()
	hole_punch.connect("hole_punched", self, "_on_hole_punched")
	add_child(hole_punch)

	randomize()

func _on_hole_punched(my_port, hosts_port, hosts_address):
	print("hole punched")
	print("my port: " + str(my_port))
	print("hosts_port: " + str(hosts_port))
	print("hosts_address: " + str(hosts_address))
	pass

func host_game(new_player_name, port):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(port), MAX_PEERS)
	get_tree().set_network_peer(peer)
	multiplayer_active = true
	rpc("register_player", new_player_name)

func join_game(ip, port, new_player_name):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	multiplayer_active = true
	get_tree().set_network_peer(peer)

func host_game_holepunch():
	_reset()
	print('traversing nat...')
	hole_punch.start_traversal(session_id, true, session_username)
	var result = yield(hole_punch, "hole_punched")
	print("hole punched")
	var port = result[0]

	peer = NetworkedMultiplayerENet.new()
	peer.create_server(port)
	get_tree().set_network_peer(peer)
	
	multiplayer_active = true
	rpc("register_player", player_name)
	hole_punch.start_traversal(session_id, true, session_username)

func join_game_holepunch(room_code):
	_reset()
	hole_punch.start_traversal(room_code, false, session_username)
	print('traversing nat...')
	var result = yield(hole_punch, "hole_punched")
	print("hole punched")
	
	var host_ip = result[2]
	var host_port = result[1]
	var own_port = result[0]
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(host_ip, host_port, 0, 0, own_port)
	get_tree().set_network_peer(peer)

func random_session_id():
	return rng.random_string(8)

func unique_username(username):
	return username + "__" + rng.random_string(8)

func setup_network_ids(player_name):
	self.player_name = player_name
	session_id = random_session_id()
	session_username = unique_username(player_name)
	return session_username

func _reset():
	peer = null

	player_id = 2
	network_id = 0

	network_ids = {}
	multiplayer_active = false

	game = null
	
	replay_saved = false
	
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

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc("register_player", player_name)


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
func _player_disconnected(id):
	multiplayer_active = false
	if get_tree().is_network_server():
		emit_signal("game_error", "Player " + players[id] + " disconnected")
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	multiplayer_active = false
	end_game()

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

remotesync func end_turn_simulation(tick, player_id):
#	if get_tree().get_rpc_sender_id() == network_id:
#		return
	player_id = opponent_player_id(player_id)
	print("ending turn simulation for player " + str(player_id) + " at tick " + str(tick))
	ticks[player_id] = tick
	if ticks[1] == ticks[2]:
		emit_signal("player_turns_synced")

func submit_action(action, data, extra):
	if multiplayer_active:
		action_inputs[player_id]["action"] = action
		action_inputs[player_id]["data"] = data
		action_inputs[player_id]["extra"] = extra
		rpc("multiplayer_turn_ready", player_id)
		print("submitting action: " + action)

func turn_ready(id):
	if ticks[1] != ticks[2]:
		print("desync? ticks[1] = " + str(ticks[1]) + ", ticks[2] = " + str(ticks[2]))
		return false
	return Network.turns_ready[id] and (Network.turns_ready[opponent_player_id(id)])

remotesync func multiplayer_turn_ready(id):
	Network.turns_ready[id] = true
	print("turn ready for player " + str(id))
	emit_signal("player_turn_ready", id)
	if turn_ready(id):
		print("sending action")
		rpc("send_action", action_inputs[player_id]["action"], action_inputs[player_id]["data"], action_inputs[player_id]["extra"], player_id)
		emit_signal("turn_ready")

remote func send_action(action, data, extra, id):
		print("received action: " + str(action))
		action_inputs[id]["action"] = null
		action_inputs[id]["data"] = null
		action_inputs[id]["extra"] = null
		player_objects[id].on_action_selected(action, data, extra)

remotesync func register_player(new_player_name):
	var id = get_tree().get_rpc_sender_id()
	if get_tree().get_network_unique_id() == id:
		network_id = id
	print(id)
	players[id] = new_player_name
	emit_signal("player_list_changed")

func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

remotesync func sync_ids(network_ids):
	self.network_ids = network_ids
	for player in network_ids:
		if network_ids[player] == get_tree().get_network_unique_id():
			player_id = player

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func request_rematch():
	send_rematch_request(player_id)
	rpc("send_rematch_request", player_id)

remotesync func send_rematch_request(player_id):
	rematch_requested[player_id] = true
	if rematch_requested[1] and rematch_requested[2]:
		if get_tree().is_network_server():
			ReplayManager.init()
			begin_game()

func assign_players():
	if get_tree().is_network_server():
		var network_ids = {}
		var player_ids = players.keys()
		assert(player_ids.size() == 2)
		player_ids.shuffle()
		network_ids[1] = player_ids[0]
		network_ids[2] = player_ids[1]
		rpc("sync_ids", network_ids)

func select_character(character):
	rpc("sync_character_selection", player_id, character)

remotesync func sync_character_selection(player_id, character):
	emit_signal("character_selected", player_id, character)

func begin_game():
	if get_tree().is_network_server():
		rematch_requested = {
			1: false,
			2: false,
		}
#		emit_signal("start_game")
		rpc("open_chara_select")

remotesync func open_chara_select():
	emit_signal("start_game")

func end_game():
	if multiplayer_active:
		stop_multiplayer()

func autosave_match_replay(match_data):
	if !replay_saved:
		replay_saved = true
		ReplayManager.save_replay_mp(match_data, players.values()[0], players.values()[1])

func _exit_tree():
	stop_multiplayer()

func stop_multiplayer():
	multiplayer_active = false
	if peer:
		peer.close_connection()
	_reset()
