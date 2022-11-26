extends Node

enum LOBBY_AVAILABILITY {PRIVATE, FRIENDS, PUBLIC, INVISIBLE}
const PACKET_READ_LIMIT: int = 32

signal lobby_match_list_received()
signal lobby_data_update()
signal join_lobby_failed(reason)
signal join_lobby_success()
signal lobby_created()
signal retrieved_lobby_members(members)

var LOBBY_ID: int = 0
var LOBBY_MEMBERS: Array = []
var DATA
var LOBBY_VOTE_KICK: bool = false
var LOBBY_MAX_MEMBERS: int = 64

var OPPONENT_ID: int = 0
var PLAYER_SIDE = 1

var LOBBY_NAME = ""

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
	
	# Check for command line arguments
	_check_Command_Line()

class LobbyMember:
	var steam_id: int
	var steam_name: String
	func _init(steam_id: int, steam_name: String):
		self.steam_id = steam_id
		self.steam_name = steam_name

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
	PLAYER_SIDE = 1
	var data = {
		"challenge_from": SteamYomi.STEAM_ID,
	}
	_send_P2P_Packet(user.steam_id, data)

func accept_challenge(steam_id):
	print("accepting challenge")
	OPPONENT_ID = steam_id
	PLAYER_SIDE = 2
	_setup_game_vs(steam_id)
	_send_P2P_Packet(steam_id, {
		"challenge_accepted": SteamYomi.STEAM_ID
	})

func leave_Lobby() -> void:
	# If in a lobby, leave it
	if LOBBY_ID != 0:
		# Send leave request to Steam
		Steam.leaveLobby(LOBBY_ID)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		LOBBY_ID = 0

		# Close session with all users
		for MEMBER in LOBBY_MEMBERS:
			# Make sure this isn't your Steam ID
			if MEMBER.steam_id != SteamYomi.STEAM_ID:

				# Close the P2P session
				Steam.closeP2PSessionWithUser(MEMBER.steam_id)

		# Clear the local lobby list
		LOBBY_MEMBERS.clear()

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

func request_lobby_list():
#	if LOBBY_ID == 0:
			# Set distance to worldwide
		Steam.addRequestLobbyListDistanceFilter(3)

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
		print("Packet: "+str(READABLE))
		
		if READABLE.has("rpc_data"):
			print("received rpc")
			_receive_rpc(READABLE)
		elif READABLE.has("challenge_from"):
			_receive_challenge(READABLE.challenge_from)
		elif READABLE.has("challenge_accepted"):
			_setup_game_vs(READABLE.challenge_accepted)
		# Append logic here to deal with packet data

func _receive_challenge(steam_id):
	print("received challenge")
	accept_challenge(steam_id)

func _setup_game_vs(steam_id):
	print("registering players")
	OPPONENT_ID = steam_id
	Network.register_player_steam(steam_id)
	Network.register_player_steam(SteamYomi.STEAM_ID)
	Network.assign_players()

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
		Steam.setLobbyData(LOBBY_ID, "status", "Waiting")

	var RELAY: bool = Steam.allowP2PPacketRelay(true)
	print("Allowing Steam to relay backup: " + str(RELAY))

func _on_Lobby_Joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	Network.start_steam_mp()
	# If joining was successful
	if response == 1:
		# Set this lobby ID as your lobby ID
		LOBBY_ID = lobby_id

		# Get the lobby members
		_get_Lobby_Members()

		# Make the initial handshake
		_make_P2P_Handshake()
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

	# Get the data of these players from Steam
	for member in range(0, MEMBERS):
		# Get the member's Steam ID
		var steam_id: int = Steam.getLobbyMemberByIndex(LOBBY_ID, member)

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
				"function_name": function_name,
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
	Network.callv(data.rpc_data.function_name, args)

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

func _on_Lobby_Chat_Update(lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var CHANGER: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == 1:
		print(str(CHANGER)+" has joined the lobby.")

	# Else if a player has left the lobby
	elif chat_state == 2:
		print(str(CHANGER)+" has left the lobby.")

	# Else if a player has been kicked
	elif chat_state == 8:
		print(str(CHANGER)+" has been kicked from the lobby.")

	# Else if a player has been banned
	elif chat_state == 16:
		print(str(CHANGER)+" has been banned from the lobby.")

	# Else there was some unknown change
	else:
		print(str(CHANGER)+" did... something.")

	# Update the lobby now that a change has occurred
	_get_Lobby_Members()
