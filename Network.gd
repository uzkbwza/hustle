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

const LanDiscoveryScript = preload("res://networking/LanDiscovery.gd")

# yomi hustle coaching for 1 dolla at metafy dot gg slash at eternum lmk

# 128-bit nonce it should be pretty fuckin brute force proof unless yomi hustle cheaters solve quantum computing
const COMMIT_NONCE_BYTES = 16
const COMMIT_NONCE_HEX_LENGTH = 32
const COMMIT_HASH_HEX_LENGTH = 64
# this is essentially a version check lol, it might be unnecessary but indulge me 
# it needs to be bumped if the hash input format changes
const COMMIT_HASH_TAG = "money-check-v1"

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

var lan_discovery = null
var lan_room_active = false
var lan_room_name = ""
var lan_room_address = ""
var lan_room_port = 0
var ids_synced = false
var turn_synced = false
var send_ready = false
var can_open_action_buttons = true
var action_submitted = false
var possible_softlock = false
var steam = false
var forfeiter = 0
var last_action_sent_tick = 0

var relay_spectating = false
var relay_spectate_pending = false
var relay_spectators = {}
var relay_replay_marks = null
var relay_spectator_timer = null
var relay_room_code = ""
var relay_room_info = {}
var relay_room_chat_history = []
var relay_match_chat_history = []
var relay_match_settings = {}
var relay_replay_data = null
var relay_replay_challenger_side = 0
var relay_replay_side = 0
var relay_replay_challenger_name = ""
var relay_replay_challenge_pending = false

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
var relay_id = 0
var players_ready = []

var action_button_panels = {}
# UI only cause ActionButtons.activate() overwrites this mid frame lmao
var turns_ready = {}
var action_inputs = {}

# the commit-reveal is, essentially, each player first sending only a hash of their move
# moves are only revealed once both are in. reset_action_inputs clears this per simulated tick
var commit_hashes = {1: "", 2: ""}
var commit_nonce = ""
# deep copy so edits to the dicts dont break things
var commit_payload = null
var commit_sent = false
var reveal_sent = false

var player_objects = {}
var player_ids = {}
var player_name_colors = {}
var relay_name_colors = {}
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
	# local-only blacklist so people can't callv shit over steam
	"submit_action": true,
	"_reset_commit_state": true,
	"_announce_turn_ready": true,
	"_try_send_reveal": true,
	"_rpc_sender_is_opponent": true,
	"_wire_player_id": true,
	"_snapshot_value": true,
	"_canonical_value": true,
	"compute_commit_hash": true,
	"generate_nonce": true,
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
signal relay_chat_received(sender_name, message)
signal room_chat_received(sender_name, message)
signal room_chat_history_received(history)
signal relay_match_settings_received(settings)
signal relay_replay_challenge_received(challenger_name, replay_data, challenger_side)
signal relay_replay_challenge_accepted()
signal relay_replay_challenge_declined(reason, detail)
signal relay_replay_challenge_cancelled()
signal check_players_ready()
signal opponent_ready()
signal client_actionable()
signal both_players_actionable()
signal client_turn_end()
signal both_players_turn_end()
signal match_ready(match_data)
signal resim_requested()
signal resim_denied()
signal style_save_request_received(target_player_id, requester_id, requester_name, style_name)
signal style_save_response_received(target_player_id, requester_id, requester_name, allowed)
signal force_open_action_buttons()
signal player_count_received(playercount)
signal multiplayer_stopped()
signal received_spectator_match_data(data)
signal spectate_declined()
signal spectator_error(message)
signal room_info_received(info)
signal opponent_left(username, reason)
signal lan_rooms_changed(rooms)

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

	relay_spectator_timer = Timer.new()
	relay_spectator_timer.one_shot = false
	relay_spectator_timer.connect("timeout", self, "_on_relay_spectator_timer_timeout")
	add_child(relay_spectator_timer)
	relay_spectator_timer.start(3)

	randomize()
	_setup_rpc_whitelist()

	lan_discovery = LanDiscoveryScript.new()
	lan_discovery.connect("rooms_changed", self, "_on_lan_rooms_changed")
	add_child(lan_discovery)


func get_multiplayer_active():
	return multiplayer_active and !SteamLobby.SPECTATING and !relay_spectating

func broadcast_rpc(function_name: String, arg=null):
	if steam:
		if !(multiplayer_active or SteamLobby.SPECTATING):
			return
		SteamLobby.broadcast_rpc(function_name, arg)
		return
	if multiplayer_active:
		rpc_(function_name, arg, "remote")

func rpc_(function_name: String, arg=null, type="remotesync"):
	if SteamLobby.SPECTATING or relay_spectating:
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
	if function_name in rpc_blacklist:
		return false
	if function_name in rpc_whitelist:
		return true
	for method in get_method_list():
		if method.name == function_name and (method.flags & METHOD_FLAG_FROM_SCRIPT) != 0:
			rpc_whitelist[function_name] = true
			return true
	print("unrecognized method %s for RPC call. modders please use _whitelist_rpc_method() to fix this." % function_name)
	return false

remotesync func send_match_data(match_data):
	emit_signal("match_locked_in", match_data)

func publish_relay_match_settings(settings):
	if steam or !multiplayer_active or !is_host():
		return
	if !(settings is Dictionary):
		return
	relay_match_settings = settings.duplicate(true)
	rpc_("receive_relay_match_settings", relay_match_settings, "remote")

remote func receive_relay_match_settings(settings):
	if !(settings is Dictionary):
		return
	relay_match_settings = settings.duplicate(true)
	emit_signal("relay_match_settings_received", relay_match_settings)

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

func get_self_id():
	if steam:
		return SteamHustle.STEAM_ID
	if !direct_connect and multiplayer_client:
		return relay_id
	return get_local_id()

func join_game_direct(ip, port, new_player_name):
	_reset()
	player_name = new_player_name
	peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, int(port))
	multiplayer_active = true
	direct_connect = true
	multiplayer_host = false
	get_tree().set_network_peer(peer)

func get_local_lan_address():
	var best = ""
	var best_score = -1
	for addr in IP.get_local_addresses():
		if !_is_lan_ipv4(addr):
			continue
		if addr.begins_with("127.") or addr.begins_with("169.254."):
			continue
		var score = _lan_address_score(addr)
		if score > best_score:
			best_score = score
			best = addr
	if best != "":
		return best
	return "127.0.0.1"

func _lan_address_score(addr):
	if addr.begins_with("192.168.56.") or addr.begins_with("192.168.137.") or addr.begins_with("192.168.99."):
		return 1
	if addr.begins_with("172.17.") or addr.begins_with("172.18.") or addr.begins_with("172.19."):
		return 1
	if addr.begins_with("192.168.0.") or addr.begins_with("192.168.1."):
		return 7
	if addr.begins_with("192.168."):
		return 6
	if addr.begins_with("10."):
		return 5
	if _is_lan_private_172(addr):
		return 3
	return 0

func _is_lan_ipv4(addr):
	var parts = str(addr).split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if !part.is_valid_integer():
			return false
		var n = int(part)
		if n < 0 or n > 255:
			return false
	return true

func _is_lan_private_172(addr):
	var parts = str(addr).split(".")
	if parts.size() != 4:
		return false
	if !parts[0].is_valid_integer() or !parts[1].is_valid_integer():
		return false
	return int(parts[0]) == 172 and int(parts[1]) >= 16 and int(parts[1]) <= 31

func start_lan_hosting(p_room_name, p_address, p_port, p_players=1):
	lan_room_active = true
	lan_room_name = str(p_room_name)
	lan_room_address = str(p_address)
	lan_room_port = int(p_port)
	if lan_discovery != null:
		lan_discovery.start_advertising(lan_room_name, player_name, lan_room_port, p_players)

func update_lan_hosting_players(count):
	if lan_discovery != null:
		lan_discovery.update_players(count)

func stop_lan_hosting():
	if lan_discovery != null:
		lan_discovery.stop_advertising()
	lan_room_active = false
	lan_room_name = ""
	lan_room_address = ""
	lan_room_port = 0

func start_lan_browsing():
	if lan_discovery == null:
		return
	lan_discovery.start_browsing()

func stop_lan_browsing():
	if lan_discovery == null:
		return
	lan_discovery.stop_browsing()

func refresh_lan_rooms():
	if lan_discovery == null:
		return
	lan_discovery.refresh()

func get_lan_rooms():
	if lan_discovery == null:
		return []
	return lan_discovery.get_rooms()

func _on_lan_rooms_changed(rooms):
	emit_signal("lan_rooms_changed", rooms)

func setup_relay_multiplayer(address):
	relay_id = 0
	multiplayer_client = MultiplayerClient.new(address)
	multiplayer_active = true
	direct_connect = false
	get_tree().set_network_peer(multiplayer_client.get_client())

func host_game_relay(new_player_name, public=true, room_name=""):
	if !(multiplayer_client and multiplayer_client.connected):
		return
	multiplayer_host = true
	player_name = new_player_name.substr(0, 32)
	players = {}
	player_name_colors = {}
	relay_room_chat_history = []
	rpc_id(1, "create_match", player_name, public, room_name, local_name_color())
	yield(self, "match_code_received")
	relay_room_code = relay_room_code.to_upper()

func join_game_relay(new_player_name, room_code):
	if !(multiplayer_client and multiplayer_client.connected):
		return
	multiplayer_host = false
	player_name = new_player_name.substr(0, 32)
	players = {}
	player_name_colors = {}
	relay_room_code = room_code.to_upper()
	relay_room_chat_history = []
	rpc_id(1, "player_join_game", player_name, room_code, local_name_color())
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
	second_register = false

	network_ids = {}
	multiplayer_active = false

	possible_softlock = false

	game = null
	if multiplayer_client != null:
		multiplayer_client.end_connection()
	multiplayer_client = null
	multiplayer_host = false

	replay_saved = false
	direct_connect = false
	rematch_menu = false

	stop_lan_hosting()

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
	player_name_colors = {}
	relay_name_colors = {}
	
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

	_reset_commit_state()

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
	
	relay_spectating = false
	relay_spectate_pending = false
	relay_spectators.clear()
	relay_replay_marks = null
	relay_room_code = ""
	relay_room_info = {}
	relay_room_chat_history = []
	relay_match_chat_history = []
	relay_match_settings = {}
	relay_replay_data = null
	relay_replay_challenger_side = 0
	relay_replay_side = 0
	relay_replay_challenger_name = ""
	relay_replay_challenge_pending = false
	
	get_tree().set_network_peer(null)

# Callback from SceneTree.
func player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	if direct_connect:
		rpc_("register_player", [player_name, id, Global.VERSION])

func pid_to_username(player_id):
		if player_id != 1 and player_id != 2:
			return ""
		if is_instance_valid(game):
			if SteamLobby.SPECTATING or relay_spectating or !network_ids.has(player_id):
				var current = Global.current_game
				var match_data = current.match_data if is_instance_valid(current) else null
				if match_data is Dictionary:
					var user_data = match_data.get("user_data", {})
					if user_data is Dictionary and user_data.has("p" + str(player_id)):
						return str(user_data["p" + str(player_id)])
				return ""
			return str(players.get(network_ids.get(player_id), ""))
		# synced player list so chat still shows names.
		if network_ids.has(player_id):
			var net_id = network_ids[player_id]
			if players.has(net_id):
				return str(players[net_id])
		if player_id == self.player_id:
			return player_name
		return ""

func player_name_color(pid: int) -> String:
	var hex = str(player_name_colors.get(pid, ""))
	if hex != "":
		return hex
	if pid == player_id and Global.has_name_color():
		return Global.get_name_color().to_html(false)
	return "ff333d" if pid == 2 else "1d8df5"

func name_color_for(sender_name: String) -> String:
	if relay_name_colors.has(sender_name):
		var relay_hex = str(relay_name_colors[sender_name])
		if relay_hex != "":
			return relay_hex
	for pid in [1, 2]:
		if pid_to_username(pid) == sender_name:
			return player_name_color(pid)
	if sender_name == player_name or sender_name == Global.get_player_data().username:
		if Global.has_name_color():
			return Global.get_name_color().to_html(false)
	return "999999"

func local_name_color() -> String:
	if Global.has_name_color():
		return Global.get_name_color().to_html(false)
	return ""


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

	_reset_commit_state()

func _reset_commit_state():
	commit_hashes = {1: "", 2: ""}
	commit_nonce = ""
	commit_payload = null
	commit_sent = false
	reveal_sent = false

# Callback from SceneTree.
remote func player_disconnected(id):
#	multiplayer_active = false
	if !(id in players):
		return
	if direct_connect and is_host() and !is_instance_valid(game) and !Global.css_open:
		unregister_player(id)
		return
	# Only the opponent's departure may count as an opponent quit;
	# spectator drops must never forge a forfeit.
	if !steam and !direct_connect:
		var opponent_net_id = 0
		var opp_player_id = opponent_player_id(player_id)
		if network_ids.has(opp_player_id):
			opponent_net_id = network_ids[opp_player_id]
		if opponent_net_id == 0 or id != opponent_net_id:
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
	if _rpc_from_wire() and id == player_id:
		return
	emit_signal("sync_timer_request", id, timer)
	if steam:
		SteamLobby.spectator_sync_timers(id, timer)
	elif !relay_spectators.empty():
		_push_to_relay_spectators("spectator_sync_timers", {"id": id, "time": timer})

func sync_timer(id, time):
	rpc_("receive_player_timer", [id, time], "remotesync")

# commit phase
func submit_action(action, data, extra):
	if !multiplayer_active:
		return
	# meant to limit to one lock in per turn
	if commit_sent:
		print("submit_action: already locked in this turn: " + str(action))
		return
	var nonce = generate_nonce(COMMIT_NONCE_BYTES)
	if nonce == "":
		push_error("Network: lock in not sent")
		emit_signal("game_error", "Could not lock in: rng failed")
		return
	action_inputs[player_id]["action"] = action
	action_inputs[player_id]["data"] = data
	action_inputs[player_id]["extra"] = extra
	commit_payload = {
		"action": action,
		"data": _snapshot_value(data),
		"extra": _snapshot_value(extra),
	}
	commit_nonce = nonce
	commit_hashes[player_id] = compute_commit_hash(player_id, nonce, commit_payload["action"], commit_payload["data"], commit_payload["extra"])
	commit_sent = true
	print("submitting action: " + str(action))
	_announce_turn_ready(player_id)
	rpc_("multiplayer_commit_hash", [player_id, commit_hashes[player_id]], "remote")
	_try_send_reveal()

# i feel like ive gotten way too into the idea of making this shit infallible but i cant help it
# if this fails it just returns an empty string instead
func generate_nonce(num_bytes: int = COMMIT_NONCE_BYTES) -> String:
	var crypto = Crypto.new()
	if crypto == null:
		return ""
	var bytes = crypto.generate_random_bytes(num_bytes)
	if bytes == null or bytes.size() != num_bytes:
		return ""
	return bytes.hex_encode()

func _snapshot_value(v):
	if v is Dictionary or v is Array:
		return v.duplicate(true)
	return v

func _canonical_value(v) -> String:
	var t = typeof(v)
	if t == TYPE_ARRAY:
		var items = PoolStringArray()
		for item in v:
			items.append(_canonical_value(item))
		return "[" + items.join(",") + "]"
	if t == TYPE_DICTIONARY:
		var entries = []
		for k in v.keys():
			entries.append(_canonical_value(k) + ":" + _canonical_value(v[k]))
		entries.sort()
		return "{" + PoolStringArray(entries).join(",") + "}"
	return var2bytes(v).hex_encode()

# if u r wondering why it hashes in the player id it's because i felt like it
func compute_commit_hash(pid: int, nonce: String, action, data, extra) -> String:
	var payload = COMMIT_HASH_TAG + "|" + str(pid) + "|" + nonce + "|" + _canonical_value([action, data, extra])
	return payload.sha256_text()

func get_sender_id():
#	if direct_connect:
	return get_tree().get_rpc_sender_id()

func _rpc_from_wire():
	var sender_id = get_tree().get_rpc_sender_id()
	if sender_id == 0:
		return false
	if direct_connect and sender_id == get_self_id():
		return false
	return true

# checking whether rpc came from opponent, for steam we check packet sender
# for new legacy it's just always gonna be peer 1
func _rpc_sender_is_opponent() -> bool:
	if steam:
		var sender = SteamLobby.p2p_packet_sender
		return typeof(sender) == TYPE_INT and sender != 0 and sender == SteamLobby.OPPONENT_ID
	if direct_connect:
		var sender_id = get_sender_id()
		return sender_id != 0 and sender_id == network_ids.get(opponent_player_id(player_id), -1)
	return get_tree().get_rpc_sender_id() == 1

func _wire_player_id(v) -> int:
	if typeof(v) == TYPE_INT:
		return v
	return 0

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
	if _rpc_from_wire() and player_id == self.player_id:
		return
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
		var attempts = 0
		while players.keys().size() != 2:
			if attempts >= 30:
				print("assign_players: only %d player(s) registered" % [players.keys().size()])
				emit_signal("game_error", "Your opponent disconnected or never finished joining. Please try again.")
				return
			attempts += 1
			yield(get_tree().create_timer(0.1), "timeout")
		var assigned_ids = {}
		var player_keys = players.keys()
		player_keys.shuffle()
		assigned_ids[1] = player_keys[0]
		assigned_ids[2] = player_keys[1]
		rpc_("sync_ids", assigned_ids)

func assign_players_for_replay_challenge(replay_data):
	print("assigning players for replay challenge")
	if steam:
		player_id = SteamLobby.PLAYER_SIDE
		if SteamLobby.PLAYER_SIDE == 1:
			network_ids[1] = SteamHustle.STEAM_ID
			network_ids[2] = SteamLobby.OPPONENT_ID
		else:
			network_ids[1] = SteamLobby.OPPONENT_ID
			network_ids[2] = SteamHustle.STEAM_ID
	elif network_ids.size() < 2:
		return
	ReplayManager.frames = replay_data.frames
	if ReplayManager.frames.has("finished"):
		ReplayManager.frames["finished"] = false
	if ReplayManager.frames.has("end_reason"):
		ReplayManager.frames.erase("end_reason")
	ReplayManager.playback = true
	ReplayManager.replaying_ingame = true
	var match_data = replay_data.duplicate(true)
	match_data.erase("frames")
	match_data["replay_challenge"] = true
	match_data["singleplayer"] = false
	var trimmed_max = 0
	for id in [1, 2]:
		for tick in ReplayManager.frames[id].keys():
			if int(tick) > trimmed_max:
				trimmed_max = int(tick)
	var game_length = int(match_data.get("game_length", 3000))
	if game_length <= trimmed_max + 120:
		match_data["game_length"] = trimmed_max + 3600
	multiplayer_active = true
	emit_signal("match_ready", match_data)

func relay_opponent_id() -> int:
	var self_id = get_self_id()
	for id in players:
		if id != self_id:
			return int(id)
	return 0

func _assign_relay_replay_sides(side: int) -> bool:
	if side != 1 and side != 2:
		return false
	var opponent = relay_opponent_id()
	if opponent == 0:
		return false
	player_id = side
	network_ids = {
		side: get_self_id(),
		opponent_player_id(side): opponent,
	}
	return true

func _relay_replay_missing_characters(replay_data: Dictionary) -> Array:
	var missing = []
	var characters = replay_data.get("selected_characters", {})
	for i in [1, 2]:
		var char_data = characters.get(i, {})
		if !(char_data is Dictionary):
			continue
		var char_name = char_data.get("name", "")
		if char_name != "" and !Global.has_character(char_name):
			missing.append(Global.character_display_name(char_name))
	return missing

func send_relay_replay_challenge(match_data: Dictionary, side: int):
	if steam or !(multiplayer_client and multiplayer_client.connected):
		return
	if is_instance_valid(game) or relay_spectating:
		return
	if side != 1 and side != 2:
		return
	if relay_opponent_id() == 0:
		return
	var payload = match_data.duplicate(true)
	payload["frames"] = ReplayManager.frames

	var raw: PoolByteArray = var2bytes(payload)
	var compressed: PoolByteArray = raw.compress(File.COMPRESSION_DEFLATE)

	relay_replay_data = payload
	relay_replay_challenger_side = side
	relay_replay_side = side
	relay_replay_challenger_name = player_name
	rpc_id(1, "relay", "receive_relay_replay_challenge", [player_name, compressed, side])

remote func receive_relay_replay_challenge(challenger_name, compressed, challenger_side):
	if steam:
		return
	if is_instance_valid(game) or relay_spectating or relay_replay_challenge_pending or relay_replay_data != null:
		decline_relay_replay_challenge("busy")
		return
	if !(compressed is PoolByteArray):
		return
	var inflated: PoolByteArray = compressed.decompress_dynamic(64 * 1024 * 1024, File.COMPRESSION_DEFLATE)
	if inflated.empty():
		return
	var replay_data = bytes2var(inflated)
	if !(replay_data is Dictionary):
		return
	if int(challenger_side) != 1 and int(challenger_side) != 2:
		return
	var version = str(replay_data.get("version", ""))
	if version != "" and version != str(Global.VERSION):
		decline_relay_replay_challenge("version", version)
		return
	var missing = _relay_replay_missing_characters(replay_data)
	if !missing.empty():
		decline_relay_replay_challenge("missing_mods", missing)
		return
	relay_replay_data = replay_data
	relay_replay_challenger_side = int(challenger_side)
	relay_replay_side = opponent_player_id(relay_replay_challenger_side)
	relay_replay_challenger_name = str(challenger_name)
	relay_replay_challenge_pending = true
	emit_signal("relay_replay_challenge_received", relay_replay_challenger_name, replay_data, relay_replay_challenger_side)

func accept_relay_replay_challenge():
	if !relay_replay_challenge_pending or relay_replay_data == null:
		return
	if !_assign_relay_replay_sides(relay_replay_side):
		return
	var replay_data = relay_replay_data
	relay_replay_data = null
	relay_replay_challenge_pending = false
	rpc_id(1, "relay", "receive_relay_replay_challenge_accepted", [])
	assign_players_for_replay_challenge(replay_data)

remote func receive_relay_replay_challenge_accepted():
	if relay_replay_data == null:
		return
	if !_assign_relay_replay_sides(relay_replay_side):
		return
	var replay_data = relay_replay_data
	relay_replay_data = null
	assign_players_for_replay_challenge(replay_data)

func decline_relay_replay_challenge(reason="", detail=null):
	rpc_id(1, "relay", "receive_relay_replay_challenge_declined", [reason, detail])
	relay_replay_challenge_pending = false
	relay_replay_data = null
	relay_replay_challenger_side = 0
	relay_replay_side = 0
	relay_replay_challenger_name = ""

remote func receive_relay_replay_challenge_declined(reason="", detail=null):
	relay_replay_challenge_pending = false
	relay_replay_data = null
	relay_replay_challenger_side = 0
	relay_replay_side = 0
	relay_replay_challenger_name = ""
	emit_signal("relay_replay_challenge_declined", reason, detail)

func cancel_relay_replay_challenge():
	if relay_replay_data == null:
		return
	rpc_id(1, "relay", "receive_relay_replay_challenge_cancelled", [])
	relay_replay_data = null
	relay_replay_challenge_pending = false
	relay_replay_challenger_side = 0
	relay_replay_side = 0
	relay_replay_challenger_name = ""

remote func receive_relay_replay_challenge_cancelled():
	relay_replay_challenge_pending = false
	relay_replay_data = null
	relay_replay_challenger_side = 0
	relay_replay_side = 0
	relay_replay_challenger_name = ""
	emit_signal("relay_replay_challenge_cancelled")

func select_character(character, style=null):
	rpc_("sync_character_selection", [player_id, character, style])

func forfeit(opponent=false):
	print("forfeiting")
	if !opponent:
		rpc_("player_forfeit", player_id)
	else:
		if is_instance_valid(game):
			player_forfeit(opponent_player_id(player_id))
	pass

remotesync func player_forfeit(player_id):
	if is_instance_valid(game):
		game.forfeit(player_id)
		forfeiter = player_id
		if player_id != self.player_id and !SteamLobby.SPECTATING and !relay_spectating and !ReplayManager.playback:
			SteamHustle.unlock_achievement("ACH_WIN_BY_FORFEIT")
		if steam and !SteamLobby.SPECTATING:
			SteamLobby.spectate_forfeit(player_id)
		elif !relay_spectating and !relay_spectators.empty():
			_push_to_relay_spectators("spectator_player_forfeit", player_id)

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
	if steam and (SteamLobby.SPECTATING or SteamLobby.REQUESTING_TO_SPECTATE != 0):
		SteamLobby.leave_spectate()
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

func request_spectate(code):
	if steam or !(multiplayer_client and multiplayer_client.connected):
		return
	relay_spectate_pending = true
	rpc_id(1, "request_spectate", player_name.substr(0, 64), code, local_name_color())

func cancel_spectate_request():
	if steam:
		return
	relay_spectate_pending = false
	if multiplayer_client and multiplayer_client.connected:
		rpc_id(1, "end_spectate")

func request_room_info(room_code):
	if steam or !(multiplayer_client and multiplayer_client.connected):
		return
	rpc_id(1, "fetch_room_info", room_code)

remote func receive_room_info(info):
	if info is Dictionary:
		relay_room_info = info
		var players = info.get("players", [])
		var player_colors = info.get("player_colors", [])
		for i in range(min(players.size(), player_colors.size())):
			relay_name_colors[str(players[i])] = str(player_colors[i])
		var spectators = info.get("spectators", [])
		var spectator_colors = info.get("spectator_colors", [])
		for i in range(min(spectators.size(), spectator_colors.size())):
			relay_name_colors[str(spectators[i])] = str(spectator_colors[i])
	emit_signal("room_info_received", info)

remote func receive_name_color(username, hex):
	relay_name_colors[str(username)] = str(hex)

remote func receive_name_colors(colors):
	if !(colors is Dictionary):
		return
	for username in colors:
		relay_name_colors[str(username)] = str(colors[username])

remote func receive_opponent_left(username, reason):
	if multiplayer_active and is_instance_valid(game) and !game.game_finished:
		for id in players.keys():
			if players[id] == username:
				player_disconnected(id)
				return
		emit_signal("player_disconnected")
		return
	for id in players.keys():
		if players[id] == username:
			players.erase(id)
			relay_name_colors.erase(str(username))
			emit_signal("player_list_changed")
			break
	emit_signal("opponent_left", username, reason)

func leave_match():
	if steam or !(multiplayer_client and multiplayer_client.connected):
		return
	rpc_id(1, "leave_match")

func end_spectate():
	if steam:
		SteamLobby.leave_spectate()
		return
	if relay_spectating:
		_stop_relay_spectating()
		if multiplayer_client and multiplayer_client.connected:
			rpc_id(1, "end_spectate")

func _stop_relay_spectating():
	relay_spectating = false
	relay_spectate_pending = false
	relay_spectators.clear()
	relay_replay_marks = null

remote func spectate_accept(data):
	if !relay_spectate_pending and !relay_spectating:
		return
	if !(data is Dictionary) or !(data.get("match_data") is Dictionary) or data.get("replay") == null:
		return
	if relay_spectating:
		return
	var match_data = data.match_data
	var missing = []
	for i in [1, 2]:
		var char_data = match_data.get("selected_characters", {}).get(i, {})
		var char_name = char_data.get("name", "")
		if char_name != "" and !Global.has_character(char_name):
			missing.append(Global.character_display_name(char_name))
	if missing.size() > 0:
		relay_spectate_pending = false
		relay_spectating = false
		if multiplayer_client and multiplayer_client.connected:
			rpc_id(1, "end_spectate")
		emit_signal("spectator_error", "You're missing the mods for this match: " + ", ".join(missing))
		return
	relay_spectating = true
	relay_spectate_pending = false
	multiplayer_active = false
	relay_replay_marks = null
	ReplayManager.init()
	match_data["replay"] = data.replay
	ReplayManager.frames = data.replay
	emit_signal("received_spectator_match_data", match_data)

remote func spectator_replay_update(replay):
	if !relay_spectating or !(replay is Dictionary):
		return
	for pid in [1, 2]:
		if !replay.has(pid):
			continue
		if !ReplayManager.frames.has(pid):
			ReplayManager.frames[pid] = {}
		for tick in replay[pid].keys():
			ReplayManager.frames[pid][tick] = replay[pid][tick]
	if replay.get("finished", false):
		ReplayManager.frames["finished"] = true
	if replay.has("emotes") and replay["emotes"] is Dictionary:
		if !ReplayManager.frames.has("emotes") or !(ReplayManager.frames["emotes"] is Dictionary):
			ReplayManager.frames["emotes"] = {1: {}, 2: {}}
		for pid in replay["emotes"].keys():
			if !ReplayManager.frames["emotes"].has(pid):
				ReplayManager.frames["emotes"][pid] = {}
			for tick in replay["emotes"][pid].keys():
				ReplayManager.frames["emotes"][pid][tick] = replay["emotes"][pid][tick]

remote func spectator_sync_timers(data):
	if !relay_spectating or !(data is Dictionary):
		return
	emit_signal("sync_timer_request", data.get("id"), data.get("time"))

remote func spectator_turn_ready(id):
	if relay_spectating:
		emit_signal("player_turn_ready", id)

remote func spectator_player_forfeit(player_id):
	if relay_spectating:
		player_forfeit(player_id)

remote func receive_spectate_declined():
	if relay_spectate_pending:
		relay_spectate_pending = false
		emit_signal("spectate_declined")

remote func spectate_ended(disconnected_id, reason="", player_name=""):
	if relay_spectators.has(disconnected_id):
		relay_spectators.erase(disconnected_id)
	if int(disconnected_id) == 0:
		if relay_spectate_pending:
			relay_spectate_pending = false
			emit_signal("spectate_declined")
		if relay_spectating:
			_stop_relay_spectating()
			if is_instance_valid(game):
				game = null
				Global.reload()
			else:
				emit_signal("spectate_declined")

remote func spectate_request(spectator_id):
	if steam:
		return
	if !is_instance_valid(game):
		relay_spectators[spectator_id] = false
		return
	relay_spectators[spectator_id] = true
	rpc_id(1, "spectator_accept", spectator_id, _spectate_accept_data())

func _spectate_accept_data():
	return {
		"spectate_accept": get_tree().get_network_unique_id(),
		"match_data": game.match_data,
		"replay": ReplayManager.frames,
	}

func _push_replay_updates_delta():
	if steam or relay_spectators.empty():
		return
	if !(multiplayer_client and multiplayer_client.connected):
		return
	if relay_replay_marks == null:
		relay_replay_marks = {"ticks": {1: -1, 2: -1}, "emotes": {1: -1, 2: -1}, "finished": false}
	var frames = ReplayManager.frames
	var delta = {}
	for pid in [1, 2]:
		if !frames.has(pid):
			continue
		var max_tick = -1
		for tick in frames[pid].keys():
			if int(tick) > max_tick:
				max_tick = int(tick)
		if max_tick < relay_replay_marks.ticks[pid]:
			relay_replay_marks.ticks[pid] = -1
		for tick in frames[pid].keys():
			if int(tick) <= relay_replay_marks.ticks[pid]:
				continue
			if !delta.has(pid):
				delta[pid] = {}
			delta[pid][tick] = frames[pid][tick]
		relay_replay_marks.ticks[pid] = max_tick
	if frames.get("finished", false) and !relay_replay_marks.finished:
		delta["finished"] = true
		relay_replay_marks.finished = true
	var emote_frames = frames.get("emotes", null)
	if emote_frames is Dictionary:
		for pid in [1, 2]:
			if !emote_frames.has(pid):
				continue
			for tick in emote_frames[pid].keys():
				if int(tick) <= relay_replay_marks.emotes[pid]:
					continue
				if !delta.has("emotes"):
					delta["emotes"] = {}
				if !delta["emotes"].has(pid):
					delta["emotes"][pid] = {}
				delta["emotes"][pid][tick] = emote_frames[pid][tick]
				relay_replay_marks.emotes[pid] = int(tick)
	if delta.empty():
		return
	_push_to_relay_spectators("spectator_replay_update", delta)

func _push_to_relay_spectators(function_name, arg=null):
	if steam or relay_spectators.empty():
		return
	if !(multiplayer_client and multiplayer_client.connected):
		return
	rpc_id(1, "relay_to_spectators", function_name, arg)

func _on_relay_spectator_timer_timeout():
	if steam:
		return
	if relay_room_code != "" and multiplayer_client and multiplayer_client.connected:
		rpc_id(1, "fetch_room_info", relay_room_code)
	if relay_spectators.empty():
		return
	if !is_instance_valid(game):
		return
	for spectator_id in relay_spectators.keys():
		if !relay_spectators[spectator_id]:
			relay_spectators[spectator_id] = true
			rpc_id(1, "spectator_accept", spectator_id, _spectate_accept_data())
	_push_replay_updates_delta()

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
	# politely directing to my previous statement
	if commit_sent:
		rpc_("multiplayer_commit_hash", [player_id, commit_hashes[player_id]], "remote")
		if reveal_sent:
			send_current_action_reveal()
	else:
		print("the answer is no")

remote func my_turn_started(player_id):
	if player_id == opponent_player_id(player_id):
		emit_signal("opponent_ready")

remote func receive_match_code(code):
	emit_signal("match_code_received")

# reveal phase
remote func send_action_reveal(sender_player_id, nonce, action, data, extra):
	if SteamLobby.SPECTATING or relay_spectating:
		return
	var opp_id = opponent_player_id(player_id)
	if _wire_player_id(sender_player_id) != opp_id:
		print("Network: how?? " + str(sender_player_id))
		return
	if !_rpc_sender_is_opponent():
		print("Network: who tf r u lmaooooo")
		return
	if action_inputs[opp_id]["action"] != null:
		return
	# me when race conditions. hopefully there are none
	if !commit_sent or commit_hashes[player_id] == "" or commit_hashes[opp_id] == "":
		print("Network:" + str(opp_id) + " showed his hand")
		return
	if !(nonce is String) or nonce.length() != COMMIT_NONCE_HEX_LENGTH:
		print("Network:" + str(opp_id) + " sending bullshit")
		return
	if compute_commit_hash(opp_id, nonce, action, data, extra) != commit_hashes[opp_id]:
		print("Network:" + str(opp_id) + " is lying")
		emit_signal("game_error", "you're playing casualty bro")
		return
	var obj = player_objects.get(opp_id, null)
	if obj == null or !is_instance_valid(obj):
		print("Network: this guy genuinely doesn't exist")
		return
	print("received action: " + str(action))
	action_inputs[opp_id]["action"] = action
	action_inputs[opp_id]["data"] = data
	action_inputs[opp_id]["extra"] = extra
	obj.on_action_selected(action, data, extra)
	rpc_("opponent_received_action", null, "remote")

remote func opponent_received_action():
	print("opponent received my action")
	possible_softlock = false

remote func check_tick_sync(tick):
	pass

remotesync func send_chat_message(player_id, message):
	emit_signal("chat_message_received", player_id, message)

func _record_relay_chat(history, sender_name, message, name_color=""):
	if message == "":
		return
	history.append({"name": str(sender_name), "message": str(message), "color": str(name_color)})
	while history.size() > 200:
		history.pop_front()

func send_relay_chat(message):
	if steam:
		return
	if !(multiplayer_client and multiplayer_client.connected):
		return
	message = message.strip_edges()
	if message == "":
		return
	_record_relay_chat(relay_match_chat_history, player_name, message, local_name_color())
	emit_signal("relay_chat_received", player_name, message)
	rpc_id(1, "relay_chat", message)

remote func receive_relay_chat(sender_name, message, name_color=""):
	if name_color != "":
		relay_name_colors[str(sender_name)] = str(name_color)
	_record_relay_chat(relay_match_chat_history, sender_name, message, name_color)
	emit_signal("relay_chat_received", sender_name, message)

func send_room_chat(message):
	if steam:
		return
	message = message.strip_edges()
	if message == "":
		return
	if direct_connect:
		if !multiplayer_active:
			return
		_record_relay_chat(relay_room_chat_history, player_name, message, local_name_color())
		emit_signal("room_chat_received", player_name, message)
		rpc_("receive_room_chat", [player_name, message, local_name_color()])
		return
	if !(multiplayer_client and multiplayer_client.connected):
		return
	_record_relay_chat(relay_room_chat_history, player_name, message, local_name_color())
	emit_signal("room_chat_received", player_name, message)
	rpc_id(1, "relay_room_chat", message)

remote func receive_room_chat(sender_name, message, name_color=""):
	if name_color != "":
		relay_name_colors[str(sender_name)] = str(name_color)
	_record_relay_chat(relay_room_chat_history, sender_name, message, name_color)
	emit_signal("room_chat_received", sender_name, message)

remote func receive_room_chat_history(history):
	if history is Array:
		relay_room_chat_history.clear()
		for entry in history:
			if entry is Array and entry.size() >= 3:
				_record_relay_chat(relay_room_chat_history, entry[0], entry[2], entry[1])
		emit_signal("room_chat_history_received", history)

remotesync func end_turn_simulation(tick, player_id):
#	if get_sender_id() == network_id:
#		return
	if _rpc_from_wire() and player_id == self.player_id:
		return
	player_id = opponent_player_id(player_id)
	print("ending turn simulation for player " + str(player_id) + " at tick " + str(tick))
	ticks[player_id] = tick
	if ticks[1] == ticks[2]:
		turn_synced = true
		send_ready = false
		can_open_action_buttons = true
		emit_signal("player_turns_synced")
		emit_signal("force_open_action_buttons")
		_try_send_reveal()

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

# storing opponent hash
remote func multiplayer_commit_hash(id, hash_val):
	if SteamLobby.SPECTATING or relay_spectating:
		return
	var opp_id = opponent_player_id(player_id)
	if _wire_player_id(id) != opp_id:
		print("Network: who tf r u lmaoooo " + str(id))
		return
	if !_rpc_sender_is_opponent():
		print("Network: no actually who the fuck are you")
		return
	if !(hash_val is String) or hash_val.length() != COMMIT_HASH_HEX_LENGTH:
		print("Network: sending bullshit " + str(opp_id))
		return
	var existing = commit_hashes[opp_id]
	if existing != "":
		if existing != hash_val:
			print("Network: commit different from first one" + str(opp_id))
		_try_send_reveal()
		return
	commit_hashes[opp_id] = hash_val
	_announce_turn_ready(opp_id)
	_try_send_reveal()

func _announce_turn_ready(id):
	turns_ready[id] = true
	print("turn ready for player " + str(id))
	emit_signal("player_turn_ready", id)
	if steam:
		SteamLobby.spectator_turn_ready(id)
	elif !relay_spectating and !relay_spectators.empty():
		_push_to_relay_spectators("spectator_turn_ready", id)

# reveal phase
func _try_send_reveal():
	if !commit_sent or reveal_sent:
		return
	if commit_hashes[player_id] == "" or commit_hashes[opponent_player_id(player_id)] == "":
		return
	if ticks[1] != ticks[2]:
		print("desync? ticks[1] = " + str(ticks[1]) + ", ticks[2] = " + str(ticks[2]))
		return
	reveal_sent = true
	action_submitted = true
	print("sending action")
	last_action = action_inputs[player_id]
	if is_instance_valid(game):
		last_action_sent_tick = game.current_tick
	send_current_action_reveal()
	possible_softlock = true
	emit_signal("turn_ready")
	turn_synced = false
	can_open_action_buttons = false
	send_ready = true

# no-op until _try_send_reveal allows it
func send_current_action_reveal():
	if !reveal_sent or commit_payload == null or commit_nonce == "":
		return
	rpc_("send_action_reveal", [player_id, commit_nonce, commit_payload["action"], commit_payload["data"], commit_payload["extra"]], "remote")

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
	
	var version_matches = false
	if version is Dictionary and Global.VERSION is Dictionary:
		version_matches = version == Global.VERSION
	else:
		version_matches = Global.base_version(version) == Global.base_version(Global.VERSION)
	if !version_matches:
		emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. You or your opponent must update to the newest version." % [Global.VERSION, version])
#		emit_signal("game_error", "Mismatched game versions. You: %s, Opponent: %s. Get the newest version at ivysly.itch.io." % [Global.VERSION, version])
		return
	if get_self_id() == id:
		network_id = id
	print("registering player: " + str(id))
	players[id] = new_player_name
	emit_signal("player_list_changed")

remotesync func sync_ids(network_ids):
	self.network_ids = network_ids
	for player in network_ids:
		if network_ids[player] == get_self_id():
			player_id = player
	ids_synced = true
	emit_signal("player_ids_synced")

remotesync func send_rematch_request(player_id):
	if _rpc_from_wire() and player_id == self.player_id:
		return
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

remotesync func sync_name_color(player_id, hex):
	player_name_colors[player_id] = hex

remotesync func sync_character_selection(player_id, character, style=null):
	if _rpc_from_wire() and player_id == self.player_id:
		return
	print("player %s selected character" % [str(player_id)])
	styles[player_id] = style
	emit_signal("character_selected", player_id, character, style)

remotesync func open_chara_select():
	print("opening character select")
	player_name_colors.clear()
	if Global.has_name_color():
		rpc_("sync_name_color", [player_id, Global.get_name_color().to_html(false)])
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

remote func receive_style_save_request(target_player_id, requester_name, style_name):
	var sender_id = 0
	var display_name = requester_name
	if steam:
		sender_id = SteamLobby.p2p_packet_sender
		if sender_id != 0:
			display_name = Steam.getFriendPersonaName(sender_id)
	emit_signal("style_save_request_received", target_player_id, sender_id, display_name, style_name)

remote func receive_style_save_response(target_player_id, requester_id, requester_name, allowed):
	if steam:
		var expected = network_ids.get(target_player_id, 0)
		if expected != 0 and SteamLobby.p2p_packet_sender != expected:
			return
	emit_signal("style_save_response_received", target_player_id, requester_id, requester_name, allowed)

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

remote func test_relay():
	print("relay test")

remote func room_join_confirm():
	emit_signal("relay_match_joined")

remote func room_join_deny(message):
	relay_room_code = ""
	emit_signal("game_error", message)

remote func receive_match_id(match_id):
	print("received match id: %s" % [match_id])
	relay_room_code = str(match_id).to_upper()
	emit_signal("match_code_received", match_id)

remote func player_connected_relay():
	rpc_("register_player", [player_name, get_self_id(), Global.VERSION])

remote func your_relay_id(received):
	relay_id = received

func is_modded():
	return false

func on_turn_started():
	if steam:
		SteamLobby.update_spectators(ReplayManager.frames)
	elif !relay_spectators.empty() and is_instance_valid(game):
		_push_replay_updates_delta()

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
