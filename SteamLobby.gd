extends Node

enum LOBBY_AVAILABILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}
const PACKET_READ_LIMIT: int = 32

signal lobby_match_list_received()
signal lobby_data_update()
signal join_lobby_failed(reason)
signal join_lobby_success()
signal lobby_created()
signal retrieved_lobby_members(members)
signal chat_message_received(user, message, scope, match_key)
signal quit_on_rematch()
signal received_match_settings()
signal handshake_made()
signal received_challenge()
signal received_replay_challenge(steam_id, replay_data, challenger_side)
signal replay_challenge_declined(reason, detail)
signal replay_mods_loaded_received()
signal challenge_declined()
signal challenger_cancelled()
signal received_spectator_match_data(data)
signal client_validation_success()
signal client_validation_failure(message)
signal authentication_started(steam_id)
signal authentication_complete()
signal spectate_declined()

signal user_joined(user_id)
signal user_left(user_id)

var SETTINGS_LOCKED = false
var NEW_MATCH_SETTINGS = null
var MATCH_SETTINGS = {}

var CHALLENGING_STEAM_ID = 0
var CHALLENGER_STEAM_ID = 0
var CHALLENGER_MATCH_SETTINGS = {}
var REPLAY_FULL_DATA = null
var REPLAY_CHALLENGER_SIDE = 0
var remote_replay_mods_loaded = false
var REQUESTING_TO_SPECTATE = 0
var LOBBY_CHARLOADER_ENABLED = true
var LOBBY_REPLAY_CHALLENGE_ENABLED = true

var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 16
var LOBBY_CODE: String = ""

var SPECTATORS = []

var AUTH_USERS = []

var TICKET: Dictionary
var CLIENT_TICKETS: Dictionary

var OPPONENT_ID: int = 0
var PLAYER_SIDE = 1
var LOBBY_OWNER = 0
# False from the moment we join until Steam has delivered at least one
# lobby_data_update for this lobby — until that arrives, Steam.getLobbyData
# can return "" for keys that are actually set, so callers can't tell
# "settings_locked" from absent vs not-yet-synced. Set true on a freshly
# CREATED lobby (we know its data is empty by construction) so creators
# don't suffer a startup delay. Used by the lobby UI to keep the settings
# panel disabled on rejoin until the lock state is confirmed.
var lobby_data_synced = false
# Local mirror of "settings_locked" lobby data. Monotonic within a single
# lobby: once we ever observe the key as "true", it stays true here even if
# a subsequent _on_Lobby_Data_Update happens to read it as "" (the SDK
# briefly returns empty for unrelated keys during the data-update flurry
# triggered by a new member joining, which used to make is_lobby_settings_
# locked() flicker false and let the owner edit one setting). Cleared on
# lobby boundaries (join / create / leave) so it doesn't leak across lobbies.
var _cached_lock_state = false

var SPECTATOR_MATCH_DATA = null

var SPECTATING = false
var SPECTATING_ID = 0

var LOBBY_NAME = ""

var REMATCHING_ID = 0

var spectator_update_timer
var p2p_packet_sender

func _ready() -> void:
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_match_list", self, "_on_Lobby_Match_List")
	Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	Steam.connect("lobby_message", self, "_on_Lobby_Message")
	Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
	Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")
	Steam.connect("persona_state_change", self, "_on_Persona_Change")
	Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")
	Steam.connect("get_auth_session_ticket_response", self, "_get_Auth_Session_Ticket_Response")
	Steam.connect("validate_auth_ticket_response", self, "_validate_Auth_Ticket_Response")
	Network.connect("game_error", self, "_on_game_error")
	spectator_update_timer = Timer.new()
	spectator_update_timer.connect("timeout", self, "_on_spectator_update_timer_timeout")
	add_child(spectator_update_timer)
	spectator_update_timer.start(3)
	_check_Command_Line()

func _on_game_error(error):
	print(error)
#	quit_match()
#	Global.reload()

func _on_spectator_update_timer_timeout():
	SteamLobby.update_spectators(ReplayManager.frames)
	if SPECTATING:
		if Steam.getLobbyMemberData(LOBBY_ID, SPECTATING_ID, "status") != "fighting":
			end_spectate()
	# Check for command line arguments

class LobbyMember:
	var steam_id: int
	var steam_name: String
	var status: String
	var character: String
	var opponent_id: int
	var player_id: int
	var spectating_id: int
	var client_ticket
	var authenticating = false
	var has_supporter_pack = false
	var game_started = false
	var supporter_pack_result = -1

	func _init(steam_id: int, steam_name: String):
		self.steam_id = steam_id
		self.steam_name = steam_name
		self.status = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "status")
		self.character = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "character")
		var player_id = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "player_id")
		self.player_id = int(player_id) if player_id != "" else 0
		var opponent_id = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "opponent_id")
		self.opponent_id = int(opponent_id) if opponent_id != "" else 0
		var spectating_id = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "spectating_id")
		self.spectating_id = int(spectating_id) if spectating_id != "" else 0
		var game_started = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "game_started")
		self.game_started = true if game_started and game_started == "true" else false

func generate_lobby_code(size: int = 6):
	var code = ""
	var chars = "ABCDEF01234567890"
	randomize()
	for i in range(size):
		code += chars[randi() % len(chars)]
	return code

func get_lobby_member(steam_id):
	for member in LOBBY_MEMBERS:
		if member.steam_id == steam_id:
			return member

func get_player_id(steam_id):
	return Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "player_id")

# Returns the steam_id of whoever's on side `player_id` in the local user's
# current match — local user or opponent for fighters, or the spectated
# pair when spectating. 0 if it can't be resolved.
func steam_id_for_match_side(player_id: int) -> int:
	if LOBBY_ID == 0:
		return 0
	if SPECTATING and SPECTATING_ID != 0:
		var watched_side = get_player_id(SPECTATING_ID)
		if watched_side == str(player_id):
			return SPECTATING_ID
		var opp_str = get_opponent(SPECTATING_ID)
		return int(opp_str) if opp_str != "" else 0
	# Fighter: our player_id matches us, the opposite side is OPPONENT_ID.
	if Network.player_id == player_id:
		return SteamHustle.STEAM_ID
	return OPPONENT_ID

func get_opponent(steam_id):
	return Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "opponent_id")

func create_lobby(availability: int, size: int):
	if Global.winws_check():
		Global.reload()
		return
	
	if LOBBY_ID == 0:
		Steam.createLobby(availability, size)

func connected():
	return LOBBY_ID != 0

func join_lobby(lobby_id: int):
	if Global.winws_check():
		Global.reload()
		return
	
	print("Attempting to join lobby "+str(lobby_id)+"...")

	# Clear any previous lobby members lists, if you were in a previous lobby
	CLIENT_TICKETS.clear()
	LOBBY_MEMBERS.clear()
	
	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)

func challenge_user(user):
	print("challenging user")
	var data = {
		"challenge_from": SteamHustle.STEAM_ID,
		"match_settings": MATCH_SETTINGS
	}
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	_send_P2P_Packet(user.steam_id, data)
	SETTINGS_LOCKED = true
	CHALLENGING_STEAM_ID = user.steam_id
	OPPONENT_ID = user.steam_id
	PLAYER_SIDE = 1

func replay_challenge_user(user, match_data, side):
	print("replay-challenging user as side " + str(side))
	var full_replay = match_data.duplicate(true)
	full_replay["frames"] = ReplayManager.frames
	var data = {
		"replay_challenge_from": SteamHustle.STEAM_ID,
		"replay_data": full_replay,
		"replay_challenger_side": side,
	}
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	_send_P2P_Packet(user.steam_id, data)
	SETTINGS_LOCKED = true
	CHALLENGING_STEAM_ID = user.steam_id
	OPPONENT_ID = user.steam_id
	PLAYER_SIDE = side
	REPLAY_FULL_DATA = full_replay
	REPLAY_CHALLENGER_SIDE = side
	remote_replay_mods_loaded = false

func on_match_started():
	Steam.setLobbyMemberData(LOBBY_ID, "game_started", "true")

func accept_challenge():
#	if CHALLENGER_STEAM_ID == 0:
#		return
	var steam_id = CHALLENGER_STEAM_ID
	var match_settings = CHALLENGER_MATCH_SETTINGS
	print("accepting challenge")
	OPPONENT_ID = steam_id
	PLAYER_SIDE = 2
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "player_id", "2")
	
	SETTINGS_LOCKED = true
	MATCH_SETTINGS = match_settings
#	_setup_game_vs(steam_id)
	_send_P2P_Packet(steam_id, {
		"challenge_accepted": SteamHustle.STEAM_ID
	})
	_setup_game_vs(OPPONENT_ID)

func authenticate_with(steam_id):
	return # TODO: fix this
	if steam_id in AUTH_USERS:
		return 
	TICKET = Steam.getAuthSessionTicket()
	AUTH_USERS.append(steam_id)
	emit_signal("authentication_started", steam_id)
	_send_P2P_Packet(steam_id, {"validate_auth_session": TICKET})

func decline_challenge():
	var steam_id = CHALLENGER_STEAM_ID
	_send_P2P_Packet(steam_id, {"challenge_declined": SteamHustle.STEAM_ID})
	Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())
	CHALLENGER_STEAM_ID = 0

func quit_match():
	if get_status() != "fighting":
		return
	if !SPECTATING and is_fighting():
		if OPPONENT_ID != 0:
			_send_P2P_Packet(OPPONENT_ID, {
				"match_quit": true
			})
		Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())
		Steam.setLobbyMemberData(LOBBY_ID, "character", "")
		Steam.setLobbyMemberData(LOBBY_ID, "game_started", "false")
		if REMATCHING_ID == 0:
			Steam.setLobbyMemberData(LOBBY_ID, "player_id", "")
			Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", "")

func exit_match_from_button():
	if !SPECTATING:
		quit_match()
	Network.stop_multiplayer()
	Global.reload()

func has_supporter_pack(steam_id):
	# TODO: fix this
#	return steam_id in CLIENT_TICKETS and CLIENT_TICKETS[steam_id].authenticated and Steam.userHasLicenseForApp(steam_id, Custom.SUPPORTER_PACK)
	return true

func leave_Lobby() -> void:
	# If in a lobby, leave it
	if LOBBY_ID != 0:
		print("leaving lobby")
		# Send leave request to Steam
		Steam.leaveLobby(LOBBY_ID)
		REMATCHING_ID = 0
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		LOBBY_ID = 0
		# Drop the synced flag so a same-session rejoin can't inherit a stale
		# "lobby data already synced" state from the lobby we just left. Also
		# clear the cached lock so a different lobby doesn't inherit it.
		lobby_data_synced = false
		_cached_lock_state = false
		# Chat history is per-lobby; this is the only point where we actually
		# severed the lobby connection (quit_match / exit_match_from_button do
		# not call this), so clearing here keeps the buffer alive across match
		# in/out toggles but drops it when the user really leaves the lobby.
		clear_chat_history()

		# Close session with all users
		for MEMBER in LOBBY_MEMBERS:
			# Make sure this isn't your Steam ID
			if MEMBER.steam_id != SteamHustle.STEAM_ID:

				# Close the P2P session
				Steam.closeP2PSessionWithUser(MEMBER.steam_id)

		# Clear the local lobby list
		LOBBY_OWNER = 0
		LOBBY_MEMBERS.clear()
		MATCH_SETTINGS = {}
		SETTINGS_LOCKED = false
		# Reset so a rejoin re-emits the member list (the signature would
		# otherwise still match the old lobby and suppress the first rebuild).
		_last_member_signature = ""
	if TICKET:
		Steam.cancelAuthTicket(TICKET['id'])
		TICKET = {}
	for ticket in CLIENT_TICKETS.values():
		Steam.endAuthSession(ticket['id'])
	CLIENT_TICKETS.clear()
	AUTH_USERS.clear()
	OPPONENT_ID = 0

func send_chat_message(message: String, scope: String = "") -> void:
	message = message.strip_edges()
	if message.length() == 0:
		return
	# Always wrap outgoing messages in the versioned JSON envelope so receivers
	# get a uniform shape. Receive side still falls back to raw text if the
	# parse fails (old-patch clients sending unwrapped messages still work).
	var envelope = {"v": 1, "text": message, "scope": scope}
	# Unique per-message id (sender + per-join token + counter). Receivers store
	# it on the history entry and dedup the join/sync merge by id, so a repeated
	# message survives while a true echo collapses — see _history_contains_recent.
	_chat_seq += 1
	envelope["id"] = str(SteamHustle.STEAM_ID) + "-" + _chat_session_token + "-" + str(_chat_seq)
	# For match-scoped sends, stamp our own match_key. The sender always knows
	# its match correctly; the receiver otherwise has to guess the bucket from
	# our lobby "status" member-data, which lags behind over the network — so
	# match chat sent right as a match starts gets misfiled into lobby history
	# (and then broadcast to every joiner). The stamp removes that guess.
	if scope == "match":
		envelope["match_key"] = current_match_key()
	var payload = JSON.print(envelope)
	var SENT: bool = Steam.sendLobbyChatMsg(LOBBY_ID, payload)
	if not SENT:
		print("ERROR: Chat message failed to send.")


func spectate_forfeit(player_id):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_player_forfeit": player_id})

func request_lobby_list(code: String="", version: String="", allow_modded=true, allow_vanilla=true):
	if LOBBY_ID == 0:
			# Set distance to worldwide
		Steam.addRequestLobbyListDistanceFilter(3)
		Steam.addRequestLobbyListResultCountFilter(5000)
		if code != "":
			Steam.addRequestLobbyListStringFilter("code", code.to_upper(), 0)
		
		if version != "":
			Steam.addRequestLobbyListStringFilter("version", version, 0)
		
		if allow_modded != allow_vanilla:
			if allow_modded:
				Steam.addRequestLobbyListStringFilter("charloader", "Yes", 0)
			else:
				Steam.addRequestLobbyListStringFilter("charloader", "No", 0)
		#	Before requesting the lobby list with requestLobbyList you can add more search queries like:
		#	addRequestLobbyListStringFilter - which allows you to look for specific works in the lobby metadata
		#	addRequestLobbyListNumericalFilter - which adds a numerical comparions filter (<=, <, =, >, >=, !=)
		#	addRequestLobbyListNearValueFilter - which gives results closes to the specified value you give

		#	addRequestLobbyListFilterSlotsAvailable - which only returns lobbies with a specified amount of open slots available
		#	addRequestLobbyListResultCountFilter - which sets how many results you want returned
		#	addRequestLobbyListDistanceFilter - which sets the distance to search for lobbies, like:
		#	0 - Close
		#	1 - Default
		#	2 - Far
		#	3 - Worldwide

#		print("Requesting a lobby list")
		Steam.requestLobbyList()

func spectator_sync_timers(id, time):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_sync_timers": {"id": id, "time": time}})

func spectator_turn_ready(id):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_turn_ready": id})

func end_spectate():
	if SPECTATING and SPECTATING_ID != 0:
		_send_P2P_Packet(SPECTATING_ID, {"spectate_ended": SteamHustle.STEAM_ID})
		_stop_spectating()

func update_spectators(replay):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_replay_update": replay})

func update_spectator_tick(tick):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_tick_update": tick})

func cancel_challenge():
	print("cancelling challenge")
	if CHALLENGING_STEAM_ID != 0:
		_send_P2P_Packet(CHALLENGING_STEAM_ID, {"challenge_cancelled": SteamHustle.STEAM_ID})
	CHALLENGING_STEAM_ID = 0
	OPPONENT_ID = 0
	Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())

func _receive_challenge(steam_id, match_settings):
	# Blocked users get the same silent decline as a busy player would —
	# they can't distinguish the reasons, so it's just "not available".
	print("[block] _receive_challenge from ", steam_id, " is_blocked=", is_blocked(steam_id), " block_list=", Global.blocked_users)
	if is_blocked(steam_id):
		_send_P2P_Packet(steam_id, {"challenge_declined": SteamHustle.STEAM_ID})
		return
	if Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status") != "idle":
		_send_P2P_Packet(steam_id, {"player_busy": null})
		return
	print("received challenge")
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	CHALLENGER_STEAM_ID = steam_id
	CHALLENGER_MATCH_SETTINGS = match_settings
	emit_signal("received_challenge", CHALLENGER_STEAM_ID)

func _receive_replay_challenge(steam_id, replay_data, challenger_side):
	if is_blocked(steam_id):
		_send_P2P_Packet(steam_id, {"replay_challenge_declined": SteamHustle.STEAM_ID})
		return
	if Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status") != "idle":
		_send_P2P_Packet(steam_id, {"player_busy": null})
		return
	print("received replay challenge from side " + str(challenger_side))
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	CHALLENGER_STEAM_ID = steam_id
	REPLAY_FULL_DATA = replay_data
	REPLAY_CHALLENGER_SIDE = challenger_side
	remote_replay_mods_loaded = false
	emit_signal("received_replay_challenge", steam_id, replay_data, challenger_side)

func accept_replay_challenge():
	var steam_id = CHALLENGER_STEAM_ID
	var my_side = 2 if REPLAY_CHALLENGER_SIDE == 1 else 1
	print("accepting replay challenge as side " + str(my_side))
	OPPONENT_ID = steam_id
	PLAYER_SIDE = my_side
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "player_id", str(my_side))
	SETTINGS_LOCKED = true
	_send_P2P_Packet(steam_id, {
		"replay_challenge_accepted": SteamHustle.STEAM_ID,
	})
	_setup_replay_game_vs(OPPONENT_ID)

func decline_replay_challenge():
	var steam_id = CHALLENGER_STEAM_ID
	_send_P2P_Packet(steam_id, {"replay_challenge_declined": SteamHustle.STEAM_ID})
	Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())
	CHALLENGER_STEAM_ID = 0
	REPLAY_FULL_DATA = null
	REPLAY_CHALLENGER_SIDE = 0

func signal_replay_mods_loaded():
	if OPPONENT_ID == 0:
		return
	_send_P2P_Packet(OPPONENT_ID, {"replay_mods_loaded": SteamHustle.STEAM_ID})

func decline_replay_challenge_with_reason(reason, detail=null):
	var steam_id = CHALLENGER_STEAM_ID
	_send_P2P_Packet(steam_id, {
		"replay_challenge_declined": SteamHustle.STEAM_ID,
		"replay_decline_reason": reason,
		"replay_decline_detail": detail,
	})
	Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())
	CHALLENGER_STEAM_ID = 0
	REPLAY_FULL_DATA = null
	REPLAY_CHALLENGER_SIDE = 0

func _on_opponent_replay_challenge_accepted(steam_id):
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "player_id", str(PLAYER_SIDE))
	_setup_replay_game_vs(steam_id)

func _setup_replay_game_vs(steam_id):
	print("registering players for replay challenge")
	REMATCHING_ID = 0
	OPPONENT_ID = steam_id
	Network.register_player_steam(steam_id)
	Network.register_player_steam(SteamHustle.STEAM_ID)
	Steam.setLobbyMemberData(LOBBY_ID, "status", "fighting")
	Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", str(OPPONENT_ID))
	Network.assign_players_for_replay_challenge(REPLAY_FULL_DATA)

func _on_challenge_declined(member_id):
	if member_id != CHALLENGING_STEAM_ID:
		return
	Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())
	emit_signal("challenge_declined")
	SETTINGS_LOCKED = false
	CHALLENGING_STEAM_ID = 0

func _on_Lobby_Match_List(lobbies: Array) -> void:
	emit_signal("lobby_match_list_received", lobbies)

func _check_Command_Line() -> void:
	var ARGUMENTS: Array = OS.get_cmdline_args()

	# There are arguments to process
	if ARGUMENTS.size() > 0:

		# A Steam connection argument exists
		if ARGUMENTS[0] == "+connect_lobby":
		
			# Lobby invite exists so try to connect to it
			if int(ARGUMENTS[1]) > 0:

				# At this point, you'll probably want to change scenes
				# Something like a loading into lobby screen
				print("CMD Line Lobby ID: "+str(ARGUMENTS[1]))
				join_lobby(int(ARGUMENTS[1]))

func _process(delta):
	if LOBBY_ID > 0:
		_read_All_P2P_Packets()
		if !SETTINGS_LOCKED and NEW_MATCH_SETTINGS != null:
			MATCH_SETTINGS = NEW_MATCH_SETTINGS
			NEW_MATCH_SETTINGS = null

func _read_All_P2P_Packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		_read_P2P_Packet()
		_read_All_P2P_Packets(read_count + 1)

func _on_opponent_challenge_accepted(steam_id):
	PLAYER_SIDE = 1
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "player_id", "1")
	_setup_game_vs(steam_id)

func _read_P2P_Packet():
	var PACKET_SIZE:int = Steam.getAvailableP2PPacketSize(0)

	
	if PACKET_SIZE > 0:
		var PACKET = Steam.readP2PPacket(PACKET_SIZE, 0)

		if PACKET.empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")

		
		var PACKET_SENDER:int = PACKET["steam_id_remote"]
		p2p_packet_sender = PACKET_SENDER

#		packets.append(PACKET)
		
		
		if !PACKET.has("data"):
			print("ERROR: no packet data!")
			return
			
		var PACKET_CODE = PACKET.get("data")
		
		var readable = bytes2var(PACKET_CODE)
		
		if readable == null:
			print("ERROR: packet data is null!")
			return
		
		if not (readable is Dictionary):
			print("ERROR: packet data is not a dictionary!")
			return

		if readable.empty():
			print("ERROR: no packet data!")
			return

		if readable.has("rpc_data"):
			print("received rpc")
			_receive_rpc(readable)
		if readable.has("rpc_broadcast"):
			_receive_broadcast_rpc(readable)
		if readable.has("challenge_from"):
			_receive_challenge(readable.challenge_from, readable.match_settings)
		if readable.has("challenge_accepted"):
			if PACKET_SENDER == CHALLENGING_STEAM_ID:
				_on_opponent_challenge_accepted(readable.challenge_accepted)
		if readable.has("replay_challenge_from"):
			_receive_replay_challenge(readable.replay_challenge_from, readable.replay_data, readable.replay_challenger_side)
		if readable.has("replay_challenge_accepted"):
			if PACKET_SENDER == CHALLENGING_STEAM_ID:
				_on_opponent_replay_challenge_accepted(readable.replay_challenge_accepted)
		if readable.has("replay_challenge_declined"):
			_on_challenge_declined(readable.replay_challenge_declined)
			emit_signal("replay_challenge_declined", readable.get("replay_decline_reason"), readable.get("replay_decline_detail"))
		if readable.has("replay_mods_loaded"):
			if PACKET_SENDER == OPPONENT_ID:
				remote_replay_mods_loaded = true
				emit_signal("replay_mods_loaded_received")
		if readable.has("match_quit"):
			if PACKET_SENDER == OPPONENT_ID:
				if Network.rematch_menu:
					emit_signal("quit_on_rematch")
					Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
				if not is_instance_valid(Global.current_game):
					Global.reload()
				Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", "")
				Steam.setLobbyMemberData(LOBBY_ID, "character", "")
				Steam.setLobbyMemberData(LOBBY_ID, "player_id", "")
		if readable.has("match_settings_updated"):
			if PACKET_SENDER == LOBBY_OWNER:
				if SETTINGS_LOCKED:
					NEW_MATCH_SETTINGS = readable.match_settings_updated
				else :
					MATCH_SETTINGS = readable.match_settings_updated
				emit_signal("received_match_settings", readable.match_settings_updated)
		if readable.has("player_busy"):
			
			pass
		if readable.has("request_match_settings"):
			_send_P2P_Packet(readable.request_match_settings, {"match_settings_updated":MATCH_SETTINGS})
		if readable.has("request_chat_history"):
			# Only the lobby owner answers — keeps the source of truth clear
			# and avoids every member shipping their (possibly truncated) view.
			if LOBBY_OWNER == SteamHustle.STEAM_ID:
				_send_P2P_Packet(readable.request_chat_history, {"chat_history_response": {
					"lobby": lobby_chat_history,
					"match": match_chat_history,
				}})
		if readable.has("chat_history_response"):
			# Only honor the response if it came from the current lobby owner,
			# and only the FIRST one we're awaiting — retries can land multiple
			# responses, and re-merging would re-append old entries past the
			# dedup window and duplicate them. A late reply (after the spinner
			# timed out) still counts: _awaiting outlives loading.
			if PACKET_SENDER == LOBBY_OWNER and _awaiting_lobby_history:
				var payload = readable.chat_history_response
				if payload is Dictionary:
					# Got a usable response — stop awaiting/retrying now (a
					# malformed one is ignored so retries keep going).
					_awaiting_lobby_history = false
					if payload.get("lobby") is Array:
						# Merge: owner's snapshot is the canonical "before"
						# portion; any live entries we already received during
						# the gap go on the tail. Dedup against the recent
						# window of the snapshot so a message that's in BOTH
						# (owner saw it before snapshotting) doesn't dupe.
						lobby_chat_history = _merge_history(payload.lobby, lobby_chat_history, CHAT_HISTORY_LOBBY_MAX)
					if payload.get("match") is Dictionary:
						# Same merge per match bucket. Local buckets the owner
						# didn't send through are kept (rare — usually owner
						# has everything).
						for key in payload.match:
							var owner_entries = payload.match[key]
							var local_entries = match_chat_history.get(key, [])
							if owner_entries is Array:
								match_chat_history[key] = _merge_history(owner_entries, local_entries, CHAT_HISTORY_MATCH_MAX)
					_set_lobby_history_loading(false)
					emit_signal("chat_history_synced")
		if readable.has("request_match_history"):
			# Only one of the two fighters in the match answers — they're the
			# canonical record holders for it. Spectators don't reply (would
			# echo a partial view).
			var key = readable.get("match_key", "")
			if key != "" and key == current_match_key() \
					and get_status() == "fighting" \
					and match_chat_history.has(key):
				_send_P2P_Packet(readable.request_match_history, {"match_history_response": {
					"match_key": key,
					"entries": match_chat_history[key],
				}})
		if readable.has("match_history_response"):
			# Trust only the host of the match we're currently spectating —
			# anyone else replying is either stale or spoofing. Only the first
			# we're awaiting so retries don't re-merge into duplicates; a late
			# reply still counts (_awaiting outlives the spinner timeout).
			if PACKET_SENDER == SPECTATING_ID and _awaiting_match_history:
				var payload = readable.match_history_response
				if payload is Dictionary and payload.get("entries") is Array:
					var key = str(payload.get("match_key", ""))
					if key != "":
						# Usable response — stop awaiting/retrying (a malformed
						# one is ignored so retries keep going).
						_awaiting_match_history = false
						var local_entries = match_chat_history.get(key, [])
						match_chat_history[key] = _merge_history(payload.entries, local_entries, CHAT_HISTORY_MATCH_MAX)
						_set_match_history_loading(false)
						emit_signal("chat_history_synced")
		if readable.has("message"):
			if readable.message == "handshake":
				emit_signal("handshake_made")
		
		if readable.has("challenge_cancelled"):
			if PACKET_SENDER == CHALLENGER_STEAM_ID:
				emit_signal("challenger_cancelled")
				CHALLENGER_STEAM_ID = 0
		if readable.has("challenge_declined"):
			_on_challenge_declined(readable.challenge_declined)
		if readable.has("spectate_accept"):
			if PACKET_SENDER == REQUESTING_TO_SPECTATE:
				REQUESTING_TO_SPECTATE = 0
				_on_spectate_request_accepted(readable)
		if readable.has("spectator_replay_update"):
			if PACKET_SENDER == SPECTATING_ID:
				_on_received_spectator_replay(readable.spectator_replay_update)
		if readable.has("request_spectate"):
			_on_received_spectate_request(readable.request_spectate)
		if readable.has("spectate_ended"):
			_remove_spectator(readable.spectate_ended)
		if readable.has("spectate_declined"):
			if PACKET_SENDER == REQUESTING_TO_SPECTATE:
				REQUESTING_TO_SPECTATE = 0
				_on_spectate_declined()
		if readable.has("spectator_sync_timers"):
			if PACKET_SENDER == SPECTATING_ID:
				_on_spectate_sync_timers(readable.spectator_sync_timers)
		if readable.has("spectator_turn_ready"):
			if PACKET_SENDER == SPECTATING_ID:
				_on_spectate_turn_ready(readable.spectator_turn_ready)
		if readable.has("spectator_tick_update"):
			if PACKET_SENDER == SPECTATING_ID:
				_on_spectate_tick_update(readable.spectator_tick_update)
		if readable.has("spectator_player_forfeit"):
			if PACKET_SENDER == SPECTATING_ID:
				Network.player_forfeit(readable.spectator_player_forfeit)
		if readable.has("validate_auth_session"):
			_validate_Auth_Session(readable.validate_auth_session, PACKET_SENDER)
		_read_P2P_Packet_custom(readable)




func _read_P2P_Packet_custom(readable):
	var sender = p2p_packet_sender

# --- Lobby user actions popup (shared, lives on the autoload)
# The popup used by LobbyUser avatar clicks was previously parented to each
# LobbyUser, which got destroyed on every lobby member refresh — closing the
# menu mid-interaction. Owning it here keeps it alive across UI churn; the
# popup remembers its target via meta so handlers don't need the LobbyUser
# instance.
var _lobby_user_popup: PopupMenu

const _LOBBY_POPUP_ACTION_PROFILE = 0
const _LOBBY_POPUP_ACTION_MUTE = 1
const _LOBBY_POPUP_ACTION_BLOCK = 2
const _LOBBY_POPUP_ACTION_TRANSFER = 3

signal lobby_user_popup_hidden(steam_id)

func show_lobby_user_popup(global_pos: Vector2, steam_id: int):
	# Parent into Main's UILayer (CanvasLayer) so the popup renders on the
	# same layer as the rest of the lobby UI. Parenting to Main directly puts
	# the popup at canvas_layer 0 — technically visible, just hidden behind
	# every UI element drawn through UILayer. Falls back to the scene root if
	# UILayer can't be found, and to the viewport root if there's no scene.
	var desired_parent: Node = null
	var scene = get_tree().current_scene
	if scene != null and scene.has_node("UILayer"):
		desired_parent = scene.get_node("UILayer")
	if desired_parent == null:
		desired_parent = scene
	if desired_parent == null:
		desired_parent = get_tree().get_root()
	if _lobby_user_popup == null or not is_instance_valid(_lobby_user_popup):
		_lobby_user_popup = PopupMenu.new()
		_lobby_user_popup.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_lobby_user_popup.set_as_toplevel(true)
		# Explicit theme — popups inherit from parents in the Control tree, and
		# Main doesn't carry the lobby theme, so without this the popup's bg
		# panel renders invisible (input still works, you just can't see it).
		_lobby_user_popup.theme = preload("res://theme.tres")
		# Belt-and-suspenders: explicit dark panel stylebox in case the theme
		# doesn't take. The bg_color matches the PopupMenu/styles/panel entry
		# in theme.tres.
		var panel_sb = StyleBoxFlat.new()
		panel_sb.bg_color = Color(0.0784, 0.0784, 0.0784, 1)
		panel_sb.border_width_left = 1
		panel_sb.border_width_top = 1
		panel_sb.border_width_right = 1
		panel_sb.border_width_bottom = 1
		panel_sb.border_color = Color.black
		_lobby_user_popup.add_stylebox_override("panel", panel_sb)
		_lobby_user_popup.connect("id_pressed", self, "_on_lobby_user_popup_id_pressed")
		_lobby_user_popup.connect("popup_hide", self, "_on_lobby_user_popup_hide")
		desired_parent.add_child(_lobby_user_popup)
	elif _lobby_user_popup.get_parent() != desired_parent:
		# Current scene swapped under us (e.g. match transition rebuilt Main).
		# Reparent to the new scene before showing.
		if _lobby_user_popup.get_parent() != null:
			_lobby_user_popup.get_parent().remove_child(_lobby_user_popup)
		desired_parent.add_child(_lobby_user_popup)
	_lobby_user_popup.set_meta("target_steam_id", steam_id)
	_lobby_user_popup.clear()
	_lobby_user_popup.add_item("Open Steam Profile", _LOBBY_POPUP_ACTION_PROFILE)
	if not is_blocked(steam_id):
		_lobby_user_popup.add_item("Unmute" if is_muted(steam_id) else "Mute", _LOBBY_POPUP_ACTION_MUTE)
	_lobby_user_popup.add_item("Unblock" if is_blocked(steam_id) else "Block", _LOBBY_POPUP_ACTION_BLOCK)
	if Steam.getLobbyOwner(LOBBY_ID) == SteamHustle.STEAM_ID:
		_lobby_user_popup.add_separator()
		_lobby_user_popup.add_item("Transfer Ownership", _LOBBY_POPUP_ACTION_TRANSFER)
	_lobby_user_popup.rect_global_position = global_pos
	_lobby_user_popup.popup()

func _on_lobby_user_popup_id_pressed(id: int):
	if _lobby_user_popup == null or not _lobby_user_popup.has_meta("target_steam_id"):
		return
	var steam_id = int(_lobby_user_popup.get_meta("target_steam_id"))
	match id:
		_LOBBY_POPUP_ACTION_PROFILE:
			Steam.activateGameOverlayToUser("steamid", steam_id)
		_LOBBY_POPUP_ACTION_MUTE:
			set_muted(steam_id, not is_muted(steam_id))
		_LOBBY_POPUP_ACTION_BLOCK:
			set_blocked(steam_id, not is_blocked(steam_id))
		_LOBBY_POPUP_ACTION_TRANSFER:
			Steam.setLobbyOwner(LOBBY_ID, steam_id)

func _on_lobby_user_popup_hide():
	if _lobby_user_popup == null or not _lobby_user_popup.has_meta("target_steam_id"):
		return
	emit_signal("lobby_user_popup_hidden", int(_lobby_user_popup.get_meta("target_steam_id")))

func is_lobby_user_popup_open_for(steam_id: int) -> bool:
	if _lobby_user_popup == null or not is_instance_valid(_lobby_user_popup):
		return false
	if not _lobby_user_popup.visible:
		return false
	if not _lobby_user_popup.has_meta("target_steam_id"):
		return false
	return int(_lobby_user_popup.get_meta("target_steam_id")) == steam_id

func set_status(status):
	# Callers everywhere use set_status("idle") to mean "we're done with the
	# challenge/match flow." Honor the manual busy toggle here so those paths
	# don't silently clobber the user's preference.
	if status == "idle" and Global.lobby_busy_mode:
		status = "busy"
	Steam.setLobbyMemberData(LOBBY_ID, "status", status)

# Callback from getting the auth ticket from Steam
func _get_Auth_Session_Ticket_Response(auth_ticket: int, result: int) -> void:
	print("Auth session result: "+str(result))
	print("Auth session ticket handle: "+str(auth_ticket))

# Callback from attempting to validate the auth ticket
func _validate_Auth_Ticket_Response(authID: int, response: int, ownerID: int) -> void:
#	if authID in CLIENT_TICKETS:
#		print("Client ticket response already received, moving on...")
#		return
	print("Ticket Owner: "+str(authID))

	# Make the response more verbose, highly unnecessary but good for this example
	var VERBOSE_RESPONSE: String
	match response:
		0: VERBOSE_RESPONSE = "Steam has verified the user is online, the ticket is valid and ticket has not been reused."
		1: VERBOSE_RESPONSE = "The user in question is not connected to Steam."
		2: VERBOSE_RESPONSE = "The user doesn't have a license for this App ID or the ticket has expired."
		3: VERBOSE_RESPONSE = "The user is VAC banned for this game."
		4: VERBOSE_RESPONSE = "The user account has logged in elsewhere and the session containing the game instance has been disconnected."
		5: VERBOSE_RESPONSE = "VAC has been unable to perform anti-cheat checks on this user."
		6: VERBOSE_RESPONSE = "The ticket has been canceled by the issuer."
		7: VERBOSE_RESPONSE = "This ticket has already been used, it is not valid."
		8: VERBOSE_RESPONSE = "This ticket is not from a user instance currently connected to steam."
		9: VERBOSE_RESPONSE = "The user is banned for this game. The ban came via the web api and not VAC."
	print("Auth response: "+str(VERBOSE_RESPONSE))
	print("Game owner ID: "+str(ownerID))
	
	if response == 0:
		emit_signal("client_validation_success")
		CLIENT_TICKETS[authID].authenticated = true
	else:
		emit_signal("client_validation_failure", VERBOSE_RESPONSE)
		if CLIENT_TICKETS.has(authID):
			if !CLIENT_TICKETS[authID].authenticated:
				CLIENT_TICKETS.erase(authID)

func _validate_Auth_Session(ticket: Dictionary, steam_id: int) -> void:
#	if steam_id in CLIENT_TICKETS:
#		print("Client ticket already authorized, moving on...")
#		return
	var RESPONSE: int = Steam.beginAuthSession(ticket['buffer'], ticket['size'], steam_id)

	# Get a verbose response; unnecessary but useful in this example
	var VERBOSE_RESPONSE: String
	match RESPONSE:
		0: VERBOSE_RESPONSE = "Ticket is valid for this game and this Steam ID."
		1: VERBOSE_RESPONSE = "The ticket is invalid."
		2: VERBOSE_RESPONSE = "A ticket has already been submitted for this Steam ID."
		3: VERBOSE_RESPONSE = "Ticket is from an incompatible interface version."
		4: VERBOSE_RESPONSE = "Ticket is not for this game."
		5: VERBOSE_RESPONSE = "Ticket has expired."
	print("Auth verifcation response: "+str(VERBOSE_RESPONSE))

	if RESPONSE == 0:
		print("Validation successful, adding user to CLIENT_TICKETS")
		CLIENT_TICKETS[steam_id] = {"id": steam_id, "ticket": ticket['id'], "authenticated": false}
	else:
		emit_signal("client_validation_failure", VERBOSE_RESPONSE)
		if steam_id == OPPONENT_ID and OPPONENT_ID != 0: 
			quit_match()
			if is_instance_valid(Global.current_game):
				Global.reload()

func _on_received_spectate_request(steam_id):
	if is_blocked(steam_id):
		_send_P2P_Packet(steam_id, {"spectate_declined": null})
		return
	if Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status") == "fighting" and is_instance_valid(Network.game):
		_add_spectator(steam_id)
	else:
		_send_P2P_Packet(steam_id, {"spectate_declined": null})

func is_fighting():
	return Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status") == "fighting"

func _on_spectate_tick_update(tick):
	if SPECTATING:
		if is_instance_valid(Global.current_game):
			Global.current_game.spectate_tick = tick

func _on_spectate_declined():
	emit_signal("spectate_declined")
	_stop_spectating()

func _on_spectate_turn_ready(id):
	Network.emit_signal("player_turn_ready", id)

func _on_spectate_sync_timers(data):
	Network.emit_signal("sync_timer_request", data.id, data.time)

func _stop_spectating():
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "spectating_id", "")
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "status", _idle_status())
#	ReplayManager.init()
	SPECTATING = false
	SPECTATING_ID = 0
	SPECTATORS.clear()

func _add_spectator(steam_id):
	# Spectate requests resend on an interval (see UiSteamLobbyOld), so a
	# request can arrive again after we've already accepted — e.g. when our
	# first spectate_accept got dropped. Re-send the accept so they recover,
	# but don't append a duplicate or we'd send every update twice.
	if not (steam_id in SPECTATORS):
		SPECTATORS.append(steam_id)
	_send_P2P_Packet(steam_id, {"spectate_accept": SteamHustle.STEAM_ID, "match_data":Network.game.match_data, "replay": ReplayManager.frames })

func _remove_spectator(steam_id):
	SPECTATORS.erase(steam_id)

func _on_spectate_request_accepted(data):
	ReplayManager.init()
	data.match_data.replay = data.replay
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "status", "spectating")
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "spectating_id", str(data.spectate_accept))
	SPECTATORS.clear()
	SPECTATING = true
	SPECTATING_ID = data.spectate_accept
	SPECTATOR_MATCH_DATA = data.match_data
	ReplayManager.frames = data.replay
	# Pull the match host's chat backlog so we see the conversation that
	# happened in the match before we started spectating. Mirrors the
	# lobby-join → request_chat_history flow.
	request_match_history(SPECTATING_ID, current_match_key())
	emit_signal("received_spectator_match_data", data.match_data)

func _on_received_spectator_replay(replay):
	ReplayManager.frames = replay

func _setup_game_vs(steam_id):
#	if is_instance_valid(Global.current_game):
#		return
	print("registering players")
	REMATCHING_ID = 0
	OPPONENT_ID = steam_id
	Network.register_player_steam(steam_id)
	Network.register_player_steam(SteamHustle.STEAM_ID)
	Network.assign_players()
	Steam.setLobbyMemberData(LOBBY_ID, "status", "fighting")
	Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", str(OPPONENT_ID))

func _get_default_lobby_member_data():
	return {
		"status": _idle_status(), # idle, fighting, busy, spectating
		"opponent_id": "",
		"player_id": "",
		"spectating_id": "",
		"character": "",
		"game_started": "false",
		# Local user's Personalization name-color tint, broadcast so other
		# clients can render this user's name with the same color in their
		# chat, lobby list, and healthbar. Empty string when the user hasn't
		# customized (display sites fall back to default).
		"name_color": Global.get_name_color().to_html(false) if Global.has_name_color() else "",
	}

# A user's information has changed
func _on_Persona_Change(steam_id: int, _flag: int) -> void:
	if LOBBY_ID == 0:
		return
	print("[STEAM] A user ("+str(steam_id)+") had information change, updating the lobby member list")

	# Update the player list
	
	_get_Lobby_Members()

func get_lobby_code():
	return Steam.getLobbyData(LOBBY_ID, "code")

func _on_Lobby_Created(connect: int, lobby_id: int):
	if connect == 1:
		# set lobby id
		LOBBY_ID = lobby_id
		# Freshly created — its lobby data is empty by definition, so we
		# already "know" it's not locked. Skip the join-rejoin sync wait.
		lobby_data_synced = true
		_cached_lock_state = false
		var lobby_code = generate_lobby_code()
		
		print("Created a lobby: " + str(LOBBY_ID))

		Steam.setLobbyJoinable(LOBBY_ID, true)
		Steam.setLobbyData(LOBBY_ID, "name", ProfanityFilter.filter(LOBBY_NAME))
		Steam.setLobbyData(LOBBY_ID, "charloader", "Yes" if LOBBY_CHARLOADER_ENABLED else "No")
		Steam.setLobbyData(LOBBY_ID, "replay_challenge", "Yes" if LOBBY_REPLAY_CHALLENGE_ENABLED else "No")
		Steam.setLobbyData(LOBBY_ID, "code", lobby_code)
		print("lobby code: " + lobby_code)
#		Steam.setLobbyData(LOBBY_ID, "status", "Waiting")
		var lobby_version = Global.VERSION
		if !Network.is_modded() and !LOBBY_CHARLOADER_ENABLED:
			lobby_version = Global.VERSION.split(" Modded")[0]
		
		Steam.setLobbyData(LOBBY_ID, "version", lobby_version)

	var RELAY: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to relay backup: " + str(RELAY))

func _on_Lobby_Message(lobby_id: int, user: int, message: String, chat_type: int):
	if lobby_id != LOBBY_ID:
		return
	# Try to unwrap the versioned JSON envelope; raw text (old-patch clients
	# or new clients without a scope override) falls through with scope="".
	var text = message
	var scope = ""
	var match_key = ""
	var id = ""
	var parsed = JSON.parse(message)
	if parsed.error == OK and parsed.result is Dictionary and parsed.result.get("v") == 1:
		text = str(parsed.result.get("text", ""))
		scope = str(parsed.result.get("scope", ""))
		match_key = str(parsed.result.get("match_key", ""))
		id = str(parsed.result.get("id", ""))
	# Record into the shared history exactly once, here at the source. The Chat
	# UI used to do this, but Chat.tscn is instanced twice (in-game + lobby),
	# so each message was recorded by both views and the history doubled.
	_record_incoming_chat(user, text, scope, match_key, id)
	emit_signal("chat_message_received", user, text, scope, match_key)

# Resolve the storage bucket for an incoming chat message and append it once.
# Silenced users (mute/block) are dropped from the record entirely; self-echoes
# always go through. Mirrors the display-side categorization in Chat.gd.
func _record_incoming_chat(steam_id: int, message: String, scope: String, match_key: String, id: String = "") -> void:
	if steam_id != SteamHustle.STEAM_ID and is_silenced(steam_id):
		return
	var storage_scope = "lobby"
	var storage_match_key = ""
	if scope == "lobby":
		storage_scope = "lobby"
	elif scope == "match":
		storage_scope = "match"
		# Prefer the sender's stamped key (authoritative, lag-free); fall back
		# to deriving from live status only for old clients that omit it.
		if match_key != "":
			storage_match_key = match_key
		else:
			storage_match_key = match_key_for_user(steam_id) if steam_id != SteamHustle.STEAM_ID else current_match_key()
	elif steam_id == SteamHustle.STEAM_ID:
		var my_status = get_status()
		if my_status == "fighting" or my_status == "spectating":
			storage_scope = "match"
			storage_match_key = current_match_key()
	else:
		var sender_status = Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status")
		if sender_status == "fighting" or sender_status == "spectating":
			storage_scope = "match"
			storage_match_key = match_key_for_user(steam_id)
	record_chat_message(steam_id, message, storage_scope, storage_match_key, id)

func request_match_settings():
	# Fast-path: owner publishes settings to lobby data on every change
	# (see update_match_settings), so joiners can read directly instead
	# of waiting on a P2P round-trip. call_deferred so the UI's yield on
	# `received_match_settings` has time to register before we emit.
	var json_str = Steam.getLobbyData(LOBBY_ID, "match_settings_json")
	if json_str != "":
		var parsed = JSON.parse(json_str)
		if parsed.error == OK and parsed.result is Dictionary:
			MATCH_SETTINGS = parsed.result
			call_deferred("emit_signal", "received_match_settings", MATCH_SETTINGS)
			return
	_send_P2P_Packet(LOBBY_OWNER, {"request_match_settings": SteamHustle.STEAM_ID})
	
func am_i_lobby_owner() -> bool:
	return LOBBY_OWNER == SteamHustle.STEAM_ID

# Persistent, lobby-wide "settings frozen" toggle: once any owner flips it on,
# no one — including future owners after a transfer — can edit the lobby's
# match settings until the lobby is disposed. Stored as lobby data (not member
# data) so it survives ownership transfer; setLobbyData fires lobby_data_update
# on every member so each client refreshes their settings panel automatically.
# Separate from the per-client transient SETTINGS_LOCKED flag, which freezes a
# challenger's own settings mid-match-negotiation.
func is_lobby_settings_locked() -> bool:
	if LOBBY_ID == 0:
		return false
	# Source-of-truth check first, then promote a "true" reading into the
	# monotonic cache so transient empty reads (member-join data churn) can't
	# unlock the panel. Cache is only refreshed from a fresh _on_Lobby_Data_
	# Update; reading it directly here covers cases where the lock was just
	# set this frame and the data update hasn't bubbled through yet.
	if Steam.getLobbyData(LOBBY_ID, "settings_locked") == "true":
		_cached_lock_state = true
	return _cached_lock_state

func lock_lobby_settings():
	if LOBBY_ID == 0 or !am_i_lobby_owner():
		return
	Steam.setLobbyData(LOBBY_ID, "settings_locked", "true")

func _on_Lobby_Joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == 1:
		# Reset to idle on every lobby join — busy mode is a transient
		# preference for the current session, not something we persist.
		Global.lobby_busy_mode = false
		Network.start_steam_mp()
		# Set this lobby ID as your lobby ID
		LOBBY_ID = lobby_id
		# Joining an existing lobby — Steam hasn't pushed the data yet, so any
		# getLobbyData read here would be misleadingly empty. Flips to true on
		# the first _on_Lobby_Data_Update.
		lobby_data_synced = false
		_cached_lock_state = false
		# Fresh per-join token so chat-message ids stay unique across sessions
		# and rejoins — a recycled counter can't collide with a still-in-window
		# id from a previous session and trip the merge dedup.
		_chat_session_token = str(OS.get_unix_time()) + "-" + str(randi())
		_chat_seq = 0
		LOBBY_CHARLOADER_ENABLED = Steam.getLobbyData(LOBBY_ID, "charloader") == "Yes"
		var rce = Steam.getLobbyData(LOBBY_ID, "replay_challenge")
		LOBBY_REPLAY_CHALLENGE_ENABLED = rce != "No"

		# Get the lobby members
		_get_Lobby_Members()
#
#		for member in LOBBY_MEMBERS:
#			authenticate_with(member.steam_id)

		# Make the initial handshake
		_make_P2P_Handshake()

		var default_member_data = _get_default_lobby_member_data()
		for key in default_member_data:
			Steam.setLobbyMemberData(LOBBY_ID, key, str(default_member_data[key]))
		Global.publish_name_color()

		LOBBY_OWNER = Steam.getLobbyOwner(LOBBY_ID)
		
		if LOBBY_OWNER != SteamHustle.STEAM_ID:
			request_match_settings()
			# Pull the owner's chat record so we see messages from before we
			# joined. Owner holds the canonical history (and broadcasts it to
			# new joiners) — same pattern as request_match_settings.
			request_chat_history()

		emit_signal("join_lobby_success")

	# Else it failed for some reason
	else:
		# Get the failure reason
		var FAIL_REASON: String
	
		match response:
			2:	FAIL_REASON = "This lobby no longer exists."
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = "The lobby is now full."
			5:	FAIL_REASON = "Uh... something unexpected happened!"
			6:	FAIL_REASON = "You are banned from this lobby."
			7:	FAIL_REASON = "You cannot join due to having a limited account."
			8:	FAIL_REASON = "This lobby is locked or disabled."
			9:	FAIL_REASON = "This lobby is community locked."
			10:	FAIL_REASON = "A user in the lobby has blocked you from joining."
			11:	FAIL_REASON = "A user you have blocked is in the lobby."

		emit_signal("join_lobby_failed", FAIL_REASON)

# If the player is already in-game and accepts a Steam invite or clicks on a friend in their friend 
# list then selects 'Join Game' from there, it will trigger the join_requested callback. 
# This function will handle that:
func _on_Lobby_Join_Requested(lobby_id: int, friendID: int) -> void:
	# Get the lobby owner's name
	var OWNER_NAME: String = Steam.getFriendPersonaName(friendID)

	print("Joining "+str(OWNER_NAME)+"'s lobby...")

	# Attempt to join the lobby
	join_lobby(lobby_id)

# Set of member-data keys whose change should trigger a UI rebuild. Notably
# excludes hp_pct (published every few seconds during matches) — that fires
# lobby_data_update constantly but isn't shown in the member/player lists, so
# it must not force a full rebuild.
const _MEMBER_SIGNATURE_KEYS = ["status", "character", "opponent_id", "player_id", "spectating_id", "game_started", "name_color"]
var _last_member_signature = ""
var _member_refresh_emit_queued = false

func _get_Lobby_Members() -> void:
	if LOBBY_ID == 0:
		return
	# Clear your previous lobby list
	LOBBY_MEMBERS.clear()
	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(LOBBY_ID)
	SPECTATORS.clear()
	# Build a signature of everything the member/player lists actually
	# display, so we can skip the (expensive) rebuild when an incoming
	# lobby_data_update didn't change any of it — see emit gate below.
	var signature = PoolStringArray()
	# Get the data of these players from Steam
	for member in range(0, MEMBERS):
		# Get the member's Steam ID
		var steam_id: int = Steam.getLobbyMemberByIndex(LOBBY_ID, member)
		if Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status") == "spectating":
			if int(Steam.getLobbyMemberData(LOBBY_ID, steam_id, "spectating_id")) == SteamHustle.STEAM_ID:
				SPECTATORS.append(steam_id)

		# Get the member's Steam name
		var steam_name: String = Steam.getFriendPersonaName(steam_id)

		# Add them to the list
		LOBBY_MEMBERS.append(LobbyMember.new(steam_id, steam_name))

		signature.append(str(steam_id))
		signature.append(steam_name)
		for key in _MEMBER_SIGNATURE_KEYS:
			signature.append(Steam.getLobbyMemberData(LOBBY_ID, steam_id, key))

	# LOBBY_MEMBERS is always rebuilt (cheap, and callers may read it
	# synchronously). But only fire the rebuild signal when the displayed
	# data changed, and coalesce a burst (e.g. a join writes ~7 member-data
	# keys back-to-back) into a single deferred emit so the lobby/chat UI
	# rebuilds at most once per idle frame instead of once per write.
	var sig = signature.join("|")
	if sig == _last_member_signature:
		return
	_last_member_signature = sig
	if _member_refresh_emit_queued:
		return
	_member_refresh_emit_queued = true
	call_deferred("_emit_retrieved_lobby_members")

func _emit_retrieved_lobby_members() -> void:
	_member_refresh_emit_queued = false
	emit_signal("retrieved_lobby_members", LOBBY_MEMBERS)


func _make_P2P_Handshake() -> void:
	print("Sending P2P handshake to the lobby")
	_send_P2P_Packet(0, {"message":"handshake", "from":SteamHustle.STEAM_ID})

func _on_P2P_Session_Request(remote_id: int) -> void:
	# Get the requester's name
	var REQUESTER: String = Steam.getFriendPersonaName(remote_id)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	_make_P2P_Handshake()

func rpc_(function_name, arg):
	if OPPONENT_ID != 0:
		var data = {
			"rpc_data": {
				"func": function_name,
				"arg": arg
			}
		}
		print("sending rpc through steam...")
		_send_P2P_Packet(OPPONENT_ID, data)

# Lobby-broadcast variant of rpc_ — sends the call to every lobby member,
# not just OPPONENT_ID. Spectators can use this path (rpc_ would silently
# stay put because OPPONENT_ID is 0 and the receive side gates on sender).
# Receivers must filter by their own role (e.g. Network.player_id +
# !SPECTATING) since the packet reaches everyone.
func broadcast_rpc(function_name, arg):
	if LOBBY_ID == 0:
		return
	var data = {
		"rpc_broadcast": {
			"func": function_name,
			"arg": arg,
		}
	}
	_send_P2P_Packet(0, data)


func _send_P2P_Packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var SEND_TYPE: int = Steam.P2P_SEND_RELIABLE
	var CHANNEL: int = 0

	# Create a data array to send the data through
	var DATA: PoolByteArray
	DATA.append_array(var2bytes(packet_data))

	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in LOBBY_MEMBERS:
				if MEMBER.steam_id != SteamHustle.STEAM_ID:
					Steam.sendP2PPacket(MEMBER.steam_id, DATA, SEND_TYPE, CHANNEL)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)

func _on_Lobby_Data_Update(success, lobby_id, member_id):
	# Ownership transfers come through as lobby data updates; refresh the
	# cached owner so request/response gates (`PACKET_SENDER == LOBBY_OWNER`)
	# track the new owner instead of staying stuck on the original one.
	if LOBBY_ID != 0:
		var live_owner = Steam.getLobbyOwner(LOBBY_ID)
		if live_owner != 0 and live_owner != LOBBY_OWNER:
			LOBBY_OWNER = live_owner
	# First data update after a join confirms Steam has delivered the lobby's
	# data — getLobbyData("settings_locked") is now meaningful. Refresh the
	# monotonic lock cache here too; reading inside is_lobby_settings_locked
	# also promotes on a "true" read, but doing it here ensures every
	# downstream lobby_data_update consumer sees the freshest value before
	# they ask.
	lobby_data_synced = true
	if LOBBY_ID != 0 and Steam.getLobbyData(LOBBY_ID, "settings_locked") == "true":
		_cached_lock_state = true
	emit_signal("lobby_data_update", success, lobby_id, member_id)

func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with "+str(steamID)+" [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with "+str(steamID)+" [target user not running the same game].")

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with "+str(steamID)+" [local user doesn't own app / game].")

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with "+str(steamID)+" [target user isn't connected to Steam].")

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with "+str(steamID)+" [connection timed out].")

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with "+str(steamID)+" [unused].")

	# Mid-match disconnect: notify Network so the game can unstick / show "opponent disconnected"
	if is_fighting() and steamID == OPPONENT_ID and session_error in [3, 4]:
		Network.player_disconnected(steamID)

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")
#	Global.reload()

func get_status():
	return Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status")

# Status to write whenever code wants to flip the user back to "available
# for whatever's next" — respects the manual Do-Not-Disturb toggle in
# Global.lobby_busy_mode so the user stays unchallengable across match
# ends, challenge declines, etc.
func _idle_status() -> String:
	return "busy" if Global.lobby_busy_mode else "idle"

# Apply Global.lobby_busy_mode to the current Steam status. Only flips when
# we're not actively in a fighting / spectating state — those are owned by
# the match flow and shouldn't be overridden.
func apply_busy_mode():
	if LOBBY_ID == 0:
		return
	# Skip when the match flow actually owns our status — but check the local
	# booleans, not get_status(). Steam's cache lags behind setLobbyMemberData,
	# so reading "fighting" / "spectating" from the cache after the match has
	# ended would silently swallow the toggle.
	if OPPONENT_ID != 0 or SPECTATING:
		return
	Steam.setLobbyMemberData(LOBBY_ID, "status", _idle_status())

# --- Chat history (persists across Global.reload, cleared on full lobby leave)
# Stored on the SteamLobby autoload because Main.tscn (and the Chat node) get
# torn down when a player exits a match. Lobby chat lives in one bucket;
# match chats are bucketed by a stable match_key so a spectator who first
# joins a match later can replay everything that happened in it.
const CHAT_HISTORY_LOBBY_MAX = 1000
const CHAT_HISTORY_MATCH_MAX = 300
var lobby_chat_history := []
var match_chat_history := {}
# Per-message id state. The merge dedup (see _history_contains_recent) keys on
# these ids instead of message content, so a legitimately repeated message
# keeps both entries while a true echo (same message in the owner's snapshot
# and our live tail) collapses. _chat_session_token is refreshed on each lobby
# join so a recycled counter from a previous session can't collide.
var _chat_seq := 0
var _chat_session_token := ""

# Stable key for the match between two steam_ids, regardless of order.
func match_key_for(a: int, b: int) -> String:
	if a == 0 or b == 0:
		return ""
	if a < b:
		return str(a) + "_" + str(b)
	return str(b) + "_" + str(a)

# Match the LOCAL user is currently in (fighting or spectating). "" if idle.
func current_match_key() -> String:
	if LOBBY_ID == 0:
		return ""
	var status = get_status()
	if status == "fighting":
		return match_key_for(SteamHustle.STEAM_ID, OPPONENT_ID)
	if status == "spectating":
		var spec_opp_str = Steam.getLobbyMemberData(LOBBY_ID, SPECTATING_ID, "opponent_id")
		var spec_opp = int(spec_opp_str) if spec_opp_str != "" else 0
		return match_key_for(SPECTATING_ID, spec_opp)
	return ""

# Match key the given user is currently in. "" for idle/busy or unknown.
func match_key_for_user(steam_id: int) -> String:
	if LOBBY_ID == 0:
		return ""
	var status = Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status")
	if status == "fighting":
		var opp_str = Steam.getLobbyMemberData(LOBBY_ID, steam_id, "opponent_id")
		var opp = int(opp_str) if opp_str != "" else 0
		return match_key_for(steam_id, opp)
	if status == "spectating":
		var spec_str = Steam.getLobbyMemberData(LOBBY_ID, steam_id, "spectating_id")
		var spec_id = int(spec_str) if spec_str != "" else 0
		if spec_id == 0:
			return ""
		var spec_opp_str = Steam.getLobbyMemberData(LOBBY_ID, spec_id, "opponent_id")
		var spec_opp = int(spec_opp_str) if spec_opp_str != "" else 0
		return match_key_for(spec_id, spec_opp)
	return ""

# Append a chat entry. `scope` is "lobby" or "match"; for "match", `match_key`
# names the bucket. Each bucket has its own ring-cap so a long-running lobby
# can't grow memory unbounded.
func record_chat_message(steam_id: int, message: String, scope: String, match_key: String = "", id: String = ""):
	var entry = {"steam_id": steam_id, "message": message, "id": id}
	if scope == "match":
		if match_key == "":
			return
		if !match_chat_history.has(match_key):
			match_chat_history[match_key] = []
		var arr = match_chat_history[match_key]
		arr.append(entry)
		while arr.size() > CHAT_HISTORY_MATCH_MAX:
			arr.pop_front()
	else:
		lobby_chat_history.append(entry)
		while lobby_chat_history.size() > CHAT_HISTORY_LOBBY_MAX:
			lobby_chat_history.pop_front()

func clear_chat_history():
	lobby_chat_history.clear()
	match_chat_history.clear()

# Emitted when a freshly-joined user has received history from the owner —
# Chat.gd reacts by rebuilding all containers from the (now-populated) record.
signal chat_history_synced
# Track whether we're waiting on a history reply so Chat.gd can show a
# "loading messages..." indicator at the top of the relevant container until
# the response arrives (or the timeout below clears the flag).
signal chat_history_loading_changed
var loading_lobby_chat_history := false
var loading_match_chat_history := false
# Bumped on each (re)request so a previous request's retry loop / timeout can
# tell it's been superseded and bow out — otherwise an old request's stale 8s
# timeout could clear the loading flag mid-way through a fresh request (rapid
# match-exit → rejoin), which also makes the response gate reject the new
# history. Each request only acts while it's still the current generation.
var _lobby_history_gen := 0
var _match_history_gen := 0
# Dedup gate for applying a response, kept SEPARATE from the loading spinner:
# we merge the first response we get for a request and ignore the rest (the
# merge isn't idempotent), but a response is still honored even if it arrives
# after the spinner's timeout — late history beats no history.
var _awaiting_lobby_history := false
var _awaiting_match_history := false
const CHAT_HISTORY_LOADING_TIMEOUT := 8.0

func is_chat_history_loading() -> bool:
	return loading_lobby_chat_history or loading_match_chat_history

func _set_lobby_history_loading(on: bool):
	if loading_lobby_chat_history == on:
		return
	loading_lobby_chat_history = on
	emit_signal("chat_history_loading_changed")

func _set_match_history_loading(on: bool):
	if loading_match_chat_history == on:
		return
	loading_match_chat_history = on
	emit_signal("chat_history_loading_changed")

# Fallback so the spinner doesn't get stuck forever if the owner / host never
# replies (e.g. they're on an old patch without the handler, or they left).
func _clear_chat_loading_after_timeout(which: String, gen: int):
	yield(get_tree().create_timer(CHAT_HISTORY_LOADING_TIMEOUT), "timeout")
	# Only the latest request's timeout may clear the spinner.
	if which == "lobby" and gen == _lobby_history_gen:
		_set_lobby_history_loading(false)
	elif which == "match" and gen == _match_history_gen:
		_set_match_history_loading(false)

# Retried because the one-shot request was fragile: getLobbyOwner can still be
# 0 right after joining (lobby data not synced), which made the request no-op
# and left history permanently incomplete; a dropped request/response had the
# same effect. We re-resolve the owner and resend a few times until a response
# clears the loading flag (or the timeout gives up).
const CHAT_HISTORY_RETRY_INTERVAL := 0.4
const CHAT_HISTORY_MAX_REQUESTS := 6

# Ask the lobby owner for their stored history so newly-joined users see
# what was said before they arrived. Owner replies with their lobby record
# plus all match buckets they're holding.
func request_chat_history():
	if LOBBY_ID == 0:
		return
	_lobby_history_gen += 1
	_awaiting_lobby_history = true
	_set_lobby_history_loading(true)
	_request_chat_history_loop(_lobby_history_gen, 0)
	_clear_chat_loading_after_timeout("lobby", _lobby_history_gen)

func _request_chat_history_loop(gen: int, attempt: int):
	# Stop if superseded by a newer request, a response already merged, or we
	# left the lobby. (Tied to _awaiting, not the spinner — the spinner can
	# time out while we keep waiting for a late reply.)
	if gen != _lobby_history_gen or not _awaiting_lobby_history or LOBBY_ID == 0:
		return
	var owner = Steam.getLobbyOwner(LOBBY_ID)
	if owner != 0:
		LOBBY_OWNER = owner
	if LOBBY_OWNER == SteamHustle.STEAM_ID:
		_awaiting_lobby_history = false
		_set_lobby_history_loading(false)
		return
	if LOBBY_OWNER != 0:
		_send_P2P_Packet(LOBBY_OWNER, {"request_chat_history": SteamHustle.STEAM_ID})
	if attempt + 1 < CHAT_HISTORY_MAX_REQUESTS:
		yield(get_tree().create_timer(CHAT_HISTORY_RETRY_INTERVAL), "timeout")
		_request_chat_history_loop(gen, attempt + 1)

# Spectator-side mirror — ask the match host (the user we're spectating)
# for the in-progress match's chat backlog.
func request_match_history(host_id: int, match_key: String):
	if host_id == 0 or host_id == SteamHustle.STEAM_ID or match_key == "":
		return
	_match_history_gen += 1
	_awaiting_match_history = true
	_set_match_history_loading(true)
	_request_match_history_loop(_match_history_gen, host_id, match_key, 0)
	_clear_chat_loading_after_timeout("match", _match_history_gen)

func _request_match_history_loop(gen: int, host_id: int, match_key: String, attempt: int):
	# Stop if superseded, a response already merged, or we left the lobby.
	# The host's reply is also gated on its own status/match_key settling, so
	# retrying covers the case where those hadn't synced on the first ask.
	if gen != _match_history_gen or not _awaiting_match_history or LOBBY_ID == 0:
		return
	_send_P2P_Packet(host_id, {"request_match_history": SteamHustle.STEAM_ID, "match_key": match_key})
	if attempt + 1 < CHAT_HISTORY_MAX_REQUESTS:
		yield(get_tree().create_timer(CHAT_HISTORY_RETRY_INTERVAL), "timeout")
		_request_match_history_loop(gen, host_id, match_key, attempt + 1)

# Dedup helper for the merge step. Two entries collide when they share a stamped
# message id — authoritative, so a legitimately repeated message (distinct ids)
# is never collapsed. Entries from old clients that predate ids fall back to a
# (steam_id, message) content match, limited to the last `window` entries so the
# fallback can't wrongly collapse a real repeat from earlier in the session.
func _history_contains_recent(history: Array, entry, window: int = 50) -> bool:
	var start = int(max(0, history.size() - window))
	var entry_id = entry.get("id", "")
	for i in range(start, history.size()):
		var h = history[i]
		var h_id = h.get("id", "")
		if entry_id != "" and h_id != "":
			# Both stamped: identity is authoritative. A repeated message carries
			# a distinct id and survives; only a true echo (same id in the
			# snapshot and our live tail) collapses.
			if h_id == entry_id:
				return true
		elif h.steam_id == entry.steam_id and h.message == entry.message:
			# Old-client fallback (entry pre-dates ids): best-effort content match.
			return true
	return false

# Merge `incoming` (owner's snapshot — older entries) with `local` (live
# messages we received between request and response — newer entries),
# preserving any local entries the owner hadn't seen yet. Caps the result.
func _merge_history(incoming: Array, local: Array, cap: int) -> Array:
	var merged = incoming.duplicate()
	for entry in local:
		if not _history_contains_recent(merged, entry, 50):
			merged.append(entry)
	while merged.size() > cap:
		merged.pop_front()
	return merged

# --- Chat mute / block
# Mute is transient (this session only); blocks are persisted in
# Global.blocked_users. Both drop the user's messages from display and
# from the chat history store.
signal user_block_state_changed(steam_id)

var muted_users := {}  # steam_id -> true; transient

func is_muted(steam_id: int) -> bool:
	return muted_users.has(steam_id)

func set_muted(steam_id: int, on: bool):
	if on:
		muted_users[steam_id] = true
	else:
		muted_users.erase(steam_id)
	emit_signal("user_block_state_changed", steam_id)

func is_blocked(steam_id: int) -> bool:
	# Compare against str(entry) so a stored int or string both register —
	# JSON round-trips, hand-edits, or older saves could leave the list in
	# either shape, and a quiet false here lets a blocked user slip through
	# every gate (challenge / replay-challenge / spectate request).
	if not (Global.blocked_users is Array):
		return false
	var as_str = str(steam_id)
	for entry in Global.blocked_users:
		if str(entry) == as_str:
			return true
	return false

func set_blocked(steam_id: int, on: bool):
	var key = str(steam_id)
	print("[block] set_blocked steam_id=", steam_id, " key=", key, " on=", on, " before=", Global.blocked_users)
	if on:
		if not is_blocked(steam_id):
			Global.blocked_users.append(key)
		# Block is a superset of mute — drop the redundant mute entry so the
		# UI doesn't have to reason about "blocked AND muted" as a separate
		# state, and so unblocking later doesn't leave them silently muted.
		muted_users.erase(steam_id)
	else:
		# Erase any entry that stringifies to the same id, regardless of how
		# it was stored (str vs int) — paired with the loose is_blocked check.
		var i = 0
		while i < Global.blocked_users.size():
			if str(Global.blocked_users[i]) == key:
				Global.blocked_users.remove(i)
			else:
				i += 1
	Global.save_options()
	print("[block] set_blocked after=", Global.blocked_users)
	emit_signal("user_block_state_changed", steam_id)

# True if any silencing (mute or block) is active for this user.
func is_silenced(steam_id: int) -> bool:
	return is_muted(steam_id) or is_blocked(steam_id)

func can_get_messages_from_user(steam_id):
	if steam_id == SteamHustle.STEAM_ID:
		return true
	var status = Steam.getLobbyMemberData(LOBBY_ID, SteamHustle.STEAM_ID, "status")
	if status == "idle" or status == "busy":
		var other_status = Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status")
		return other_status == "idle" or other_status == "busy"
	if status == "fighting":
		if steam_id == OPPONENT_ID or steam_id in SPECTATORS:
			return true
		if Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status") == "spectating":
			if int(Steam.getLobbyMemberData(LOBBY_ID, steam_id, "spectating_id")) == OPPONENT_ID:
				return true
	if status == "spectating":
		if steam_id == SPECTATING_ID:
			return true
		if steam_id == int(Steam.getLobbyMemberData(LOBBY_ID, SPECTATING_ID, "opponent_id")):
			return true
		if Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status") == "spectating":
			if int(Steam.getLobbyMemberData(LOBBY_ID, steam_id, "spectating_id")) == SPECTATING_ID:
				return true
			if int(Steam.getLobbyMemberData(LOBBY_ID, steam_id, "spectating_id")) == int(Steam.getLobbyMemberData(LOBBY_ID, SPECTATING_ID, "opponent_id")):
				return true
	return false



func _on_Lobby_Chat_Update(lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == 1:
		print(str(CHANGER)+" has joined the lobby.")
		# Only the owner is authoritative for match settings, so only the
		# owner should push them to the new joiner. Previously every member
		# ran this, blasting the joiner with N redundant P2P packets (and
		# each non-owner's possibly-stale MATCH_SETTINGS racing the owner's).
		if am_i_lobby_owner():
			update_match_settings(MATCH_SETTINGS, change_id)
		if can_get_messages_from_user(change_id):
			emit_signal("user_joined", CHANGER)
	
	# Else if a player has left the lobby
	elif chat_state == 2:
		print(str(CHANGER)+" has left the lobby.")
		_user_left_lobby(change_id)
		if can_get_messages_from_user(change_id):
			emit_signal("user_left", CHANGER)

	# Else if a player has been kicked
	elif chat_state == 8:
		print(str(CHANGER)+" has been kicked from the lobby.")
		_user_left_lobby(change_id)

	# Else if a player has been banned
	elif chat_state == 16:
		print(str(CHANGER)+" has been banned from the lobby.")
		_user_left_lobby(change_id)

	# Else there was some unknown change
	else:
		print(str(CHANGER)+" did... something.")

	# Update the lobby now that a change has occurred
	_get_Lobby_Members()

func _user_joined_lobby(user_id):
	authenticate_with(user_id)

func _user_left_lobby(steam_id):
	CLIENT_TICKETS.erase(steam_id)
	AUTH_USERS.erase(steam_id)
	Steam.endAuthSession(steam_id)
	Network.player_disconnected(steam_id)
	pass

var _last_published_match_settings_json := ""

func update_match_settings(match_settings, id=0):
	# Once the lobby is locked nobody — current or future owner — may publish
	# settings to it. Catches both UI changes and the rejoin auto-publish in
	# UiSteamLobbyOld.init() that used to clobber the lock for one tick when
	# the rejoining owner's stale local MATCH_SETTINGS got written through.
	# Also refuses while the join's lobby data isn't synced yet: a not-yet-
	# arrived "settings_locked" reads as empty, so a stale write could land
	# before we know the lobby's actually locked.
	if is_lobby_settings_locked() or not lobby_data_synced:
		return
	MATCH_SETTINGS = match_settings
	print("updating settings")
	if am_i_lobby_owner():
		# Dedup writes — _on_lobby_data_update refires update_lobby_data
		# on every lobby_data_update event, and our own setLobbyData
		# triggers one, so without this guard we get a tight write loop
		# that hammers the lobby and clobbers transient state like
		# busy/idle button presses.
		var serialized = JSON.print(match_settings)
		if serialized != _last_published_match_settings_json:
			_last_published_match_settings_json = serialized
			Steam.setLobbyData(LOBBY_ID, "match_settings_json", serialized)
	_send_P2P_Packet(id, {"match_settings_updated": match_settings})
	pass

func _receive_rpc(data):
	print("received steam rpc")
	if OPPONENT_ID != p2p_packet_sender:
		return
	var args = data.rpc_data.arg
	if args == null:
		args = []
	elif not args is Array:
		args = [args]
	var func_ = data.rpc_data.func
	if Network.check_valid_rpc(func_):
		Network.callv(func_, args)

# Lobby-broadcast variant — accepts packets from any lobby member (not
# just OPPONENT_ID). Used for things like style permission requests where
# the sender may be a spectator and the target may be either fighter.
func _receive_broadcast_rpc(data):
	print("received steam broadcast rpc")
	var args = data.rpc_broadcast.arg
	if args == null:
		args = []
	elif not args is Array:
		args = [args]
	var func_ = data.rpc_broadcast.func
	if Network.check_valid_rpc(func_):
		Network.callv(func_, args)

func request_spectate(steam_id):
	REQUESTING_TO_SPECTATE = steam_id
	_send_P2P_Packet(steam_id, {"request_spectate":SteamHustle.STEAM_ID})

func cancel_spectate_request():
	# Tell the target to drop us in case they raced an accept (auto-accept +
	# request resends mean they may have already added us as a spectator);
	# it's a no-op for them otherwise. _remove_spectator erases by id.
	if REQUESTING_TO_SPECTATE != 0:
		_send_P2P_Packet(REQUESTING_TO_SPECTATE, {"spectate_ended": SteamHustle.STEAM_ID})
	REQUESTING_TO_SPECTATE = 0
