""" InSession """
extends HolePunchState

const START_PREFIX: String = "s"
const PING_PREFIX: String = "p"
const KICK_PREFIX: String = "k"
const CONFIRM_PREFIX: String = "y"
const EXIT_PREFIX: String = "x"

var _server: PacketPeerUDP
var _init_message: String
var _players: PoolStringArray
var _ping_message: String
onready var _ping_timer: Timer = $PingTimer
onready var _server_timer: Timer = $ServerTimer


func _ready() -> void:
	yield(owner, "ready")
	_ping_timer.wait_time = REPEAT_MESSAGE_TIMEOUT_SECONDS
	_ping_timer.connect("timeout", self, "_on_ping_timer_timeout")
	_server_timer.wait_time = SERVER_TIMEOUT_SECONDS
	_server_timer.connect("timeout", self, "_on_server_timer_timeout")


func enter(msg: Dictionary = {}) -> void:
	debug("Enter " + self.name + " state")
	_server = hole_puncher._server
	_players = PoolStringArray(msg["players"])
	_ping_message = PoolStringArray([PING_PREFIX, hole_puncher._session_name, 
										hole_puncher._player_name]).join(":")
	_ping_timer.start()
	_server_timer.start()


func process(delta: float) -> void:
	if _server.get_available_packet_count() > 0:
		_server_timer.start() # Restart server timeout timer because we received a message
		var packet_string = _server.get_packet().get_string_from_utf8()
		if packet_string.begins_with(ERROR_STR):
			if packet_string == hole_puncher.ERR_SESSION_PLAYER_NON_HOST:
				# You receive this message if you are not the host and try to do host stuff
				# You should not be doing that kind of things, but just in case i reset here the ping message
				# to continue sending regular pings
				warning("Received non-host error message, tried to do host stuff as non host?")
				_ping_message = PoolStringArray([PING_PREFIX, 
													hole_puncher._session_name, 
													hole_puncher._player_name]).join(":")
			elif packet_string == hole_puncher.ERR_SESSION_SINGLE_PLAYER:
				# Stop sending start message because session cannot start as it only has one player
				warning("Received single player error message, tried to start a 1 player session?")
				_ping_message = PoolStringArray([PING_PREFIX, hole_puncher._session_name, 
												hole_puncher._player_name]).join(":")
			else:
				_state_machine.transition_to("None", {ERROR_STR : packet_string})
		elif packet_string.begins_with(INFO_PREFIX):
			# i:<playername1>:<playername2>:....:<playernameN>
			debug("Received session update message " + packet_string)
			var player_names: PoolStringArray = packet_string.split(":", true, 1)[1].split(":")
			if player_names != _players:
				info("Change in session players: " + str(player_names))
				_players = player_names
				hole_puncher.emit_signal("holepunch_progress_update", 
											hole_puncher.STATUS_SESSION_UPDATED,
											"session_name", _players)
				if not hole_puncher._is_host and hole_puncher._player_name == _players[0]:
					info("Host died, so now you are host")
					hole_puncher._is_host = true # Host died, so you are now the new host
		elif packet_string.begins_with(START_PREFIX):
			# s:<ownport>:<otherplayername>:<otherplayerip>:<otherplayerport>;...
			info("Received start session message " + packet_string)
			var addresses_split = packet_string.split(":", true, 2)
			var own_port: int = int(addresses_split[1])
			var others_addresses = addresses_split[2]
			var all_addresses: Dictionary = {hole_puncher._player_name : own_port}
			var first_address: bool = true
			for player_address_string in others_addresses.split(";"):
				var player_data: Array = player_address_string.split(":")
				var is_host: bool = false
				if not hole_puncher._is_host and first_address:
					first_address = false
					# First address in init session message is always host for
					# non host players
					is_host = true
				all_addresses[player_data[0]] = {"ip" : player_data[1],
												"port" : int(player_data[2]),
												"is_host" : is_host}
			_state_machine.transition_to("ServerFinishWait", all_addresses)


func kick_player(player_name: String) -> void:
	info("Called kick player function for player " + player_name)
	if player_name in _players:
		var kick_message = PoolStringArray([KICK_PREFIX, 
											hole_puncher._session_name, 
											player_name]).join(":")
		send_message(kick_message, _server, hole_puncher.relay_server_address, 
					hole_puncher.relay_server_port)


func start_session() -> void:
	info("Called start session function")
	var start_message = PoolStringArray([START_PREFIX, hole_puncher._session_name, 
											hole_puncher._player_name]).join(":")
	send_message(start_message, _server, hole_puncher.relay_server_address, 
					hole_puncher.relay_server_port)
	# Change ping message to start message so we repeat the start message if
	# it gets lost
	_ping_message = start_message


func exit_session() -> void:
	info("Called exit session function")
	var close_message = PoolStringArray([EXIT_PREFIX, hole_puncher._session_name, 
											hole_puncher._player_name]).join(":")
	send_message(close_message, _server, hole_puncher.relay_server_address, 
					hole_puncher.relay_server_port)
	# Change ping message to exit message so we repeat the exit message if
	# it gets lost
	_ping_message = close_message


func exit() -> void:
	_ping_timer.stop()
	_server_timer.stop()
	hole_puncher._server.close()


func _on_ping_timer_timeout() -> void:
	send_message(_ping_message, _server, hole_puncher.relay_server_address, 
					hole_puncher.relay_server_port)


func _on_server_timer_timeout() -> void:
	warning("Server timed out")
	_state_machine.transition_to("None", {ERROR_STR : hole_puncher.ERR_SERVER_TIMEOUT})
