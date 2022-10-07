""" InitRequestSend """
extends HolePunchState

const HOST_PREFIX: String = "h"
const CONNECT_PREFIX: String = "c"

onready var _message_timer: Timer = $MessageTimer
onready var _server_timer: Timer = $ServerTimer

var _server: PacketPeerUDP
var _init_message: String


func _ready() -> void:
	yield(owner, "ready")
	_message_timer.wait_time = REPEAT_MESSAGE_TIMEOUT_SECONDS
	_message_timer.connect("timeout", self, "_on_message_timer_timeout")
	_server_timer.wait_time = SERVER_TIMEOUT_SECONDS
	_server_timer.connect("timeout", self, "_on_server_timer_timeout")

func enter(msg: Dictionary = {}) -> void:
	debug("Enter " + self.name + " state")
	_server = hole_puncher._server
	_server.close()
	_init_message = _build_init_message()
	hole_puncher.relay_server_address = IP.resolve_hostname(hole_puncher.relay_server_address)
	send_message(_init_message, _server, hole_puncher.relay_server_address, 
					hole_puncher.relay_server_port)
	_message_timer.start()
	_server_timer.start()
	


func process(delta: float) -> void:
	if _server.get_available_packet_count() > 0:
		var packet_string = _server.get_packet().get_string_from_utf8()
		if packet_string.begins_with(ERROR_STR):
			_state_machine.transition_to("None", {ERROR_STR : packet_string})
		elif packet_string.begins_with(INFO_PREFIX):
			# i:<playername1>:<playername2>:....:<playernameN>
			info("Received session info message, progressing to InSession state. " +
				"Message received: " + packet_string)
			var player_names = packet_string.split(":", true, 1)[1].split(":")
			hole_puncher.emit_signal("holepunch_progress_update",
										hole_puncher.STATUS_SESSION_CREATED,
										"session_name", player_names)
			_state_machine.transition_to("InSession", {"players" : player_names})


func exit() -> void:
	_message_timer.stop()
	_server_timer.stop()


func _on_message_timer_timeout() -> void:
	# No answer from relay server or our packet was lost, send again
	send_message(_init_message, _server, hole_puncher.relay_server_address, 
					hole_puncher.relay_server_port)


func _on_server_timer_timeout() -> void:
	_state_machine.transition_to("None", {ERROR_STR : hole_puncher.ERR_SERVER_TIMEOUT})


func _build_init_message() -> String:
	var message_array: Array = [hole_puncher._session_name, hole_puncher._player_name]
	if hole_puncher._is_host:
		message_array.push_front(HOST_PREFIX)
		message_array.push_back(str(hole_puncher._max_players))
	else:
		message_array.push_front(CONNECT_PREFIX)
	
	if hole_puncher._session_pass != null and not hole_puncher._session_pass.empty():
		message_array.push_back(hole_puncher._session_pass)
		
	return PoolStringArray(message_array).join(":")
