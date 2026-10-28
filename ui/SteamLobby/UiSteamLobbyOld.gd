extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var user_list = $"%UserList"

var users = []
var matches = {}
var selected_user = null
var pending_replay_challenge_member = null
var pending_replay_match_data = null
var pending_replay_path = ""
var incoming_is_replay_challenge = false

var handshake_made = false

# Called when the node enters the scene tree for the first time.
func _ready():
	SteamLobby.connect("lobby_data_update", self, "_on_lobby_data_update")
	SteamLobby.connect("received_challenge", self, "_on_received_challenge")
	SteamLobby.connect("received_replay_challenge", self, "_on_received_replay_challenge")
	SteamLobby.connect("replay_challenge_declined", self, "_on_replay_challenge_declined_with_reason")
	SteamLobby.connect("retrieved_lobby_members", self, "_on_retrieved_lobby_members", [], CONNECT_DEFERRED)
	SteamLobby.connect("challenge_declined", self, "_on_challenge_declined")
	SteamLobby.connect("challenger_cancelled", self, "_on_challenger_cancelled")
	SteamLobby.connect("spectate_declined", self, "_on_spectate_declined")
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	if UIManager.is_connected("swiped_back", self, "_on_back_button_pressed"):
		UIManager.disconnect("swiped_back", self, "_on_back_button_pressed")
	UIManager.connect("swiped_back", self, "_on_back_button_pressed")
	$"%StartButton".connect("pressed", self, "_on_start_button_pressed")
	$"%LockSettingsButton".connect("pressed", self, "_on_LockSettingsButton_pressed")
	$"%LockConfirmButton".connect("pressed", self, "_on_LockConfirmButton_pressed")
	$"%LockCancelButton".connect("pressed", self, "_on_LockCancelButton_pressed")
	$"%ChallengeCancelButton".connect("pressed", self, "_on_challenge_cancelled")
	$"%ChallengeAcceptButton".connect("pressed", self, "_on_challenge_accept_pressed")
	$"%ChallengeDeclineButton".connect("pressed", self, "_on_challenge_decline_pressed")
	$"%SidePickerP1Button".connect("pressed", self, "_on_side_picker_p1_pressed")
	$"%SidePickerP2Button".connect("pressed", self, "_on_side_picker_p2_pressed")
	$"%SidePickerCancelButton".connect("pressed", self, "_on_side_picker_cancel_pressed")
	$"%SpectateCancelButton".connect("pressed", self, "_on_spectate_cancel_pressed")
#	user_list.connect("item_selected", self, "_on_user_selected")
	$"%GameSettingsPanelContainer".init(false)
	# SteamLobby.tscn ships with placeholder LobbyMatch/LobbyUser nodes
	# as design-time dummies. Without removing them here, any code that
	# iterates MatchList/UserList children before the first rebuild (e.g.
	# the cl_port `_process` hitting `game.p1.character`) NPEs on the
	# uninit'd dummies. Previously the rebuild on this line did it for
	# us — but now the rebuild gates on is_visible_in_tree (false at
	# _ready time), so we clean up explicitly first.
	for child in $"%UserList".get_children():
		child.free()
	for child in $"%MatchList".get_children():
		child.free()
	_on_retrieved_lobby_members(SteamLobby.LOBBY_MEMBERS)
	yield(get_tree(), "idle_frame")
	handshake_made = false

func _on_lobby_data_update(success, lobby_id, member_id):
	_refresh_settings_panel_state()
	SteamLobby._get_Lobby_Members()

var _was_owner = false

func _refresh_settings_panel_state():
	# Settings panel + lock button visibility recompute on every lobby data
	# update so ownership transfer and the persistent settings lock both take
	# effect immediately on every member.
	var am_owner = Steam.getLobbyOwner(SteamLobby.LOBBY_ID) == SteamHustle.STEAM_ID
	var just_became_owner = am_owner and not _was_owner
	_was_owner = am_owner
	var locked = SteamLobby.is_lobby_settings_locked()
	# Steam can take a tick to deliver lobby data on rejoin — until then
	# getLobbyData("settings_locked") reads as empty regardless of the real
	# state. Without this gate the rejoining owner saw an enabled panel for
	# one frame and could sneak in a change before the lock data arrived
	# (the actual bug report). Bypassed for freshly CREATED lobbies (autoload
	# sets lobby_data_synced=true on _on_Lobby_Created) so the creator
	# doesn't get a momentary disabled panel.
	var sync_pending = not SteamLobby.lobby_data_synced
	if just_became_owner and not SteamLobby.MATCH_SETTINGS.empty():
		# Ownership transferred to us — sync the panel to the previous owner's
		# published settings BEFORE update_lobby_data fires. Otherwise we'd
		# publish whatever stale values the panel was carrying (typically the
		# user's last singleplayer training format, which the panel restored
		# at _ready), overwriting the actual lobby settings everyone agreed on.
		# Gated on just_became_owner so the owner's live edits don't get
		# clobbered by a reload on every subsequent data update.
		$"%GameSettingsPanelContainer".load_settings(SteamLobby.MATCH_SETTINGS)
	if am_owner and not locked and not sync_pending:
		$"%GameSettingsPanelContainer".enable()
		$"%GameSettingsPanelContainer".update_lobby_data()
	else:
		# Re-disable on ownership loss OR on a persistent settings lock; without
		# this a former owner (or the locker themselves) keeps the controls
		# editable but inert.
		$"%GameSettingsPanelContainer".disable()
	$"%LockSettingsButton".visible = am_owner and not locked and not sync_pending

func _on_LockSettingsButton_pressed():
	$"%LockSettingsConfirmDialog".show()

func _on_LockConfirmButton_pressed():
	SteamLobby.lock_lobby_settings()
	$"%LockSettingsConfirmDialog".hide()
	# Steam fires lobby_data_update on every member after setLobbyData, but
	# refresh locally too so the panel state flips instantly on the locker
	# without waiting on the network round-trip.
	_refresh_settings_panel_state()

func _on_LockCancelButton_pressed():
	$"%LockSettingsConfirmDialog".hide()

func _on_challenge_accept_pressed():
	if incoming_is_replay_challenge:
		incoming_is_replay_challenge = false
		SteamLobby.accept_replay_challenge()
	else:
		SteamLobby.accept_challenge()
	$"%ChallengeDialogScreen".hide()

func _on_challenge_decline_pressed():
	if incoming_is_replay_challenge:
		incoming_is_replay_challenge = false
		SteamLobby.decline_replay_challenge()
	else:
		SteamLobby.decline_challenge()
	$"%ChallengeDialogScreen".hide()

func _on_received_challenge(steam_id):
	incoming_is_replay_challenge = false
	$"%ChallengeAcceptButton".show()
	$"%ChallengeDeclineButton".text = "decline"
	$"%ChallengeLabel".text = Steam.getFriendPersonaName(steam_id) + " has challenged you."
	$"%ChallengeDialogScreen".show()
	if visible:
		$ChallengeSound.play()

func _on_challenge_cancelled():
	SteamLobby.cancel_challenge()
	$"%SendChallengeDialogScreen".hide()
	
func _on_user_challenge_pressed():
	$"%SendChallengeDialogScreen".show()

func _on_user_replay_challenge_pressed(member):
	pending_replay_challenge_member = member
	var ui_layer = get_parent()
	if !ui_layer.is_connected("replay_picked_for_challenge", self, "_on_replay_picked_for_challenge"):
		ui_layer.connect("replay_picked_for_challenge", self, "_on_replay_picked_for_challenge")
	var opponent_name = Steam.getFriendPersonaName(member.steam_id) if member else ""
	ui_layer.open_replay_picker_for_challenge(opponent_name)

func _on_replay_picked_for_challenge(match_data, path):
	pending_replay_match_data = match_data
	pending_replay_path = path
	_show_side_picker_dialog()

func _show_side_picker_dialog():
	var p1_name = "P1"
	var p2_name = "P2"
	if pending_replay_match_data and pending_replay_match_data.has("selected_characters"):
		var sc = pending_replay_match_data.selected_characters
		if sc.has(1) and sc[1].has("name"):
			p1_name = _display_char_name(sc[1]["name"])
		if sc.has(2) and sc[2].has("name"):
			p2_name = _display_char_name(sc[2]["name"])
	$"%SidePickerLabel".text = "Pick your side\n%s vs %s" % [p1_name, p2_name]
	$"%SidePickerP1Button".text = "P1 (" + p1_name + ")"
	$"%SidePickerP2Button".text = "P2 (" + p2_name + ")"
	# Restore-timers offer applies to any mode that runs a per-player clock —
	# both chess and increment carry chess_timer_state. Old replays still use
	# the bool field; new ones use timer_mode (already normalized via Utils
	# before reaching here).
	var has_timer = false
	if pending_replay_match_data:
		var mode = pending_replay_match_data.get("timer_mode", null)
		if mode == null:
			has_timer = pending_replay_match_data.get("chess_timer", false)
		else:
			has_timer = mode != "none"
	var has_timer_state = has_timer and pending_replay_match_data.has("chess_timer_state")
	$"%SidePickerRestoreTimers".visible = has_timer_state
	$"%SidePickerRestoreTimers".pressed = has_timer_state
	$"%SidePickerDialogScreen".show()

func _display_char_name(full_name):
	var css = Network.css_instance
	if css:
		return css.getCharName(full_name)
	if full_name.find("__") != -1:
		return full_name.split("__")[1]
	return full_name

func _on_side_picker_p1_pressed():
	_send_replay_challenge(1)

func _on_side_picker_p2_pressed():
	_send_replay_challenge(2)

func _on_side_picker_cancel_pressed():
	_clear_pending_replay_challenge()
	$"%SidePickerDialogScreen".hide()

func _send_replay_challenge(side):
	if pending_replay_challenge_member and pending_replay_match_data:
		pending_replay_match_data["restore_timers"] = $"%SidePickerRestoreTimers".visible and $"%SidePickerRestoreTimers".pressed
		SteamLobby.replay_challenge_user(pending_replay_challenge_member, pending_replay_match_data, side)
	_clear_pending_replay_challenge()
	$"%SidePickerDialogScreen".hide()

func _clear_pending_replay_challenge():
	pending_replay_challenge_member = null
	pending_replay_match_data = null
	pending_replay_path = ""

func show():
	.show()
	init()

func init():
	if SteamLobby.REMATCHING_ID != 0:
#		SteamLobby.set_status("busy")
		Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "game_started", "false")
		SteamLobby._setup_game_vs(SteamLobby.REMATCHING_ID)
	else:
		# Use _idle_status() instead of hardcoded "idle" — otherwise this
		# clobbers the user's manual busy toggle every time the lobby UI
		# re-inits (which happens after every match end).
		Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "status", SteamLobby._idle_status())
	$"%LoadingLobbyRect".hide()
	if Steam.getLobbyOwner(SteamLobby.LOBBY_ID) != SteamHustle.STEAM_ID:
		SteamLobby.request_match_settings()
		$"%LobbyLabel".text = Steam.getLobbyData(SteamLobby.LOBBY_ID, "name")
		$"%GameSettingsPanelContainer".init(false)
		$"%GameSettingsPanelContainer".disable()
		if !handshake_made:
			$"%LoadingLobbyRect".show()
			yield(SteamLobby, "received_match_settings")
			$"%LoadingLobbyRect".hide()
			handshake_made = true
	else:
		$"%GameSettingsPanelContainer".init(false)
		$"%GameSettingsPanelContainer"._on_received_match_settings(SteamLobby.MATCH_SETTINGS, true)
		# Publish current settings to lobby data so fresh-lobby joiners
		# can fast-path past the P2P request stall. Without this, the
		# owner only writes on the first slider change, so joining a
		# lobby where the owner hasn't touched settings yet falls back
		# to the slow P2P round-trip.
		$"%GameSettingsPanelContainer".update_lobby_data()
	$"%RoomCode".text = SteamLobby.get_lobby_code()
	$"%RoomCode".modulate = Color(SteamLobby.get_lobby_code())
	# Sync the lock button + panel state to the current lobby on first show
	# (and on every re-init after a match), so we don't have to wait for the
	# next lobby_data_update to surface the correct visibility/enabled state.
	_refresh_settings_panel_state()
	if Steam.getLobbyData(SteamLobby.LOBBY_ID, "version") != Global.VERSION:
		$"%WrongVersionScreen".show()
		var mismatched_version_text = "Mismatched versions. Make sure your game is fully updated, or you have the same mods enabled.\n\nYour game: %s \nThis lobby: %s" % [Global.VERSION, Steam.getLobbyData(SteamLobby.LOBBY_ID, "version")]
		$"%WrongVersionLabel".text = mismatched_version_text
#func _on_user_selected(index):
#	if users[index].steam_id == SteamHustle.STEAM_ID:
#		return
#	selected_user = users[index]
#	$"%StartButton".disabled = false


func _on_spectate_declined():
	$"%LoadingSpectatorRect".hide()
	pass

func _on_challenge_declined():
	$"%ChallengeDialogScreen".hide()
	$"%SendChallengeDialogScreen".hide()

func _on_start_button_pressed():
	if selected_user:
		SteamLobby.challenge_user(selected_user)

func _on_challenger_cancelled():
	$"%ChallengeDialogScreen".hide()
	if !SteamLobby.is_fighting():
		SteamLobby.set_status("idle")

func _on_retrieved_lobby_members(members):
	# Skip the full UserList/MatchList rebuild when the lobby UI isn't
	# visible (i.e. we're in a match). lobby_data_update fires constantly
	# during matches because both fighters publish hp_pct every 250ms,
	# and rebuilding the lists offscreen burns ~40ms/frame for nothing.
	# SPECTATORS still updates via SteamLobby._get_Lobby_Members which
	# runs unconditionally in UiSteamLobbyOld._on_lobby_data_update.
	if not is_visible_in_tree():
		return
	$"%LobbyLabel".text = Steam.getLobbyData(SteamLobby.LOBBY_ID, "name")
	users.clear()
	for child in $"%UserList".get_children():
		child.free()
	
	matches.clear()
	for child in $"%MatchList".get_children():
		child.free()

	for member in members:
		var user_scene = preload("res://ui/SteamLobby/LobbyUser.tscn").instance()
		$"%UserList".add_child(user_scene)
		user_scene.init(member)
		user_scene.connect("challenge_pressed", self, "_on_user_challenge_pressed")
		user_scene.connect("replay_challenge_pressed", self, "_on_user_replay_challenge_pressed")
#		user_list.add_item(member.steam_name, null)
		print("updating members")
		users.append(member)
		# setup match
		if member.status == "fighting" and member.opponent_id != 0 and member.player_id != 0 and member.game_started:
			if not (member.opponent_id in matches):
				var opponent
				for potential_opponent in members:
					if potential_opponent.steam_id == member.opponent_id:
						opponent = potential_opponent
						break
				if opponent:
#				p1 = member if member.player_id == 1 else 
					if opponent.opponent_id == 0 or opponent.player_id == 0:
						continue
					var p1 = opponent if opponent.player_id == 1 else member
					var p2 = opponent if p1 == member else member
					matches[member.steam_id] = {
						"p1": p1,
						"p2": p2,
					}

	for match_ in matches.values():
		print("updating matches")
		var match_scene = preload("res://ui/SteamLobby/LobbyMatch.tscn").instance()
		match_scene.connect("spectate_requested", self, "_on_spectate_requested")
		$"%MatchList".add_child(match_scene)
		match_scene.init(match_.p1, match_.p2)
	
	for child in $"%UserList".get_children():
		child.update_avatar()
		yield(child, "avatar_loaded")

	# Delegate to the centralized refresh so the lock + sync gating applies
	# here too. Was previously a bare panel.enable() for the owner, which
	# fired on every member-join (via _get_Lobby_Members -> retrieved_lobby_
	# members) and unlocked the panel visually on a locked lobby until the
	# next lobby_data_update re-disabled it.
	_refresh_settings_panel_state()

# How often to re-send the spectate request while it's still pending. P2P
# packets are sent reliable, but reliable delivery still fails when the P2P
# session hasn't come up yet (common right after returning from spectating, or
# on a flaky connection) — resending re-kicks the session instead of silently
# giving up. Mirrors the challenge button: stay pending with a cancel button
# rather than auto-cancelling after a fixed timeout.
const SPECTATE_RETRY_INTERVAL := 2.0

func _on_spectate_requested(player):
	var steam_id = player.steam_id
	$"%SpectateStatusLabel".text = "Requesting to spectate..."
	$"%SpectateCancelButton".show()
	$"%LoadingSpectatorRect".show()
	SteamLobby.request_spectate(steam_id)
	# Keep resending until the request is accepted or declined (either clears
	# SteamLobby.REQUESTING_TO_SPECTATE) or the user cancels (which clears it
	# too). A re-request to a different player also flips REQUESTING_TO_SPECTATE,
	# so any stale loop for the previous target stops on its own.
	while SteamLobby.REQUESTING_TO_SPECTATE == steam_id:
		yield(get_tree().create_timer(SPECTATE_RETRY_INTERVAL), "timeout")
		if SteamLobby.REQUESTING_TO_SPECTATE == steam_id:
			SteamLobby.request_spectate(steam_id)

func _on_spectate_cancel_pressed():
	SteamLobby.cancel_spectate_request()
	$"%LoadingSpectatorRect".hide()

func _on_back_button_pressed():
	if not visible: return
	Network.stop_multiplayer(true)
	Global.reload()


func _on_IncompatibleQuitButton_pressed():
	if not visible: return
	Network.stop_multiplayer(true)
	Global.reload()

func _on_received_replay_challenge(steam_id, replay_data, challenger_side):
	var p1_name = "P1"
	var p2_name = "P2"
	if replay_data.has("selected_characters"):
		var sc = replay_data.selected_characters
		if sc.has(1) and sc[1].has("name"):
			p1_name = _display_char_name(sc[1].name)
		if sc.has(2) and sc[2].has("name"):
			p2_name = _display_char_name(sc[2].name)
	var missing = _missing_chars_for_replay(replay_data)
	if !missing.empty():
		SteamLobby.decline_replay_challenge_with_reason("missing_mods", missing)
		return
	var challenger_name = Steam.getFriendPersonaName(steam_id)
	var their_char = p1_name if challenger_side == 1 else p2_name
	var your_side = 2 if challenger_side == 1 else 1
	var your_char = p2_name if challenger_side == 1 else p1_name
	incoming_is_replay_challenge = true
	$"%ChallengeAcceptButton".show()
	$"%ChallengeDeclineButton".text = "decline"
	$"%ChallengeLabel".text = "%s wants to replay-challenge you.\n%s vs %s\nThey'd play P%d (%s) — you'd play P%d (%s)." % [challenger_name, p1_name, p2_name, challenger_side, their_char, your_side, your_char]
	$"%ChallengeDialogScreen".show()
	if visible:
		$ChallengeSound.play()

func _on_replay_challenge_declined_with_reason(reason, detail):
	if reason == null:
		return
	var msg = "Replay challenge declined."
	if reason == "missing_mods":
		var missing_str = ""
		if detail is Array:
			var pretty = []
			for n in detail:
				pretty.append(_display_char_name(n))
			missing_str = ", ".join(pretty)
		msg = "Opponent is missing required mods:\n%s" % missing_str
	$"%ChallengeLabel".text = msg
	incoming_is_replay_challenge = false
	$"%ChallengeAcceptButton".hide()
	$"%ChallengeDeclineButton".text = "ok"
	$"%ChallengeDialogScreen".show()

func _missing_chars_for_replay(replay_data):
	var missing = []
	if !replay_data.has("selected_characters"):
		return missing
	var css = Network.css_instance
	if !css:
		return missing
	for player_id in [1, 2]:
		var sc = replay_data.selected_characters
		if !sc.has(player_id) or !sc[player_id].has("name"):
			continue
		var char_name = sc[player_id].name
		if !css.isCustomChar(char_name):
			continue
		if css.name_to_index.has(char_name):
			continue
		var retro = css.retro_charName(char_name)
		if retro != null and css.name_to_index.has(retro):
			continue
		missing.append(char_name)
	return missing
