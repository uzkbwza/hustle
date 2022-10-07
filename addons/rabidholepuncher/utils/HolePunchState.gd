extends Node
class_name HolePunchState, "res://addons/rabidholepuncher/assets/state.svg"
"""
Simplification of Generic State from GDQuest
It includes a couple new methods and variables to simplify children of
this class
Credits to GDQuest for parts of this code
"""

"""
Common constants and variables
"""
# Default timeout to repeat a message sent
const REPEAT_MESSAGE_TIMEOUT_SECONDS: float = 0.5
# Maximum time in milliseconds to wait for relay server response, otherwise fail
const SERVER_TIMEOUT_SECONDS: float = 15.0
const ERROR_STR: String = "error"
const INFO_PREFIX: String = "i"

onready var _state_machine: = _get_state_machine(self)
var hole_puncher: HolePuncher


func _ready() -> void:
	yield(owner, "ready")
	hole_puncher = _state_machine.get_parent() as HolePuncher
	assert(hole_puncher != null)
	hole_puncher


func process(delta: float) -> void:
	return


func enter(msg: Dictionary = {}) -> void:
	return


func exit() -> void:
	return


func _get_state_machine(node: Node) -> Node:
	if node != null and not node.is_in_group("state_machine"):
		return _get_state_machine(node.get_parent())
	return node


func send_message(message: String, packet_peer_udp: PacketPeerUDP,
					destination: String, port: int) -> void:
	var buffer = PoolByteArray()
	buffer.append_array(message.to_utf8())
	packet_peer_udp.set_dest_address(destination, port)
	packet_peer_udp.put_packet(buffer)


func debug(message):
	if hole_puncher._logger != null:
		hole_puncher._logger.debug(message)


func info(message):
	if hole_puncher._logger != null:
		hole_puncher._logger.info(message)


func warning(message):
	if hole_puncher._logger != null:
		hole_puncher._logger.warning(message)


func error(message):
	if hole_puncher._logger != null:
		hole_puncher._logger.error(message)
