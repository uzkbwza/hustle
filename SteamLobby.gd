extends Node

enum LOBBY_AVAILABILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}
const PACKET_READ_LIMIT: int = 32

signal lobby_match_list_received()
signal lobby_data_update()
signal join_lobby_failed(reason)
signal join_lobby_success()
signal lobby_created()
signal retrieved_lobby_members(members)
signal chat_message_received(user, message)
signal quit_on_rematch()
signal received_match_settings()
signal handshake_made()
signal received_challenge()
signal challenge_declined()
signal challenger_cancelled()
signal received_spectator_match_data(data)

signal user_joined(user_id)
signal user_left(user_id)

var SETTINGS_LOCKED = false
var NEW_MATCH_SETTINGS = null
var MATCH_SETTINGS = {}

var CHALLENGING_STEAM_ID = 0
var CHALLENGER_STEAM_ID = 0
var CHALLENGER_MATCH_SETTINGS = {}

var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 64

var SPECTATORS = []

var OPPONENT_ID: int = 0
var PLAYER_SIDE = 1
var LOBBY_OWNER = 0

var SPECTATOR_MATCH_DATA = null

var SPECTATING = false
var SPECTATING_ID = 0

var LOBBY_NAME = ""

var REMATCHING_ID = 0
var spectator_update_timer


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
	spectator_update_timer = Timer.new()
	spectator_update_timer.connect("timeout", self, "_on_spectator_update_timer_timeout")
	add_child(spectator_update_timer)
	spectator_update_timer.start(3)
	_check_Command_Line()
	

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

	func _init(steam_id: int, steam_name: String):
		self.steam_id = steam_id
		self.steam_name = steam_name
		self.status = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "status")
		self.character = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "character")
		var player_id = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "opponent_id")
		self.player_id = int(player_id) if player_id != "" else 0
		var opponent_id = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "opponent_id")
		self.opponent_id = int(opponent_id) if opponent_id != "" else 0
		var spectating_id = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, steam_id, "spectating_id")
		self.spectating_id = int(spectating_id) if spectating_id != "" else 0

func create_lobby(availability: int):
	if LOBBY_ID == 0:
		Steam.createLobby(availability, LOBBY_MAX_MEMBERS)

func join_lobby(lobby_id: int):
	print("Attempting to join lobby "+str(lobby_id)+"...")

	# Clear any previous lobby members lists, if you were in a previous lobby
	LOBBY_MEMBERS.clear()
	
	# Make the lobby join request to Steam
	Steam.joinLobby(lobby_id)

func challenge_user(user):
	print("challenging user")
	var data = {
		"challenge_from": SteamYomi.STEAM_ID,
		"match_settings": MATCH_SETTINGS
	}
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	_send_P2P_Packet(user.steam_id, data)
	SETTINGS_LOCKED = true
	CHALLENGING_STEAM_ID = user.steam_id

func accept_challenge():
	var steam_id = CHALLENGER_STEAM_ID
	var match_settings = CHALLENGER_MATCH_SETTINGS
	print("accepting challenge")
	OPPONENT_ID = steam_id
	PLAYER_SIDE = 2
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "player_id", "2")
	SETTINGS_LOCKED = true
	MATCH_SETTINGS = match_settings
	_setup_game_vs(steam_id)
	_send_P2P_Packet(steam_id, {
		"challenge_accepted": SteamYomi.STEAM_ID
	})

func decline_challenge():
	var steam_id = CHALLENGER_STEAM_ID
	CHALLENGER_STEAM_ID = 0
	_send_P2P_Packet(steam_id, {"challenge_declined": SteamYomi.STEAM_ID})
	Steam.setLobbyMemberData(LOBBY_ID, "status", "idle")

func quit_match():
	if !SPECTATING:
		if OPPONENT_ID != 0:
			_send_P2P_Packet(OPPONENT_ID, {
				"match_quit": true
			})
		Steam.setLobbyMemberData(LOBBY_ID, "status", "idle")
		Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", "")
		Steam.setLobbyMemberData(LOBBY_ID, "character", "")
		Steam.setLobbyMemberData(LOBBY_ID, "player_id", "")

func leave_Lobby() -> void:
	# If in a lobby, leave it
	if LOBBY_ID != 0:
		print("leaving lobby")
		# Send leave request to Steam
		Steam.leaveLobby(LOBBY_ID)
		REMATCHING_ID = 0
		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		LOBBY_ID = 0

		# Close session with all users
		for MEMBER in LOBBY_MEMBERS:
			# Make sure this isn't your Steam ID
			if MEMBER.steam_id != SteamYomi.STEAM_ID:

				# Close the P2P session
				Steam.closeP2PSessionWithUser(MEMBER.steam_id)

		# Clear the local lobby list
		LOBBY_OWNER = 0
		LOBBY_MEMBERS.clear()
		MATCH_SETTINGS = {}
		SETTINGS_LOCKED = false

func send_chat_message(message: String) -> void:
	# Get the entered chat message
	message = message.strip_edges()
	# If there is even a message
	if message.length() > 0:
		# Pass the message to Steam
		var SENT: bool = Steam.sendLobbyChatMsg(LOBBY_ID, message)
		
		# Was it sent successfully?
		if not SENT:
			print("ERROR: Chat message failed to send.")


func spectate_forfeit(player_id):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_player_forfeit": player_id})

func request_lobby_list():
	if LOBBY_ID == 0:
			# Set distance to worldwide
		Steam.addRequestLobbyListDistanceFilter(3)
#		Steam.addRequestLobbyListResultCountFilter(100)
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

func request_spectate(steam_id):
	_send_P2P_Packet(steam_id, {"request_spectate": SteamYomi.STEAM_ID})

func spectator_sync_timers(id, time):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_sync_timers": {"id": id, "time": time}})

func spectator_turn_ready(id):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_turn_ready": id})

func end_spectate():
	if SPECTATING and SPECTATING_ID != 0:
		_send_P2P_Packet(SPECTATING_ID, {"spectate_ended": SteamYomi.STEAM_ID})
		_stop_spectating()

func update_spectators(replay):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_replay_update": replay})

func update_spectator_tick(tick):
	for spectator in SPECTATORS:
		_send_P2P_Packet(spectator, {"spectator_tick_update": tick})

func cancel_challenge():
	print("cancelling challenge")
	
	_send_P2P_Packet(CHALLENGING_STEAM_ID, {"challenge_cancelled": SteamYomi.STEAM_ID})
	CHALLENGING_STEAM_ID = 0
	Steam.setLobbyMemberData(LOBBY_ID, "status", "idle")

func _receive_challenge(steam_id, match_settings):
	if Steam.getLobbyMemberData(LOBBY_ID, SteamYomi.STEAM_ID, "status") != "idle":
		_send_P2P_Packet(steam_id, {"player_busy": null})
		return
	print("received challenge")
	Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
	CHALLENGER_STEAM_ID = steam_id
	CHALLENGER_MATCH_SETTINGS = match_settings
	emit_signal("received_challenge", CHALLENGER_STEAM_ID)

func _on_challenge_declined(member_id):
	if member_id != CHALLENGING_STEAM_ID:
		return
	Steam.setLobbyMemberData(LOBBY_ID, "status", "idle")
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

func _read_P2P_Packet() -> void:
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)

		if PACKET.empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var PACKET_SENDER: int = PACKET['steam_id_remote']

		# Make the packet data readable
		var PACKET_CODE: PoolByteArray = PACKET['data']
		var READABLE: Dictionary = bytes2var(PACKET_CODE)

		# Print the packet to output
#		print("Packet: "+str(READABLE))
		
		if READABLE.has("rpc_data"):
			print("received rpc")
			_receive_rpc(READABLE)
		if READABLE.has("challenge_from"):
			_receive_challenge(READABLE.challenge_from, READABLE.match_settings)
		if READABLE.has("challenge_accepted"):
			PLAYER_SIDE = 1
			Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "player_id", "1")
			_setup_game_vs(READABLE.challenge_accepted)
		if READABLE.has("match_quit"):
			if Network.rematch_menu:
				emit_signal("quit_on_rematch")
				Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
			Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", "")
			Steam.setLobbyMemberData(LOBBY_ID, "character", "")
			Steam.setLobbyMemberData(LOBBY_ID, "player_id", "")
		if READABLE.has("match_settings_updated"):
			if SETTINGS_LOCKED:
				NEW_MATCH_SETTINGS = READABLE.match_settings_updated
			else:
				MATCH_SETTINGS = READABLE.match_settings_updated
			emit_signal("received_match_settings", READABLE.match_settings_updated)
		if READABLE.has("player_busy"):
			# TODO: show "player is busy" message
			pass
		if READABLE.has("request_match_settings"):
			_send_P2P_Packet(READABLE.request_match_settings, {"match_settings_updated": MATCH_SETTINGS})
		if READABLE.has("message"):
			if READABLE.message == "handshake":
				emit_signal("handshake_made")
		# Append logic here to deal with packet data
		if READABLE.has("challenge_cancelled"):
			emit_signal("challenger_cancelled")
			Steam.setLobbyMemberData(LOBBY_ID, "status", "idle")
		if READABLE.has("challenge_declined"):
			_on_challenge_declined(READABLE.challenge_declined)
		if READABLE.has("spectate_accept"):
			_on_spectate_request_accepted(READABLE)
		if READABLE.has("spectator_replay_update"):
			_on_received_spectator_replay(READABLE.spectator_replay_update)
		if READABLE.has("request_spectate"):
			_on_received_spectate_request(READABLE.request_spectate)
		if READABLE.has("spectate_ended"):
			_remove_spectator(READABLE.spectate_ended)
		if READABLE.has("spectate_declined"):
			_on_spectate_declined()
		if READABLE.has("spectator_sync_timers"):
			_on_spectate_sync_timers(READABLE.spectator_sync_timers)
		if READABLE.has("spectator_turn_ready"):
			_on_spectate_turn_ready(READABLE.spectator_turn_ready)
		if READABLE.has("spectator_tick_update"):
			_on_spectate_tick_update(READABLE.spectator_tick_update)
		if READABLE.has("spectator_player_forfeit"):
			Network.player_forfeit(READABLE.spectator_player_forfeit)

func _on_received_spectate_request(steam_id):
	if Steam.getLobbyMemberData(LOBBY_ID, SteamYomi.STEAM_ID, "status") == "fighting" and is_instance_valid(Network.game):
		_add_spectator(steam_id)
	else:
		_send_P2P_Packet(steam_id, {"spectate_declined": null})

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
	Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "status", "idle")
#	ReplayManager.init()
	SPECTATING = false
	SPECTATING_ID = 0
	SPECTATORS.clear()

func _add_spectator(steam_id):
	SPECTATORS.append(steam_id)
	_send_P2P_Packet(steam_id, {"spectate_accept": SteamYomi.STEAM_ID, "match_data":Network.game.match_data, "replay": ReplayManager.frames })

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
	emit_signal("received_spectator_match_data", data.match_data)

func _on_received_spectator_replay(replay):
	print("here")
	ReplayManager.frames = replay

func _setup_game_vs(steam_id):
	print("registering players")
	REMATCHING_ID = 0
	OPPONENT_ID = steam_id
#	var match_ =
	Network.register_player_steam(steam_id)
	Network.register_player_steam(SteamYomi.STEAM_ID)
	Network.assign_players()
	Steam.setLobbyMemberData(LOBBY_ID, "status", "fighting")
	Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", str(OPPONENT_ID))

func _get_default_lobby_member_data():
	return {
		"status": "idle", # idle, fighting, busy, spectating
		"opponent_id": "",
		"player_id": "",
		"spectating_id": "",
		"character": "",
	}

# A user's information has changed
func _on_Persona_Change(steam_id: int, _flag: int) -> void:
	print("[STEAM] A user ("+str(steam_id)+") had information change, update the lobby list")

	# Update the player list
	_get_Lobby_Members()

func _on_Lobby_Created(connect: int, lobby_id: int):
	if connect == 1:
		# set lobby id
		LOBBY_ID = lobby_id
		print("Created a lobby: " + str(LOBBY_ID))

		Steam.setLobbyJoinable(LOBBY_ID, true)
		Steam.setLobbyData(LOBBY_ID, "name", LOBBY_NAME)
#		Steam.setLobbyData(LOBBY_ID, "status", "Waiting")
		Steam.setLobbyData(LOBBY_ID, "version", Global.VERSION)

	var RELAY: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to relay backup: " + str(RELAY))

func _on_Lobby_Message(lobby_id: int, user: int, message: String, chat_type: int):
	if lobby_id == LOBBY_ID:
		emit_signal("chat_message_received", user, message)
	pass

func request_match_settings():
	_send_P2P_Packet(LOBBY_OWNER, {"request_match_settings": SteamYomi.STEAM_ID})

func _on_Lobby_Joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == 1:
		Network.start_steam_mp()
		# Set this lobby ID as your lobby ID
		LOBBY_ID = lobby_id

		# Get the lobby members
		_get_Lobby_Members()

		# Make the initial handshake
		_make_P2P_Handshake()

		var default_member_data = _get_default_lobby_member_data()
		for key in default_member_data:
			Steam.setLobbyMemberData(LOBBY_ID, key, str(default_member_data[key]))

		LOBBY_OWNER = Steam.getLobbyOwner(LOBBY_ID)
		
		if LOBBY_OWNER != SteamYomi.STEAM_ID:
			_send_P2P_Packet(LOBBY_OWNER, {"request_match_settings": SteamYomi.STEAM_ID})

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

func _get_Lobby_Members() -> void:
	# Clear your previous lobby list
	LOBBY_MEMBERS.clear()

	# Get the number of members from this lobby from Steam
	var MEMBERS: int = Steam.getNumLobbyMembers(LOBBY_ID)
	SPECTATORS.clear()
	# Get the data of these players from Steam
	for member in range(0, MEMBERS):
		# Get the member's Steam ID
		var steam_id: int = Steam.getLobbyMemberByIndex(LOBBY_ID, member)
		if Steam.getLobbyMemberData(LOBBY_ID, steam_id, "status") == "spectating":
			if int(Steam.getLobbyMemberData(LOBBY_ID, steam_id, "spectating_id")) == SteamYomi.STEAM_ID:
				SPECTATORS.append(steam_id)

		# Get the member's Steam name
		var steam_name: String = Steam.getFriendPersonaName(steam_id)

		# Add them to the list
		LOBBY_MEMBERS.append(LobbyMember.new(steam_id, steam_name))
	emit_signal("retrieved_lobby_members", LOBBY_MEMBERS)


func _make_P2P_Handshake() -> void:
	print("Sending P2P handshake to the lobby")
	_send_P2P_Packet(0, {"message":"handshake", "from":SteamYomi.STEAM_ID})

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

func _receive_rpc(data):
	print("received steam rpc")
	var args = data.rpc_data.arg
	if args == null:
		args = []
	elif !args is Array:
		args = [args]
	Network.callv(data.rpc_data.func, args)

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
				if MEMBER.steam_id != SteamYomi.STEAM_ID:
					Steam.sendP2PPacket(MEMBER.steam_id, DATA, SEND_TYPE, CHANNEL)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, DATA, SEND_TYPE, CHANNEL)

func _on_Lobby_Data_Update(steam_id, member_id, success):
	emit_signal("lobby_data_update", steam_id, member_id, success)

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

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")

func can_get_messages_from_user(steam_id):
	if steam_id == SteamYomi.STEAM_ID:
		return true
	var status = Steam.getLobbyMemberData(LOBBY_ID, SteamYomi.STEAM_ID, "status")
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
	return false

func _on_Lobby_Chat_Update(lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == 1:
		print(str(CHANGER)+" has joined the lobby.")
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

func _user_left_lobby(steam_id):
	Network.player_disconnected(steam_id)
	pass

func update_match_settings(match_settings, id=0):
	MATCH_SETTINGS = match_settings
	print("updating settings")
	_send_P2P_Packet(id, {"match_settings_updated": match_settings})
	pass