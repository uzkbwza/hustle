extends Node

signal game_started()
signal game_setup()

onready var ui_layer = $UILayer
onready var game_layer = $GameLayer
onready var hud_layer = $HudLayer

# Modding hooks node (MainHooks). Grabbed in _ready; see MainHooks.gd.
var hooks = null

var singleplayer = false
var game
var ghost_game

var afterimages = []

var p1_ghost_action
var p1_ghost_data
var p1_ghost_extra

var p2_ghost_action
var p2_ghost_data
var p2_ghost_extra

var match_data = {}
var has_submitted_a_turn = false
var last_backup_tick = -1

# Per-match: which target player_ids we've already asked permission from
# (one request per match per target). Pending entries are still waiting on
# the response.
var style_permission_requested := {}
var style_permission_pending := {}

var started_ghost_this_frame = false

var _Global = Network

func _enter_tree():
	pass

func _ready():
	BorderManager.show_menu_art()
	
	# Modding hook surface (app/match lifecycle). Scene-embedded in Main.tscn;
	# gated on ModLoader.active — stays null when mods are off (fire-sites skip).
	# See MainHooks.gd.
	if ModLoader.active:
		hooks = get_node_or_null("Hooks")
		if hooks:
			hooks.host = self
	# Re-enforce the busy-mode toggle every time Main initializes — exit-match
	# calls Global.reload(), so even though SteamLobby (autoload) keeps the
	# preference, the lobby member data could have been left as "fighting"
	# or otherwise transient if a quit path skipped the _idle_status() reset.
	if SteamLobby.LOBBY_ID != 0:
		SteamLobby.apply_busy_mode()
	ui_layer.connect("singleplayer_started", self, "_on_game_started", [true])
	ui_layer.connect("loaded_replay", self, "_on_loaded_replay")
	connect("game_started", ui_layer, "on_game_started")
	Network.connect("start_game", self, "_on_game_started", [false])
	Network.connect("match_ready", self, "_on_match_ready")
	Network.connect("force_open_action_buttons", self, "_on_multiplayer_turn_started")
	Network.connect("style_save_response_received", self, "_on_style_save_response_received")
	SteamLobby.connect("received_spectator_match_data", self, "_on_received_spectator_match_data")
	$"%P1ActionButtons".connect("action_clicked", self, "on_action_clicked", [1])
	$"%P2ActionButtons".connect("action_clicked", self, "on_action_clicked", [2])
	$"%GhostButton".connect("toggled", self, "_on_ghost_button_toggled")
	$"%SaveReplayButton".connect("pressed", self, "save_replay")
	$"%SaveStylesButton".connect("pressed", self, "_show_style_save_menu", [true])
	$"%StyleBackButton".connect("pressed", self, "_show_style_save_menu", [false])
	$"%SaveP1StyleButton".connect("pressed", self, "save_player_style", [1])
	$"%SaveP2StyleButton".connect("pressed", self, "save_player_style", [2])
	if !Global.STYLE_SAVE_FEATURE_ENABLED:
		# Whole feature off — hide the only entry point to the style submenu
		# so the per-player save buttons can't be reached.
		$"%SaveStylesButton".hide()
	$"%PausePanel".connect("visibility_changed", self, "_on_pause_panel_visibility_changed")
	$"%CharacterSelect".connect("match_ready", self, "_on_match_ready")
	$"%GhostSpeed".connect("value_changed", self, "_on_ghost_speed_changed")
	$"%GhostWaitTimer".connect("timeout", self, "_on_ghost_wait_timer_timeout")
	$"%FreezeOnMyTurn".connect("pressed", self, "start_ghost")
	$"%FreezeOnMyTurn".connect("toggled", Global, "save_option", ["freeze_ghost_prediction"])
	$"%FreezeSound".connect("toggled", Global, "save_option", ["freeze_ghost_sound"])
	$"%FreezeSound".connect("pressed", self, "start_ghost")
	$"%AfterimageButton".connect("pressed", self, "start_ghost")
	$"%AfterimageButton".connect("toggled", Global, "save_option", ["ghost_afterimages"])
	$"%GameUI".hide()
	$"%MainMenu".show()
	ReplayManager.play_full = false
	if Network.multiplayer_active:
		Network.stop_multiplayer()
	Network.connect("player_disconnected", self, "_on_player_disconnected")
	$"%FreezeOnMyTurn".set_pressed_no_signal(Global.freeze_ghost_prediction)
	$"%AfterimageButton".set_pressed_no_signal(Global.ghost_afterimages)
#	setup_main_menu_game()
	SteamLobby.SETTINGS_LOCKED = false
	randomize()
	$"%NagWindow".hide()
	$"%NagWindow".rect_position = Vector2(randi() % 640, randi() % 360)
	Global.connect("nag_window", $"%NagWindow", "show")
	SteamLobby._stop_spectating()
	SteamLobby.quit_match()
	$"%P1ShowStyle".connect("toggled", self, "_on_show_style_toggled", [1])
	$"%P2ShowStyle".connect("toggled", self, "_on_show_style_toggled", [2])
	ReplayManager.replaying_ingame = false
	
#	SteamHustle.print_all_achievements()

	########################### charloader
	var mod_toggle = $"%ModToggle" if has_node("%ModToggle") else null
	var container = mod_toggle.get_parent() if mod_toggle else null

	if container and container.get_node_or_null("DeleteCache") == null:
		var btt = Button.new()
		btt.name = "DeleteCache"
		btt.text = "delete character cache"
		container.add_child(btt)
		container.move_child(btt, mod_toggle.get_index())
		btt.connect("pressed", self, "_delete_char_cache", [btt])
#
	var loaded_mods = false
	while !Global.mods_loaded:
		loaded_mods = true
		hide_main_menu(true)
		$"%LoadingCharactersLabel".show()
		$InputBlocker.show()
		$"%LoadingCharactersLabel2".show()
		$"%LoadingCharactersLabel2".text = Global.loading_character
		yield(get_tree(), "idle_frame")

	if loaded_mods:
		$"%MainMenu".show()
		$InputBlocker.hide()
		$"%LoadingCharactersLabel2".hide()
		$"%LoadingCharactersLabel".hide()

	if hooks:
		hooks.ready()

func _delete_char_cache(btt):
	var dir = Directory.new()
	_Global.css_instance.charPackages = {}
	for f in ModLoader._get_all_files("user://char_cache", "pck"):
		dir.remove(f)
	get_tree().quit()

func _on_show_style_toggled(on, player_id):
	if is_instance_valid(game):
		var player = game.get_player(player_id)
		if on:
			player.reapply_style()
		else:
			player.reset_style()
		# Keep the HUD portrait's palette in sync with the toggle.
		var hud = get_node_or_null("%HudLayer")
		if hud and hud.has_method("refresh_portrait_style"):
			hud.refresh_portrait_style(player_id)

func _on_player_disconnected():
	if hooks:
		hooks.player_disconnected()
	$"%OpponentDisconnectedLabel".show()
#	ui_layer._on_forfeit_button_pressed()
	ui_layer._on_opponent_disconnected()
	
	if !is_instance_valid(game):
		Global.reload()

func _on_game_started(singleplayer):
	ui_layer.reset_ui()
	if is_instance_valid(game):
		game.free()
		game = null
		stop_ghost()
	self.singleplayer = singleplayer
	Network.replay_saved = false
	hide_main_menu(true)

	if $"%P1InfoContainer".get_child(0) is PlayerInfo:
		$"%P1InfoContainer".get_child(0).queue_free()
	if $"%P2InfoContainer".get_child(0) is PlayerInfo:
		$"%P2InfoContainer".get_child(0).queue_free()

	$"%CharacterSelect".show()
	$"%CharacterSelect".init(singleplayer)
	$"%DirectConnectLobby".hide()
	$"%Lobby".hide()
	$"%SteamLobby".hide()
	if hooks:
		hooks.game_started(singleplayer)

func _on_ghost_wait_timer_timeout():
	if is_instance_valid(game):
		start_ghost()

func _on_loaded_replay(match_data):
#	match_data["replay"] = true
#	_on_match_ready(match_data)
	_Global.css_instance.net_loadReplayChars([match_data.selected_characters[1]["name"], match_data.selected_characters[2]["name"], match_data])
	match_data["replay"] = true
	_on_match_ready(match_data)

func _on_received_spectator_match_data(data):
#	data["spectating"] = true
#	_on_match_ready(data)
	# Request accepted: swap the "Requesting to spectate..." overlay over to the
	# loading message and drop the cancel button (too late to cancel now).
	var spectate_label = $"%SteamLobby".get_node_or_null("LoadingSpectatorRect/SpectateStatusLabel")
	if spectate_label:
		spectate_label.text = "Spectating...\n(Loading Characters, this may take a while)"
	var spectate_cancel = $"%SteamLobby".get_node_or_null("LoadingSpectatorRect/SpectateCancelButton")
	if spectate_cancel:
		spectate_cancel.hide()
	_Global.css_instance.net_loadReplayChars([data.selected_characters[1]["name"], data.selected_characters[2]["name"], data])
	data["spectating"] = true
	_on_match_ready(data)

func _on_match_ready(data):
	Utils.normalize_timer_settings(data)
	match_data = data
	if hooks:
		hooks.match_ready(data)
	# New match (incl. a freshly-accepted spectate): re-arm the once-per-match
	# autosave guard. Replay loops rebuild the game through _on_playback_requested
	# -> setup_game, which does NOT pass through here, so the flag survives them
	# and the spectated replay only autosaves once. See game.end_game.
	Network.replay_saved = false
	has_submitted_a_turn = false
	last_backup_tick = -1
	style_permission_requested.clear()
	style_permission_pending.clear()
	_set_save_style_button_disabled(1, false)
	_set_save_style_button_disabled(2, false)
	if match_data.has("replay_challenge"):
		singleplayer = false
	elif match_data.has("replay"):
		singleplayer = true
	else:
		singleplayer = data["singleplayer"]
	if !match_data.has("replay") and !match_data.has("replay_challenge"):
		ReplayManager.playback = false
	if match_data.has("replay_challenge") and match_data.has("selected_characters"):
		yield(_load_replay_chars_and_wait(match_data), "completed")
	SteamLobby.SETTINGS_LOCKED = false
	setup_game(singleplayer, data)
	emit_signal("game_started")

func _load_replay_chars_and_wait(match_data):
	var loading_rect = $"%SteamLobby".get_node_or_null("ReplayLoadingRect")
	var label = null
	if loading_rect:
		label = loading_rect.get_node_or_null("ReplayLoadingLabel")
		loading_rect.show()
		if label:
			label.text = "Loading replay characters..."
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
	var css = _Global.css_instance
	var my_side = Network.player_id
	for player_id in [1, 2]:
		var char_name = match_data.selected_characters[player_id]["name"]
		if !css.isCustomChar(char_name):
			continue
		var is_mine = (player_id == my_side)
		if label:
			if is_mine:
				label.text = "Loading your character: " + css.getCharName(char_name) + "..."
			else:
				label.text = "Loading opponent's character: " + css.getCharName(char_name) + "..."
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		var idx = css.name_to_index.get(char_name)
		if idx == null:
			idx = css.name_to_index.get(css.retro_charName(char_name))
		if idx != null:
			css.loadListChar(idx, !is_mine)
		yield(get_tree(), "idle_frame")
	# Spectators have no opponent to handshake with — signal_replay_mods_loaded
	# returns early when OPPONENT_ID == 0, so the wait loop would hang forever.
	if not match_data.get("spectating"):
		if label:
			label.text = "Waiting for opponent to load their character..."
		yield(get_tree(), "idle_frame")
		SteamLobby.signal_replay_mods_loaded()
		while not SteamLobby.remote_replay_mods_loaded:
			yield(get_tree(), "idle_frame")
	if loading_rect:
		loading_rect.hide()


func show_lobby():
	$"%DirectConnectLobby".show()
	$"%Lobby".show()

func setup_game(singleplayer, data):
	hide_main_menu(true)
	if is_instance_valid(game):
		game.queue_free()
	call_deferred("setup_game_deferred", singleplayer, data)
	emit_signal("game_setup")
	if hooks:
		hooks.game_setup(singleplayer, data)

func setup_main_menu_game():
	game = preload("res://Game.tscn").instance()
	game_layer.add_child(game)

func save_replay():
	var filename = ReplayManager.save_replay(match_data, $"%ReplayName".text)
	$"%SaveReplayButton".disabled = true
	$"%SaveReplayButton".text = "saved"
	$"%SaveReplayLabel".text = "saved replay to " + filename
	if hooks:
		hooks.replay_saved(filename)

# Save-replay shortcut (rebindable, default Ctrl+S). With the pause menu open,
# mirrors the Save Replay button (and updates its label inside the panel).
# With the menu closed, save silently and flash a 2-second "saved replay"
# toast so the player gets feedback without having to open the menu.
func _unhandled_key_input(event):
	if not event.pressed or event.echo:
		return
	if not event.is_action_pressed(Hotkeys.SAVE_REPLAY):
		return
	if _style_menu_active:
		return
	var btn = get_node_or_null("%SaveReplayButton")
	if btn == null or btn.disabled:
		return
	var pause_open = has_node("%PausePanel") and $"%PausePanel".visible
	save_replay()
	if not pause_open:
		_show_save_replay_toast()
	get_tree().set_input_as_handled()

# Floating duplicate of the pause panel's SaveReplayLabel shown for 2 seconds
# when Ctrl+S fires with the pause menu closed. Duplicating the existing
# label inherits its theme/font/anchors so the toast looks identical to what
# the player would see if they'd opened the pause menu themselves. Auto-
# dismisses early if the pause panel opens (its own label is now on screen)
# or if the pause panel's SaveReplayLabel text changes (a fresher save / an
# unrelated message takes over).
const _TOAST_NODE_NAME := "_SaveReplayToast"
const _TOAST_DURATION := 1.5
var _toast_baseline_label_text := ""

func _get_save_replay_toast():
	var host = get_node_or_null("%GameUI")
	if host == null:
		return null
	return host.get_node_or_null(_TOAST_NODE_NAME)

func _show_save_replay_toast():
	# Tear down any toast already on screen — the new save replaces it.
	var existing = _get_save_replay_toast()
	if existing:
		existing.queue_free()
	var pause_label: Label = get_node_or_null("%SaveReplayLabel")
	if pause_label == null:
		return
	# Parent the toast under GameUI (the Control that holds the pause panel
	# and owns the global theme) so it inherits the same fonts and styling
	# the pause label gets. A standalone CanvasLayer would lose all that
	# inheritance and render the label in the engine default theme.
	var host = get_node_or_null("%GameUI")
	if host == null:
		return
	_toast_baseline_label_text = pause_label.text
	var label_copy: Label = pause_label.duplicate()
	label_copy.name = _TOAST_NODE_NAME
	# Anchor to screen center, then nudge down ~50px so the toast doesn't
	# overlap player-info HUD elements at the very middle.
	label_copy.set_anchors_preset(Control.PRESET_CENTER)
	label_copy.margin_left = -274
	label_copy.margin_top = 42
	label_copy.margin_right = 274
	label_copy.margin_bottom = 58
	label_copy.visible = true
	host.add_child(label_copy)
	var timer = Timer.new()
	timer.wait_time = _TOAST_DURATION
	timer.one_shot = true
	label_copy.add_child(timer)
	timer.start()
	timer.connect("timeout", label_copy, "queue_free")

var _style_menu_main_visibility := {}
var _style_menu_active := false

# Toggles the pause panel between the main button list and the style-saving
# sub-menu. Snapshots each main button's visibility on the way in and
# restores it on the way out so we don't fight with code that conditionally
# shows/hides specific buttons (e.g. forfeit).
func _show_style_save_menu(show_styles: bool):
	if show_styles == _style_menu_active:
		return
	_style_menu_active = show_styles
	var main_buttons = ["%ResumeButton", "%ReplayName", "%SaveReplayButton",
			"%SaveStylesButton", "%PauseOptionsButton",
			"%QuitToMainMenuButton", "%ForfeitButton"]
	var style_buttons = ["%StyleName", "%SaveP1StyleButton",
			"%SaveP2StyleButton", "%StyleBackButton"]
	if show_styles:
		_style_menu_main_visibility.clear()
		for path in main_buttons:
			var n = get_node_or_null(path)
			if n:
				_style_menu_main_visibility[path] = n.visible
				n.visible = false
	else:
		for path in main_buttons:
			var n = get_node_or_null(path)
			if n:
				n.visible = _style_menu_main_visibility.get(path, true)
		_style_menu_main_visibility.clear()
	for path in style_buttons:
		var n = get_node_or_null(path)
		if n:
			n.visible = show_styles

# Whenever the pause panel hides (escape, resume, etc.), drop out of the
# style sub-menu so the next open shows the main pause buttons again with
# their previously-tracked visibility restored.
func _on_pause_panel_visibility_changed():
	if !$"%PausePanel".visible and _style_menu_active:
		_show_style_save_menu(false)

func save_player_style(player_id: int):
	if !Global.STYLE_SAVE_FEATURE_ENABLED:
		return
	if !is_instance_valid(game):
		return
	var player = game.get_player(player_id)
	if !is_instance_valid(player) or player.applied_style == null:
		$"%SaveReplayLabel".text = "p%d has no style to save" % player_id
		return
	# Respect the style's auto-share flag. Legacy styles without the field are
	# treated as opted in (default true). Saving your own player's style
	# bypasses the share gate (singleplayer or your own MP slot — you have
	# the file locally already). The latest-in-chain steam_id (creator if no
	# modifiers, else last modifier) also bypasses regardless of context —
	# they're the most recent person to have touched the style.
	# Whole gate is short-circuited while the feature flag is off — saves
	# proceed unconditionally and no permission prompts are emitted.
	var src = player.applied_style
	# `match_data.replay` is the frames-array for both pure replay viewing
	# AND for live spectating (set in SteamLobby._on_spectate_request_accepted)
	# — so checking it alone misclassifies spectators as replay viewers. Treat
	# "no live peer to ask" as the real gate further down via in_lobby; here
	# we only need is_replay to suppress saving-own bookkeeping.
	var is_replay = match_data.get("replay", false) or match_data.get("replay_challenge", false)
	# Spectators are never the "owner" — they're outside the match.
	# Network.multiplayer_active (the getter) returns false for spectators,
	# so excluding them explicitly stops the !multiplayer_active branch from
	# treating them as a local solo player.
	var saving_own = !is_replay and !SteamLobby.SPECTATING and (!Network.multiplayer_active or Network.player_id == player_id)
	var i_am_chain_owner = _is_chain_latest(src)
	if Global.STYLE_SAVE_FEATURE_ENABLED and !saving_own and !i_am_chain_owner and src is Dictionary and !src.get("allow_others_save", true):
		# Real "no peer" gate: a pure replay file (no MP, no spectating) has
		# no one to ask. Live MP fighters and live spectators do — both fall
		# through to the broadcast_rpc request below.
		var in_lobby = Network.multiplayer_active or SteamLobby.SPECTATING
		if !in_lobby:
			$"%SaveReplayLabel".text = "p%d's style is not shareable" % player_id
			return
		if style_permission_requested.has(player_id):
			# Button should already be disabled — defensive no-op.
			return
		style_permission_requested[player_id] = true
		style_permission_pending[player_id] = true
		var requester = Global.get_player_data().username
		var style_name = src.get("style_name", "") if src is Dictionary else ""
		Network.broadcast_rpc("receive_style_save_request", [player_id, requester, style_name])
		$"%SaveReplayLabel".text = "asked p%d for permission..." % player_id
		_set_save_style_button_disabled(player_id, true)
		return
	_do_save_player_style(player_id, _duplicate_style_object(player.applied_style))

func _is_chain_latest(style) -> bool:
	if !(style is Dictionary):
		return false
	var sid = SteamHustle.STEAM_ID
	if sid == null or typeof(sid) != TYPE_INT or sid <= 0:
		return false
	var my_id = str(sid)
	var latest_id = ""
	var mod_ids = style.get("modifier_ids", [])
	if mod_ids is Array and !mod_ids.empty():
		latest_id = str(mod_ids[mod_ids.size() - 1])
	else:
		latest_id = str(style.get("creator_id", ""))
	return latest_id != "" and latest_id == my_id

func _set_save_style_button_disabled(player_id: int, disabled: bool):
	var path = "%%SaveP%dStyleButton" % player_id
	if has_node(path):
		get_node(path).disabled = disabled

func _do_save_player_style(player_id: int, style):
	var requested_name = $"%StyleName".text.strip_edges()
	if requested_name == "":
		# Fall back to the style's own name (carried in the .style dict).
		# Final fallback to the player's username if the style somehow has
		# no name (old save without it).
		requested_name = style.get("style_name", "") if style is Dictionary else ""
		if requested_name == "":
			var ud = match_data.get("user_data", {}) if match_data else {}
			requested_name = ud.get("p%d" % player_id, "untitled")
	requested_name = Utils.filter_filename(requested_name)
	if requested_name == "":
		requested_name = "untitled"
	var unique_name = _next_available_style_name(requested_name)
	style["style_name"] = unique_name
	Custom.save_style(style)
	$"%SaveReplayLabel".text = "saved p%d style as %s.style" % [player_id, unique_name]

# Response from the style's owner. Filter to messages addressed to us:
# steam matches by verified steam_id, relay falls back to username.
func _on_style_save_response_received(target_player_id, requester_id, requester_name, allowed):
	if !_style_response_for_me(requester_id, requester_name):
		return
	if !style_permission_pending.has(target_player_id):
		return
	style_permission_pending.erase(target_player_id)
	if !allowed:
		# Chat already surfaces the denial — don't double up in pause menu.
		return
	if !is_instance_valid(game):
		return
	var player = game.get_player(target_player_id)
	if !is_instance_valid(player) or player.applied_style == null:
		$"%SaveReplayLabel".text = "p%d's style is gone" % target_player_id
		return
	_do_save_player_style(target_player_id, _duplicate_style_object(player.applied_style))

func _style_response_for_me(requester_id, requester_name) -> bool:
	if Network.steam:
		return requester_id != 0 and requester_id == SteamHustle.STEAM_ID
	return requester_name == Global.get_player_data().username

# Returns a style_name that doesn't collide with existing files in the
# user's custom folder. If `base` is taken, appends 2, 3, ... until free.
func _next_available_style_name(base: String) -> String:
	var dir = Directory.new()
	var name = base
	var n = 2
	while dir.file_exists("user://custom/" + name + ".style"):
		name = base + str(n)
		n += 1
	return name

func _duplicate_style_object(style):
	if style is Dictionary:
		return style.duplicate(true)
	# Style might be a Resource — try .duplicate() if available, else return as-is.
	if style and style.has_method("duplicate"):
		return style.duplicate(true)
	return style

func hide_main_menu(all=false):
	ui_layer.hide_main_menu(all)

func _format_p2_name(p2_name: String):
	if p2_name.begins_with("F-") and "__" in p2_name and p2_name.split("__").size() > 1:
		return p2_name.split("__")[1]
	return p2_name

func setup_game_deferred(singleplayer, data):
	game = preload("res://Game.tscn").instance()
	game_layer.add_child(game)
	game.connect("simulation_continue", self, "_on_simulation_continue")
	game.connect("player_actionable", self, "_on_player_actionable")
	game.connect("playback_requested", self, "_on_playback_requested")
	game.connect("zoom_changed", self, "_on_zoom_changed")
	
	Network.game = game
	
	if !data.has("user_data"):
		var ud := {}
		if Network.multiplayer_active:
			ud["p1"] = Network.pid_to_username(1)
			ud["p2"] = Network.pid_to_username(2)
			# Snapshot both sides' name colors so replays reproduce them
			# without depending on the original lobby still existing.
			if Network.steam:
				var p1_steam = SteamLobby.steam_id_for_match_side(1)
				var p2_steam = SteamLobby.steam_id_for_match_side(2)
				var p1_col = Global.get_remote_name_color(p1_steam) if p1_steam != 0 else null
				var p2_col = Global.get_remote_name_color(p2_steam) if p2_steam != 0 else null
				if p1_col != null:
					ud["p1_color"] = p1_col.to_html(false)
				if p2_col != null:
					ud["p2_color"] = p2_col.to_html(false)
			elif Global.has_name_color():
				# Legacy MP: only know the local user's color. Apply it to
				# the side they're playing.
				ud["p" + str(Network.player_id) + "_color"] = Global.get_name_color().to_html(false)
		else:
			ud["p1"] = Global.get_player_data().username
			ud["p2"] = _format_p2_name(data.selected_characters[2]["name"])
			# Singleplayer: user controls P1.
			if Global.has_name_color():
				ud["p1_color"] = Global.get_name_color().to_html(false)
		data["user_data"] = ud
	
	if game.start_game(singleplayer, data) is bool:
		return
	var timer_mode = data.get("timer_mode", "default")
	# "none" mode skips timer setup entirely. Other modes need set_turn_time
	# to seed the timer's wait_time. Undo path keeps the existing chess clock
	# running — only re-init the timer when we're not in chess mode.
	if timer_mode != "none":
		if !Network.undo or timer_mode != "chess":
			if timer_mode == "increment":
				# Starting bank is max(starting_time, increment) per spec.
				# Normalize already bumps starting up to increment, but keep
				# max() explicit so the rule is visible at the call site.
				var starting = int(data.get("increment_starting_time", 60))
				var inc = int(data.get("increment_per_turn", 10))
				var bank = int(max(starting, inc))
				# Cap to increment_max_time if set (in minutes; 0 = no cap).
				# Matches the per-turn cap inside _apply_increment so the
				# initial bank can't sit above the running limit.
				var max_minutes = int(data.get("increment_max_time", 0))
				if max_minutes > 0:
					bank = int(min(bank, max_minutes * 60))
				ui_layer.set_turn_time(bank, false)
			elif data.has("turn_time"):
				ui_layer.set_turn_time(data.turn_time, timer_mode == "chess")
		else:
			ui_layer.start_timers()
	ui_layer.init(game)
	if data.has("replay_challenge") and data.replay_challenge and data.get("restore_timers") and data.has("chess_timer_state"):
		ui_layer.restore_chess_timer_state(data.chess_timer_state)
	hud_layer.init(game)
	var p1 = game.get_player(1)
	var p2 = game.get_player(2)
	p1.debug_label = $"%DebugLabelP1"
	p2.debug_label = $"%DebugLabelP2"
	var p1_info_scene = p1.player_info_scene.instance()
	var p2_info_scene = p2.player_info_scene.instance()
	p1_info_scene.set_fighter(p1)
	p2_info_scene.set_fighter(p2)
	if $"%P1InfoContainer".get_child(0) is PlayerInfo:
#		$"%P1InfoContainer".remove_child($"%P1InfoContainer".get_child(0))
		$"%P1InfoContainer".get_child(0).queue_free()
	if $"%P2InfoContainer".get_child(0) is PlayerInfo:
#		$"%P2InfoContainer".remove_child($"%P2InfoContainer".get_child(0))
		$"%P2InfoContainer".get_child(0).queue_free()
	for child in $"%ActivePlayerInfoContainer".get_children():
		child.queue_free()

	$"%P1InfoContainer".add_child(p1_info_scene)
	$"%P1InfoContainer".move_child(p1_info_scene, 0)
	$"%P2InfoContainer".add_child(p2_info_scene)
	$"%P2InfoContainer".move_child(p2_info_scene, 0)
	ui_layer.p1_info_scene = p1_info_scene
	ui_layer.p2_info_scene = p2_info_scene

func _on_ghost_button_toggled(toggled):
	if toggled:
		start_ghost()
	else:
		stop_ghost()

func _on_player_actionable():
#	if singleplayer or Network.player_id == id:
	ui_layer.on_player_actionable()
	if hooks:
		hooks.turn_ui_opened()
	$"%GhostWaitTimer".start()
	start_ghost()
	_maybe_save_backup()
	_reset_save_replay_button()

func _on_multiplayer_turn_started():
	_maybe_save_backup()
	_reset_save_replay_button()

# Re-arm the Save Replay button each new turn so the player can re-save the
# updated replay (without having to close + re-open the pause menu).
func _reset_save_replay_button():
	var btn = get_node_or_null("%SaveReplayButton")
	if btn == null:
		return
	btn.disabled = false
	btn.text = "save replay"

func _maybe_save_backup():
	if !is_instance_valid(game):
		return
	if SteamLobby.SPECTATING:
		return
	if game.current_tick == last_backup_tick:
		return
	last_backup_tick = game.current_tick
	if Global.enable_replay_backups and has_submitted_a_turn and !ReplayManager.playback and !game.game_finished:
		ReplayManager.save_replay_backup(match_data)
	has_submitted_a_turn = true

func on_action_clicked(action, data, extra, player_id):
	if hooks:
		hooks.action_clicked(player_id, action, data, extra)
	if player_id == 1:
		p1_ghost_action = action
		p1_ghost_data = data
		p1_ghost_extra = extra
	else:
		p2_ghost_action = action
		p2_ghost_data = data
		p2_ghost_extra = extra
	start_ghost()
	$"%AdvantageLabel".text = ""
	pass

func start_ghost():
	call_deferred("_start_ghost")

func _process(_delta):
	align_afterimages()
	if is_instance_valid(game):
		$"%SpeedLines".set_direction(game.camera.current_direction)
		$"%SpeedLines".set_speed(game.camera.current_speed / game.camera.zoom.x)
		$"%SpeedLines".tick = game.current_tick
		# Per-character fade anchors. Use camera.global_position (NOT
		# get_camera_screen_center, which may include the shake offset) so
		# the anchors track the un-shaken camera position — the speed lines
		# then ignore screen rumble. Same world-to-screen math the
		# super-effect overlay in HudLayer uses to place per-player overlays.
		if is_instance_valid(game.p1) and is_instance_valid(game.p2):
			var screen_center = game.get_viewport_rect().size / 2
			var cam_pos = game.camera.global_position
			var zoom = game.camera.zoom.x
			var p1_screen = (game.p1.global_position - cam_pos) / zoom + screen_center
			var p2_screen = (game.p2.global_position - cam_pos) / zoom + screen_center
			$"%SpeedLines".set_player_anchors(p1_screen, p2_screen)
		# Suppress lines through hit / super freeze. Freeze is visually a
		# beat-pause; the pre-hit camera motion can leave intensity above
		# the draw cutoff for a tick or two into the freeze, which reads as
		# the lines briefly flashing on for a frame as the freeze starts.
		$"%SpeedLines".on = !game.is_waiting_on_player() and game.super_freeze_ticks <= 0
	_tick_save_replay_toast()

func _tick_save_replay_toast():
	var toast = _get_save_replay_toast()
	if toast == null:
		return
	if has_node("%PausePanel") and $"%PausePanel".visible:
		toast.queue_free()
		return
	var pause_label = get_node_or_null("%SaveReplayLabel")
	if pause_label and pause_label.text != _toast_baseline_label_text:
		toast.queue_free()

func _physics_process(delta):
	set_deferred("started_ghost_this_frame", false)

func align_afterimages():
	if is_instance_valid(game):
		var zoom = game.camera.zoom.x * game.camera_zoom
		var center = -game.camera_snap_position / zoom
#		center.y = min(center.y, ghost_game.camera.limit_bottom)
		for image in $"%Afterimages".get_children():
			image.rect_position = center + image.start_position / zoom + game.camera.offset / zoom
			image.visible = $"%AfterimageButton".pressed

func _start_ghost():
	if started_ghost_this_frame:
		return
	started_ghost_this_frame = true
#	print("starting ghost" + str(randi()))
	if !$"%GhostWaitTimer".is_stopped():
		yield($"%GhostWaitTimer", "timeout")
		return
	stop_ghost()
	for child in $"%GhostViewport".get_children():
		child.queue_free()
	afterimages = []
	$"%AfterImage1".texture = null
	$"%AfterImage2".texture = null
	if !$"%GhostButton".pressed:
		return
	if ReplayManager.playback:
		return
	if !is_instance_valid(game):
		return
	if !game.prediction_enabled:
		return
#
	ghost_game = preload("res://Game.tscn").instance()
	ghost_game.is_ghost = true
	$"%GhostViewport".add_child(ghost_game)
	ghost_game.start_game(true, match_data)
	ghost_game.connect("ghost_finished", self, "ghost_finished")
	ghost_game.connect("make_afterimage", self, "make_afterimage", [], CONNECT_DEFERRED)
	ghost_game.connect("ghost_my_turn", self, "ghost_my_turn", [], CONNECT_DEFERRED)
	ghost_game.ghost_speed = $"%GhostSpeed".get_speed()
	ghost_game.ghost_freeze = $"%FreezeOnMyTurn".pressed
	game.call_deferred("copy_to", ghost_game)
	game.ghost_game = ghost_game
	var p1 = ghost_game.get_player(1)
	var p2 = ghost_game.get_player(2)

	p1.queued_action = p1_ghost_action
	p1.queued_data = p1_ghost_data
	p1.queued_extra = p1_ghost_extra
	p1.is_ghost = true

	p2.queued_action = p2_ghost_action
	p2.queued_data = p2_ghost_data
	p2.queued_extra = p2_ghost_extra
	p2.is_ghost = true
	call_deferred("fix_ghost_objects", ghost_game)


func ghost_my_turn():
	if Global.freeze_ghost_sound:
		$GhostMyTurnSound.play()

func make_afterimage():
	if !$"%AfterimageButton".pressed:
		return
	var img = $"%GhostViewport".get_texture().get_data()
	
	var img_dest = Image.new()
	img_dest.create(img.get_width(), img.get_height(), false, img.get_format())
	img_dest.blit_rect(img, Rect2(Vector2(), Vector2(img.get_width(), img.get_height())), Vector2.ZERO)
	img_dest.flip_y()
	# Create a texture for it.
	var tex = ImageTexture.new()
	tex.create_from_image(img_dest)
	
	var texture_rect = $"%AfterImage1" if $"%AfterImage1".texture == null else $"%AfterImage2"
	texture_rect.start_position = game.camera_snap_position
	texture_rect.texture = tex

func ghost_finished():
#	yield(get_tree(), "idle_frame")
	start_ghost()

func fix_ghost_objects(ghost_game_):
	for obj_name in ghost_game_.objs_map:
		var object = ghost_game_.objs_map[obj_name]
		if object:
			object.is_ghost = true
func stop_ghost():
	if is_instance_valid(game):
		game.ghost_game = null
	for child in $"%GhostViewport".get_children():
		child.hide()
		child.ghost_hidden = true
	for child in $"%Afterimages".get_children():
		child.texture = null

func _on_zoom_changed():
	for child in $"%Afterimages".get_children():
		child.texture = null

func _on_simulation_continue():
	p1_ghost_action = null
	p1_ghost_data = null
	p1_ghost_extra = null
	p2_ghost_action = null
	p2_ghost_data = null
	p2_ghost_extra = null
	call_deferred("stop_ghost")

func _on_ghost_speed_changed(_value):
	if is_instance_valid(game):
		_start_ghost()

func _on_playback_requested():
	ReplayManager.playback = true
	setup_game(singleplayer, match_data)


func _on_ReplayName_text_entered(_new_text):
	save_replay()
