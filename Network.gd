extends Node
signal player_turns_synced()
# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 1209

# Max number of players.
const MAX_PEERS = 2

var peer = null

var player_id = 2
var network_id = 0

# Name for my player.
var player_name = "Me"

var match_data = {}
var multiplayer_active = false

var game

var ticks = {
	1: null,
	2: null
}

# Names for remote players in id:name format.
var players = {}
var players_ready = []

var action_button_panels = {
	1: null,
	2: null,
}

var turns_ready = {
	1: false,
	2: false
}

var action_inputs = {
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

var player_objects = {
	1: null,
	2: null
}

var player_ids = {
}

var rematch_requested = {
	1: false,
	2: false,
}

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)
signal start_game()



# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	rpc("register_player", player_name)

func opponent_id(pid=player_id):
	if pid == 1:
		return match_data[2]
	return match_data[1]

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
	end_game()
	get_tree().reload_current_scene()

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
	if turn_ready(id):
		print("sending action")
		rpc("send_action", action_inputs[player_id]["action"], action_inputs[player_id]["data"], action_inputs[player_id]["extra"], player_id)
		
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

remotesync func game_start(match_data):
	self.match_data = match_data
	for player in match_data:
		if match_data[player] == get_tree().get_network_unique_id():
			player_id = player
	emit_signal("start_game")

func host_game(new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(peer)
	multiplayer_active = true
	rpc("register_player", new_player_name)

func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer_active = true
	get_tree().set_network_peer(peer)

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
			begin_game()

func begin_game():
	assert(get_tree().is_network_server())
	rematch_requested = {
		1: false,
		2: false,
	}
	var match_data = {}
	var player_ids = players.keys()
	assert(player_ids.size() == 2)
	player_ids.shuffle()
	match_data[1] = player_ids[0]
	match_data[2] = player_ids[1]
	self.player_ids[0] = match_data[1]
	self.player_ids[1] = match_data[2]
	rpc("game_start", match_data)

func end_game():
	stop_multiplayer()

func stop_multiplayer():
	multiplayer_active = false
	peer.close_connection()

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	randomize()
