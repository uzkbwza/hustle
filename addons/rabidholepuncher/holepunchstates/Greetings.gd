""" Greetings """
extends HolePunchState

const GREETINGS_AMOUNT: int = 5
const GREETINGS_CASCADE_PORT_WINDOW: int = 8
const SECONDS_BETWEEN_GREETINGS: float = 0.05
# Total greetings, we do not take into account player number because we send to all players at the same time
const TOTAL_GREETINGS: int = GREETINGS_AMOUNT * ((2 * GREETINGS_CASCADE_PORT_WINDOW) + 1)
# Wait to receive all greetings a minimum of '1 plus the time it takes to send all greetings in window' seconds
const SECONDS_TO_WAIT_FOR_GREETINGS: float = 1 + (TOTAL_GREETINGS * SECONDS_BETWEEN_GREETINGS)
const GREETING_PREFIX: String = "g"

onready var _send_greeting_timer: Timer = $SendGreetingTimer
onready var _wait_greetings_timer: Timer = $WaitGreetingsTimer

# Keys are player names, values are lists of ports to try (includes cascade ports)
var player_greeting_ports: Dictionary = {}
var player_addresses: Dictionary = {}
var greetings_round_sent: int = 0
var _peer: PacketPeerUDP
var own_port: int
# Keys are our ports received by other player greetings, values are number of greets received for each port
# (could it really happen that we receive 2 greetings on different ports?)
var greeting_ports_received: Dictionary = {}
# List of players that we received greetings from
var greeting_players_received: Array = []

func _ready() -> void:
	yield(owner, "ready")
	_send_greeting_timer.connect("timeout", self, "_on_send_greeting_timer_timeout")
	_send_greeting_timer.wait_time = SECONDS_BETWEEN_GREETINGS
	_wait_greetings_timer.connect("timeout", self, "_on_wait_greetings_timer_timeout")
	_wait_greetings_timer.wait_time = SECONDS_TO_WAIT_FOR_GREETINGS
	_wait_greetings_timer.one_shot = true


func enter(msg: Dictionary = {}) -> void:
	debug("Enter " + self.name + " state")
	player_greeting_ports = {}
	player_addresses = {}
	greetings_round_sent = 0
	greeting_ports_received = {}
	greeting_players_received = []
	
	# Msg contains player names with dicts with ip and ports (only port for oneself)
	player_addresses = msg
	own_port = player_addresses[hole_puncher._player_name]
	for player_name in player_addresses.keys():
		if player_name != hole_puncher._player_name:
			var player_init_port: int = int(player_addresses[player_name]["port"])
			var player_ports_to_try: Array = [player_init_port]
			for port in range(player_init_port - GREETINGS_CASCADE_PORT_WINDOW, player_init_port + GREETINGS_CASCADE_PORT_WINDOW + 1):
				if port != player_init_port:
					player_ports_to_try.push_back(port)
			player_greeting_ports[player_name] = player_ports_to_try

	_peer = hole_puncher._peer
	_peer.close()
	_peer.listen(own_port, "*")
	_send_greeting_timer.start()
	
	hole_puncher.emit_signal("holepunch_progress_update", 
								hole_puncher.STATUS_SENDING_GREETINGS, 
								hole_puncher._session_name,
								msg.keys())


func process(delta: float) -> void:
	if _peer.get_available_packet_count() > 0:
		var packet_string = _peer.get_packet().get_string_from_utf8()
		if packet_string.begins_with(GREETING_PREFIX):
			# g:<sender>:<sender_port>:<receiver_port>
			info("Received greeting: " + packet_string)
			var split: PoolStringArray = packet_string.split(":")
			var sender: String = split[1]
			var own_port_by_sender: int = int(split[3])
			greeting_ports_received[own_port_by_sender] = 1 + greeting_ports_received.get(own_port_by_sender, 0)


func exit() -> void:
	_send_greeting_timer.stop()
	_wait_greetings_timer.stop()


func _on_send_greeting_timer_timeout() -> void:
	if greetings_round_sent >= GREETINGS_AMOUNT:
		greetings_round_sent = 0
		for player_name in player_greeting_ports.keys():
			player_greeting_ports[player_name].pop_front()
			if player_greeting_ports[player_name].empty():
				# This means we have sent all greetings we had to send
				# (all lists of ports should be the same size)
				_send_greeting_timer.stop()
				_wait_greetings_timer.start()
				return
		return
	
	for player_name in player_greeting_ports.keys():
		var peer_ip: String = player_addresses[player_name]["ip"]
		var peer_port: int = player_greeting_ports[player_name][0]
		var message: String = PoolStringArray([GREETING_PREFIX, hole_puncher._player_name,
												own_port, str(peer_port)]).join(":")
		send_message(message, _peer, peer_ip, peer_port)
	greetings_round_sent += 1


func _on_wait_greetings_timer_timeout() -> void:
	if greeting_ports_received.empty():
		warning("No greetings received, we are unreachable from outside")
		_state_machine.transition_to("None", {ERROR_STR : hole_puncher.ERR_UNREACHABLE_SELF})
	else:
		info("Finished greetings state")
		var port_to_use: int = _get_most_received_greeting_port()
		player_addresses[hole_puncher._player_name] = port_to_use
		player_addresses["previous_port"] = own_port
		_state_machine.transition_to("Confirmations", player_addresses)


func _get_most_received_greeting_port() -> int:
	var current_count: int = -INF
	var most_received_port: int = -1
	for port in greeting_ports_received.keys():
		if greeting_ports_received[port] > current_count:
			most_received_port = port
	return most_received_port
