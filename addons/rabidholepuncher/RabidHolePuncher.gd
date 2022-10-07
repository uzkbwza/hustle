extends Node
class_name HolePuncher, "res://addons/rabidholepuncher/assets/punch.svg"

signal holepunch_progress_update(type, session_name, player_names)
signal holepunch_failure(error)
# Host_ip and host_port are null if you are host
signal holepunch_success(self_port, host_ip, host_port)

export var relay_server_address: String = "127.0.0.1"
export var relay_server_port: int = 57775
export var debug: bool = false

"""
Server error constants
"""
const ERR_REQUEST_INVALID: String = "error:invalid_request"
const ERR_SESSION_EXISTS: String = "error:session_exists"
const ERR_SESSION_NON_EXISTENT: String = "error:session_non_existent"
const ERR_SESSION_PASSWORD_MISMATCH: String = "error:password_mismatch"
const ERR_SESSION_SINGLE_PLAYER: String = "error:only_one_player_in_session"
const ERR_SESSION_FULL: String = "error:session_full"
const ERR_SESSION_PLAYER_NAME_IN_USE: String = "error:player_name_in_use"
const ERR_SESSION_PLAYER_NON_EXISTENT: String = "error:non_existent_player"
const ERR_SESSION_PLAYER_NON_HOST: String = "error:non_host_player"
const ERR_SESSION_PLAYER_KICKED_BY_HOST: String = "error:kicked_by_host"
const ERR_SESSION_PLAYER_EXIT: String = "error:player_exited_session"
const ERR_SESSION_NOT_STARTED: String = "error:session_not_started"
const ERR_SESSION_TIMEOUT: String = "error:session_timeout"
const ERR_PLAYER_TIMEOUT: String = "error:player_timeout"

"""
Client error constants
"""
const ERR_SERVER_TIMEOUT: String = "error:server_timeout"
const ERR_UNREACHABLE_SELF: String = "error:unreachable_self"
const ERR_HOST_NOT_CONFIRMED: String = "error:host_not_confirmed"

"""
HolePunching progress constants
"""
const STATUS_SESSION_CREATED: String = "session_created"
const STATUS_SESSION_UPDATED: String = "session_updated"
const STATUS_STARTING_SESSION: String = "starting_session"
const STATUS_SENDING_GREETINGS: String = "sending_greetings"
const STATUS_SENDING_CONFIRMATIONS: String = "sending_confirmations"

"""
Naming regular expressions
"""
onready var SESSION_NAME_REGEX: RegEx = RegEx.new()
const SESSION_NAME_REGEX_DEFINITION: String = "^([A-Za-z0-9]{1,10})$"
onready var PLAYER_NAME_REGEX: RegEx = RegEx.new()
const PLAYER_NAME_REGEX_DEFINITION: String = "^([A-Za-z0-9]{1,12})$"
onready var SESSION_PASS_REGEX: RegEx = RegEx.new()
const SESSION_PASS_REGEX_DEFINITION: String = "^([A-Za-z0-9]{1,12})$"

onready var _state_machine = $StateMachine
onready var _logger = $Logger
var _session_name: String = "Session"
var _session_pass: String = ""
var _player_name: String = "Player#AA"
var _max_players: int = 4
var _server = PacketPeerUDP.new()
var _peer = PacketPeerUDP.new()
var _is_host: bool = false


func _ready() -> void:
	SESSION_NAME_REGEX.compile(SESSION_NAME_REGEX_DEFINITION)
	PLAYER_NAME_REGEX.compile(PLAYER_NAME_REGEX_DEFINITION)
	SESSION_PASS_REGEX.compile(SESSION_PASS_REGEX_DEFINITION)
	if not debug:
		_logger.queue_free()
		_logger = null


func create_session(session_name: String, player_name: String, 
					max_players: int = 4, session_pass: String = "") -> void:
	_session_manage(true, session_name, player_name, max_players, session_pass)


func join_session(session_name: String, player_name: String, 
					max_players: int = 4, session_pass: String = "") -> void:
	_session_manage(false, session_name, player_name, max_players, session_pass)


func _session_manage(is_host: bool, session_name: String, 
						player_name: String, max_players: int, 
						session_pass: String) -> void:
	if _state_machine.state.name != "None":
		return
	if not SESSION_NAME_REGEX.search(session_name):
		_state_machine.transition_to("None", {"error" : "error:invalid_session_name"})
		return
	if not PLAYER_NAME_REGEX.search(player_name):
		_state_machine.transition_to("None", {"error" : "error:invalid_player_name"})
		return
	if not session_pass.empty() and not SESSION_PASS_REGEX.search(session_pass):
		_state_machine.transition_to("None", {"error" : "error:invalid_session_name"})
		return
	self._is_host = is_host
	self._session_name = session_name
	self._player_name = player_name
	self._session_pass = session_pass
	self._max_players = max_players
	_state_machine.transition_to("InitRequestSent")


func kick_player(player_name: String) -> void:
	if _is_host and _state_machine.state.name == "InSession":
		_state_machine.state.kick_player(player_name)


func start_session() -> void:
	if _is_host and _state_machine.state.name == "InSession":
		_state_machine.state.start_session()


func exit_session() -> void:
	if _is_host and _state_machine.state.name == "InSession":
		_state_machine.state.exit_session()


func is_host() -> bool:
	return _is_host


func get_player_name() -> String:
	return _player_name
