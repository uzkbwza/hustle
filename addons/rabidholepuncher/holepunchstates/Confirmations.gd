""" Confirmations """
extends HolePunchState

const CONFIRMS_CASCADE_PORT_WINDOW: int = 8
const SECONDS_BETWEEN_CONFIRMS: float = 0.05
const CONFIRM_PREFIX: String = "c"

const HOST_SECONDS_TO_START: float = 2.0
const CLIENT_MAX_HOST_WAIT_SECONDS: float = 2.0
const START_MESSAGE_AMOUNT: int = 8
const START_PREFIX: String = "s"
const START_CONFIRM_PREFIX: String = "y"
const HOST_START_TIMER_SECONDS: float = 1.5
const CLIENT_START_IN_SECONDS: float = 2 * HOST_START_TIMER_SECONDS

onready var _send_confirmation_timer: Timer = $SendConfirmationTimer

"""
If host, this timer is used as a max time to wait for other peers confirmations
before sending the start message

If client, this timer is used as a max time to wait for host to send the confirmation
but if client never receives host confirmation and this timer times out, we can assume
that the hole is not punched for host, therefore it failed
"""
onready var _host_confirmation_timer: Timer = $HostConfirmationTimer

# Time to wait before actually starting (starting = send hole punched signal)
# Host will wait a fixed amount of time (so it can send some start messages before actually starting)
# Client will wait the time the host sends him to wait
onready var _start_timer: Timer = $StartTimer

var player_addresses: Dictionary
var host_name: String = ""
var _peer: PacketPeerUDP
var self_port: int
var confirm_message: String

# Keys are player names, values are arrays of port numbers
# The idea is that if the array has more than one element, that means that
# peer hasn't confirmed yet its port so we keep trying the whole window
var player_confirmed_ports: Dictionary

var player_confirmed_start: Dictionary

func _ready() -> void:
	yield(owner, "ready")
	_send_confirmation_timer.connect("timeout", self, "_on_send_confirmation_timer_timeout")
	_send_confirmation_timer.wait_time = SECONDS_BETWEEN_CONFIRMS
	
	_host_confirmation_timer.connect("timeout", self, "_on_host_confirmation_timer_timeout")
	_host_confirmation_timer.one_shot = true
	if hole_puncher._is_host:
		_host_confirmation_timer.wait_time = HOST_SECONDS_TO_START
	else:
		_host_confirmation_timer.wait_time = CLIENT_MAX_HOST_WAIT_SECONDS
	
	_start_timer.one_shot = true
	_start_timer.connect("timeout", self, "_on_start_timer_timeout")


func enter(msg: Dictionary = {}) -> void:
	debug("Enter " + self.name + " state")
	player_addresses = msg
	player_confirmed_ports = {}
	player_confirmed_start = {}
	
	for player_name in player_addresses.keys():
		if player_name != hole_puncher._player_name and player_name != "previous_port":
			if player_addresses[player_name]["is_host"]:
				host_name = player_name
			var player_init_port: int = int(player_addresses[player_name]["port"])
			var player_ports_to_try: Array = [player_init_port]
			for port in range(player_init_port - CONFIRMS_CASCADE_PORT_WINDOW, player_init_port + CONFIRMS_CASCADE_PORT_WINDOW + 1):
				if port != player_init_port:
					player_ports_to_try.push_back(port)
			player_confirmed_ports[player_name] = player_ports_to_try
	
	_peer = hole_puncher._peer
	var previous_port: int = int(player_addresses["previous_port"])
	self_port = int(player_addresses[hole_puncher._player_name])
	if previous_port != self_port:
		_peer.close()
		_peer.listen(self_port, "*")
	
	confirm_message = PoolStringArray([CONFIRM_PREFIX, hole_puncher._player_name, str(self_port)]).join(":")
	
	_send_confirmation_timer.start()
	_host_confirmation_timer.start()
	msg.erase("previous_port")
	hole_puncher.emit_signal("holepunch_progress_update", 
								hole_puncher.STATUS_SENDING_CONFIRMATIONS, 
								hole_puncher._session_name,
								msg.keys())


func process(delta: float) -> void:
	if _peer.get_available_packet_count() > 0:
		var packet_string = _peer.get_packet().get_string_from_utf8()
		if packet_string.begins_with(CONFIRM_PREFIX):
			# c:<sender>:<sender_port>
			info("Received confirm message: " + packet_string)
			var split: PoolStringArray = packet_string.split(":")
			var sender: String = split[1]
			var sender_port: int = int(split[2])
			player_confirmed_ports[sender] = [sender_port]
			if not hole_puncher._is_host and sender == host_name:
				info("Received confirmation from host")
				_host_confirmation_timer.stop()
		elif packet_string.begins_with(START_PREFIX) and not hole_puncher._is_host:
			# s:<seconds_to_start>
			info("Received start message: " + packet_string)
			if _start_timer.is_stopped():
				var seconds_to_start: int = int(packet_string.split(":")[1])
				_start_timer.start(seconds_to_start)
		elif packet_string.begins_with(START_CONFIRM_PREFIX) and hole_puncher._is_host:
			# y:<sender>:<sender_port>
			info("Received start confirmation message: " + packet_string)
			var split: PoolStringArray = packet_string.split(":")
			var sender: String = split[1]
			player_confirmed_start[sender] = "ok"
			if player_confirmed_start.keys().size() == player_confirmed_ports.keys().size():
				info("All players confirmed! We can start!")
				_start_timer.stop()
				_on_start_timer_timeout()

func exit() -> void:
	_send_confirmation_timer.stop()
	_host_confirmation_timer.stop()
	_start_timer.stop()


func _on_send_confirmation_timer_timeout():
	for player_name in player_confirmed_ports.keys():
		var message: String = confirm_message
		if player_name == host_name and not _start_timer.is_stopped():
			message = PoolStringArray([START_CONFIRM_PREFIX, hole_puncher._player_name, str(self_port)]).join(":")
		var peer_ip: String = player_addresses[player_name]["ip"]
		var peer_port: int = player_confirmed_ports[player_name][0]
		send_message(message, _peer, peer_ip, peer_port)
		if player_confirmed_ports[player_name].size() > 1:
			var current_port = player_confirmed_ports[player_name].pop_front()
			player_confirmed_ports[player_name].push_back(current_port)


func _on_host_confirmation_timer_timeout():
	if hole_puncher._is_host:
		confirm_message = PoolStringArray([START_PREFIX, str(CLIENT_START_IN_SECONDS)]).join(":")
		_start_timer.start(HOST_START_TIMER_SECONDS)
	else:
		_state_machine.transition_to("None", {ERROR_STR : hole_puncher.ERR_HOST_NOT_CONFIRMED})


func _on_start_timer_timeout():
	if hole_puncher._is_host:
		_state_machine.transition_to("None")
		info("HolePunch successful! Our open port is " + str(self_port))
		hole_puncher.emit_signal("holepunch_success", self_port, null, null)
	else:
		_state_machine.transition_to("None")
		var host_ip: String = player_addresses[host_name]["ip"]
		var host_port: int = int(player_confirmed_ports[host_name][0])
		info("HolePunch successful! Our open port is " + str(self_port) + " and " +
			"the host address is " + host_ip + ":" + str(host_port))
		hole_puncher.emit_signal("holepunch_success", self_port, host_ip, host_port)
