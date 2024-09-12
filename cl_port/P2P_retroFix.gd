extends "res://SteamLobby.gd"
# this does NOT run on versions where P2P_Packet_custom is already available (1.0.4 onwards)

func _read_P2P_Packet():
	var PACKET_SIZE:int = Steam.getAvailableP2PPacketSize(0)

	
	if PACKET_SIZE > 0:
		var PACKET:Dictionary = Steam.readP2PPacket(PACKET_SIZE, 0)

		if PACKET.empty() or PACKET == null:
			print("WARNING: read an empty packet with non-zero size!")

		
		var PACKET_SENDER:int = PACKET["steam_id_remote"]

		
		var PACKET_CODE:PoolByteArray = PACKET["data"]
		var readable:Dictionary = bytes2var(PACKET_CODE)

		



		if readable.has("rpc_data"):
			print("received rpc")
			_receive_rpc(readable)
		if readable.has("challenge_from"):
			_receive_challenge(readable.challenge_from, readable.match_settings)
		if readable.has("challenge_accepted"):
			_on_opponent_challenge_accepted(readable.challenge_accepted)


		if readable.has("match_quit"):
			if Network.:
				emit_signal("quit_on_rematch")
				Steam.setLobbyMemberData(LOBBY_ID, "status", "busy")
			if not is_instance_valid(Global.current_game):
				if PACKET_SENDER == OPPONENT_ID:
					Global.reload()
			Steam.setLobbyMemberData(LOBBY_ID, "opponent_id", "")
			Steam.setLobbyMemberData(LOBBY_ID, "character", "")
			Steam.setLobbyMemberData(LOBBY_ID, "player_id", "")
		if readable.has("match_settings_updated"):
			if SETTINGS_LOCKED:
				NEW_MATCH_SETTINGS = readable.match_settings_updated
			else :
				MATCH_SETTINGS = readable.match_settings_updated
			emit_signal("received_match_settings", readable.match_settings_updated)
		if readable.has("player_busy"):
			
			pass
		if readable.has("request_match_settings"):
			_send_P2P_Packet(readable.request_match_settings, {"match_settings_updated":MATCH_SETTINGS})
		if readable.has("message"):
			if readable.message == "handshake":
				emit_signal("handshake_made")
		
		if readable.has("challenge_cancelled"):
			emit_signal("challenger_cancelled")
			CHALLENGER_STEAM_ID = 0
		if readable.has("challenge_declined"):
			_on_challenge_declined(readable.challenge_declined)
		if readable.has("spectate_accept"):
			_on_spectate_request_accepted(readable)
		if readable.has("spectator_replay_update"):
			_on_received_spectator_replay(readable.spectator_replay_update)
		if readable.has("request_spectate"):
			_on_received_spectate_request(readable.request_spectate)
		if readable.has("spectate_ended"):
			_remove_spectator(readable.spectate_ended)
		if readable.has("spectate_declined"):
			_on_spectate_declined()
		if readable.has("spectator_sync_timers"):
			_on_spectate_sync_timers(readable.spectator_sync_timers)
		if readable.has("spectator_turn_ready"):
			_on_spectate_turn_ready(readable.spectator_turn_ready)
		if readable.has("spectator_tick_update"):
			_on_spectate_tick_update(readable.spectator_tick_update)
		if readable.has("spectator_player_forfeit"):
			Network.player_forfeit(readable.spectator_player_forfeit)
		if readable.has("validate_auth_session"):
			_validate_Auth_Session(readable.validate_auth_session, PACKET_SENDER)

		_read_P2P_Packet_custom(readable)

func _read_P2P_Packet_custom(readable):
	pass
