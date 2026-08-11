extends CanvasLayer

onready var action_buttons = $"%ActionButtons"
onready var p1_action_buttons = $"%P1ActionButtons"
onready var p2_action_buttons = $"%P2ActionButtons"
onready var p1_side_container = $"%ActionButtons/VBoxContainer"
onready var p2_side_container = $"%ActionButtons/VBoxContainer2"
var _name_color_publish_timer: Timer

signal singleplayer_started()
signal multiplayer_started()
signal loaded_replay(match_data)
signal replay_picked_for_challenge(match_data, path)
signal received_synced_time()

var replay_picker_for_challenge = false
#
#const dark_mode_color = Color("0b0c0f")
#const light_mode_color = Color("33394b")

var game
var turns_taken = {
	1: false,
	2: false
}

var turn_time = 30

var p1_turn_time = 30
var p2_turn_time = 30

# Active timer mode for the current match. One of:
#   "default" — old default: per-turn timer that resets each turn (turn_time secs)
#   "none"    — no timer at all
#   "chess"   — chess clock: total bank per player (turn_time mins), MIN_TURN_TIME refresh
#   "increment" — chess clock that grows by increment_per_turn each turn; debt on run-out
# Replaces the old `chess_timer` bool — old replays normalize via Utils on
# match-ready. `chess_timer` is kept as a derived "is there a persistent
# per-player bank?" bool used for state save/restore gates.
var timer_mode = "default"
var chess_timer = false

# Increment-mode "debt" tracker. Running out adds increment to debt and resets
# the bank to increment, so the player can finish the turn — but they pay
# back via leftover bank at lock-in on subsequent (non-run-out) turns.
var p1_debt = 0.0
var p2_debt = 0.0

# Flag set when a player runs out of time in increment mode. Used twice:
#   1) end_turn_for skips the lock-in pay-debt step (run-out turns don't pay)
#   2) on_player_actionable's _apply_increment skips the next-turn +increment
#      add (the "you don't gain any time the next turn" penalty)
# Cleared once both have run (i.e. at the start of the turn AFTER the run-out
# turn). Saved with chess_timer_state so replay-challenge restore keeps the
# penalty intact across resumed matches.
var p1_just_ran_out = false
var p2_just_ran_out = false

var draw_bg_circle = false

var lock_in_tick = -INF

const DISCORD_URL = "https://discord.gg/YourOnlyMoveIsHUSTLE"
const TWITTER_URL = "https://x.com/YourMoveHUSTLE"
const IVY_SLY_URL = "https://www.ivysly.com"
const TIKTOK_URL = "https://www.tiktok.com/@youronlymoveishustle"
const STEAM_URL = "https://store.steampowered.com/app/2212330"
const ITCH_URL = "https://ivysly.itch.io/your-only-move-is-hustle"
var MIN_TURN_TIME = 5.0

onready var lobby = $Lobby
onready var direct_connect_lobby = $DirectConnectLobby
onready var p1_turn_timer = $"%P1TurnTimer"
onready var p2_turn_timer = $"%P2TurnTimer"
onready var block_advantage_label = $"%BlockAdvantageLabel"
onready var neutral_label = $"%NeutralLabel"

var p1_synced_time = null
var p2_synced_time = null

var game_started = false
var timer_sync_tick = -1
var actionable = false

var forfeit_pressed = false

var actionable_time = 0

var received_synced_time = false

var quit_on_rematch = true

var p1_time_run_out = false
var p2_time_run_out = false

var p1_info_scene
var p2_info_scene

onready var global_option_check_buttons = {
	$"%EnableStyleColorsButton": "enable_custom_colors",
	$"%EnableAurasButton": "enable_custom_particles",
	$"%EnableHitsparksButton": "enable_custom_hit_sparks",
	$"%ShowCommunityEventsButton": "show_community_events",
	$"%EnableEmotes": "enable_emotes",
	$"%LastMoveIndicatorButton": "show_last_move_indicators",
	$"%ProjectileOwnersButton": "show_projectile_owners",
	$"%PlaybackHotkeysRequireWindowButton": "playback_hotkeys_require_window",
	$"%SpeedLinesButton": "speed_lines_enabled",
	$"%AutoFCButton": "auto_fc",
	$"%ExtraInfoButton": "show_extra_info",
	$"%TimerSoundButton": "enable_timer_sound",
	$"%ExtraFreezeFrames": "replay_extra_freeze_frames",
	$"%EnableReplayBackups": "enable_replay_backups",
	$"%XYPlotInvertSnapButton": "xyplot_invert_snap",
	$"%HealthCountButton": "show_health_count",
	$"%NextTurnHudButton": "show_next_turn_info_hud",
	$"%ShowNextTurnOnCharsButton": "show_next_turn_info_on_chars",
#	$"%SingleplayerForfeitButton": "forfeit_buttons_enabled",
}

func _enter_tree():
	if Global.character_select_node == null:
		Global.character_select_node = $"%CharacterSelect"
	else:
		$"%CharacterSelect".free()
		var css: Node = Global.character_select_node
		add_child(css)
		move_child(css, 15)
		css.name = "CharacterSelect"
		css.owner = owner
		css.unique_name_in_owner = true
		css.reset()

func _ready():
	if Global.winws_detected:
#		$"%MultiplayerButton".disabled = true
		$"%SteamMultiplayerButton".disabled = true
		$"%WinwsLabel".show()
	if not Global.XY_SNAP_TOGGLE_ENABLED:
		# XY plots always snap when the toggle feature flag is off — hide the
		# now-inert "hold shift to snap" CheckButton from the options UI. The
		# button stays wired to xyplot_invert_snap so reviving the flag picks
		# up the user's prior preference.
		$"%XYPlotInvertSnapButton".hide()
	
	$"%SingleplayerButton".connect("pressed", self, "_on_singleplayer_pressed")
	$"%MultiplayerButton".connect("pressed", self, "_on_multiplayer_pressed")
	$"%SteamMultiplayerButton".connect("pressed", self, "_on_steam_multiplayer_pressed")
	$"%CustomizeButton".connect("pressed", self, "_on_customize_pressed")
	$"%DirectConnectButton".connect("pressed", self, "_on_direct_connect_button_pressed")
	$"%RematchButton".connect("pressed", self, "_on_rematch_button_pressed")
	$"%QuitButton".connect("pressed", self, "_on_quit_button_pressed")
	$"%QuitToMainMenuButton".connect("pressed", self, "_on_quit_button_pressed")
	$"%ForfeitButton".connect("pressed", self, "_on_forfeit_button_pressed")
	$"%QuitProgramButton".connect("pressed", self, "_on_quit_program_button_pressed")
	$"%ResumeButton".connect("pressed", self, "pause")
	$"%ReplayButton".connect("pressed", self, "_on_view_replays_button_pressed")
	$"%ReplayCancelButton".connect("pressed", self, "_on_replay_cancel_pressed")
	$"%OpenReplayFolderButton".connect("pressed", self, "open_replay_folder")
	$"%P1ActionButtons".connect("turn_ended", self, "end_turn_for", [1])
	$"%P2ActionButtons".connect("turn_ended", self, "end_turn_for", [2])
	$"%ShowAutosavedReplays".connect("pressed", self, "_on_view_replays_button_pressed")
	$"%ShowBackupReplays".connect("pressed", self, "_on_view_replays_button_pressed")
	if has_node("%ReplaySearchEdit"):
		$"%ReplaySearchEdit".connect("text_changed", self, "_on_replay_search_changed")
	if has_node("%VersionModeButton"):
		$"%VersionModeButton".connect("pressed", self, "_on_version_mode_pressed")
	_refresh_version_mode_label()
	if has_node("%NoMissingCharactersToggle"):
		$"%NoMissingCharactersToggle".connect("toggled", self, "_on_replay_filter_toggle_changed")
	# Confirm "dialogs" are instances of the shared Window scene (same one
	# the options menu uses). Show via .show() / hide via .hide(); buttons
	# are wired manually instead of going through ConfirmationDialog's
	# get_ok()/get_cancel() pair.
	if has_node("%MissingConfirmButton"):
		$"%MissingConfirmButton".connect("pressed", self, "_on_missing_char_confirmed")
	if has_node("%MissingCancelButton"):
		$"%MissingCancelButton".connect("pressed", self, "_on_missing_char_cancelled")
	if has_node("%OldVersionConfirmButton"):
		$"%OldVersionConfirmButton".connect("pressed", self, "_on_old_version_confirmed")
	if has_node("%OldVersionCancelButton"):
		$"%OldVersionCancelButton".connect("pressed", self, "_on_old_version_cancelled")
	$"%DiscordButton".connect("pressed", Steam, "activateGameOverlayToWebPage", [DISCORD_URL])
	$"%IvySlyLinkButton".connect("pressed", Steam, "activateGameOverlayToWebPage", [IVY_SLY_URL])
	$"%WishlistButton".connect("pressed", Steam, "activateGameOverlayToWebPage", [STEAM_URL])
	$"%TwitterButton".connect("pressed", Steam, "activateGameOverlayToWebPage", [TWITTER_URL])
	$"%TikTokButton".connect("pressed", Steam, "activateGameOverlayToWebPage", [TIKTOK_URL])
	$"%ItchButton".connect("pressed", Steam, "activateGameOverlayToWebPage", [ITCH_URL])
	$"%ResetZoomButton".connect("pressed", self, "_on_reset_zoom_pressed")
	Network.connect("player_turns_synced", self, "on_player_actionable")
	Network.connect("player_turn_ready", self, "_on_player_turn_ready")
	Network.connect("turn_ready", self, "_on_turn_ready")
	Network.connect("sync_timer_request", self, "_on_sync_timer_request")
	Network.connect("check_players_ready", self, "check_players_ready")
	Network.connect("force_open_action_buttons", self, "on_player_actionable")
	
	if should_open_mod_warning_window():
		# Consume the flag so the warning shows once per launch, not on every
		# scene reload. ModLoader._init (autoload) sets it once and never clears
		# it, but UILayer._ready re-runs on each Global.reload(), so without this
		# the window reappears every time the main scene reloads.
		Global.mods_disabled_by_version_transition = false
		$"%ModWarningWindow".start()

	SteamLobby.connect("join_lobby_success", self, "_on_join_lobby_success")
	$"%OptionsContainer".hide()
	update_help_text()
	Hotkeys.connect("binding_changed", self, "_on_hotkey_changed")
	p1_turn_timer.connect("timeout", self, "_on_turn_timer_timeout", [1])
	p2_turn_timer.connect("timeout", self, "_on_turn_timer_timeout", [2])
	for lobby in [$"%Lobby", $"%DirectConnectLobby", SteamLobby]:
		lobby.connect("quit_on_rematch", $"%RematchButton", "hide")
		lobby.connect("quit_on_rematch", self, "set", ["quit_on_rematch", true])
	$"%HelpButton".connect("pressed", self, "toggle_help_screen")
	$"%OptionsBackButton".connect("pressed", $"%OptionsContainer", "hide")
	$"%OptionsButton".connect("pressed", $"%OptionsContainer", "show")
	$"%CreditsButton".connect("pressed", $"%Credits", "show")
	$"%CreditsButton".connect("pressed", $"%MainMenu", "hide")
	$"%PauseOptionsButton".connect("pressed", $"%OptionsContainer", "show")
	$"%MusicButton".set_pressed_no_signal(Global.music_enabled)
	$"%MusicButton".connect("toggled", self, "_on_music_button_toggled")
	$"%MasterSlider".set_value(Global.master_value)
	AudioServer.set_bus_volume_db(0, linear2db(Global.master_value))
	$"%MasterSlider".connect("value_changed", self, "_on_master_slider_changed")
	$"%FXSlider".set_value(Global.fx_value)
	AudioServer.set_bus_volume_db(1, linear2db(Global.fx_value))
	$"%FXSlider".connect("value_changed", self, "_on_fx_slider_changed")
	$"%UISlider".set_value(Global.ui_value)
	AudioServer.set_bus_volume_db(2, linear2db(Global.ui_value))
	$"%UISlider".connect("value_changed", self, "_on_ui_slider_changed")
	$"%MusicSlider".set_value(Global.music_value)
	AudioServer.set_bus_volume_db(3, linear2db(Global.music_value))
	$"%MusicSlider".connect("value_changed", self, "_on_music_slider_changed")
	# Personalization tab wiring. Block signals while seeding initial values
	# so the loaded state doesn't get re-saved as a fresh customization (and
	# so name_color_customized stays false for fresh installs).
	$"%CustomName".text = Global.custom_name
	$"%CustomName".connect("text_changed", self, "_on_custom_name_changed")
	$"%CustomNameReset".connect("pressed", self, "_on_custom_name_reset_pressed")
	$"%NameHueSlider".set_block_signals(true)
	$"%NameHueSlider".set_value(Global.name_hue)
	$"%NameHueSlider".set_block_signals(false)
	$"%NameHueSlider".connect("value_changed", self, "_on_name_hue_changed")
	$"%NameSaturationSlider".set_block_signals(true)
	$"%NameSaturationSlider".set_value(Global.name_saturation)
	$"%NameSaturationSlider".set_block_signals(false)
	$"%NameSaturationSlider".connect("value_changed", self, "_on_name_saturation_changed")
	$"%NameColorReset".connect("pressed", self, "_on_name_color_reset_pressed")
	# Slider value_changed fires per pixel-step while dragging, so saving +
	# publishing on every emit floods Steam lobby data with RPCs during a
	# drag. Debounce: restart this timer on each change, only persist + push
	# after the user has settled.
	_name_color_publish_timer = Timer.new()
	_name_color_publish_timer.wait_time = 0.25
	_name_color_publish_timer.one_shot = true
	_name_color_publish_timer.connect("timeout", self, "_on_name_color_publish_due")
	add_child(_name_color_publish_timer)
	_refresh_name_color_preview()
#	$"%LightModeButton".set_pressed_no_signal(Global.light_mode)
#	$"%LightModeButton".connect("toggled", self, "_on_light_mode_toggled")
	$"%FullscreenButton".set_pressed_no_signal(Global.fullscreen)
	$"%FullscreenButton".connect("toggled", self, "_on_fullscreen_button_toggled")
	$"%HitboxesButton".set_pressed_no_signal(Global.show_hitboxes)
	$"%HitboxesButton".connect("toggled", self, "_on_hitboxes_button_toggled")
	$"%CapFramerateButton".set_pressed_no_signal(Global.cap_framerate)
	$"%CapFramerateButton".connect("toggled", self, "_on_cap_framerate_button_toggled")
	$"%VsyncButton".set_pressed_no_signal(Global.vsync)
	$"%VsyncButton".connect("toggled", self, "_on_vsync_button_toggled")
	$"%PlaybackControls".set_pressed_no_signal(Global.show_playback_controls)
	$"%PlaybackControls".connect("toggled", self, "_on_playback_controls_button_toggled")
	$"%PredictionSettingsOpenButton".connect("pressed", self, "_on_open_prediction_settings_pressed")
	$"%PredictionSettingsCloseButton".connect("pressed", self, "_on_close_prediction_settings_pressed")
#	$"%BGColor".color = dark_mode_color
#	if Global.light_mode:
#		$"%BGColor".color = light_mode_color
	if !SteamHustle.STARTED:
		pass
#		$"%SteamMultiplayerButton".hide()
#		$"%WishlistButton".show()
#		$"%RoadmapContainer".hide()
#		$"%CustomizeButton".hide()
#		$"%SteamBetaReplayTip".hide()
#		$"%CustomizeButton".hide()
#		$"%EnableStyleColorsButton".hide()
#		$"%EnableAurasButton".hide()
#		$"%EnableHitsparksButton".hide()
	else:
		$"%WishlistButton".hide()
		$"%RoadmapContainer".show()
#		$"%MultiplayerButton".text = "Multiplayer (Legacy)"
	
	$NetworkSyncTimer.connect("timeout", self, "_on_network_timer_timeout")
	quit_on_rematch = false
	for node in global_option_check_buttons:
		node.set_pressed_no_signal(Global.get(global_option_check_buttons[node]))
		node.connect("toggled", self, "_on_global_option_toggled", [global_option_check_buttons[node]])
	
	p1_action_buttons.connect("switch_hud_side", self, "switch_hud_side")
	p2_action_buttons.connect("switch_hud_side", self, "switch_hud_side")
	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)
	
	$"%HelpScreen".hide()
	if SteamLobby.LOBBY_ID != 0:
		yield(get_tree(), "idle_frame") 
#		yield(get_tree(), "idle_frame")
		_on_join_lobby_success()
	$"%CharacterSelect".connect("opened", self, "reset_ui")
#	$"CharacterSelect".connect("opened", self, "reset_ui")
	yield(get_tree(), "idle_frame")



func adjust_ui(is_mobile):
	if is_mobile:
		p2_side_container.visible = false
		p1_side_container.visible = true
	else:
		p1_side_container.visible = true
		p2_side_container.visible = true



func switch_hud_side():
	if Global.mobile_ui:
		p2_side_container.visible = false
		# above is to not overflow outside of the hud and cause everything to break
		p1_side_container.visible = not p1_side_container.visible
		p2_side_container.visible = not p1_side_container.visible # not a typo



func should_open_mod_warning_window():
	# Only show the warning when ModLoader._init force-disabled mods this
	# session because of a MOD_DISABLE_VERSIONS transition (first launch on
	# the version with an existing save). Used to inform the user that
	# their `Enable Mods` setting was flipped off.
	return Global.mods_disabled_by_version_transition

func _on_global_option_toggled(toggled, param):
	Global.save_option(toggled, param)

#func _on_light_mode_toggled(on):
#	Global.set_light_mode(on)
#	if Global.light_mode:
#		$"%BGColor".color = light_mode_color
#	else:
#		$"%BGColor".color = dark_mode_color

func on_workshop_uploader_clicked():
	hide_main_menu()
	$"%WorkshopMenu".init()
	$"%WorkshopMenu".show()

	
func _on_music_button_toggled(on):
	Global.set_music_enabled(on)
	Global.save_options()

func _on_master_slider_changed(value):
	AudioServer.set_bus_volume_db(0, linear2db(value))
	$"%OptionsSoundPlayer".bus = "Master"
	$"%OptionsSoundPlayer".stream = load("res://sound/ui/button_hover3.wav")
	$"%OptionsSoundPlayer".play()
	Global.master_value = value
	Global.save_options()

func _on_fx_slider_changed(value):
	AudioServer.set_bus_volume_db(1, linear2db(value))
	$"%OptionsSoundPlayer".bus = "Fx"
	$"%OptionsSoundPlayer".stream = load("res://sound/common/explosion2.wav")
	$"%OptionsSoundPlayer".play()
	Global.fx_value = value
	Global.save_options()

func _on_ui_slider_changed(value):
	AudioServer.set_bus_volume_db(2, linear2db(value))
	$"%OptionsSoundPlayer".bus = "UI"
	$"%OptionsSoundPlayer".stream = load("res://sound/ui/button_hover3.wav")
	$"%OptionsSoundPlayer".play()
	Global.ui_value = value
	Global.save_options()

func _on_music_slider_changed(value):
	AudioServer.set_bus_volume_db(3, linear2db(value))
	$"%OptionsSoundPlayer".bus = "UI"
	$"%OptionsSoundPlayer".stream = load("res://sound/ui/button_hover3.wav")
	$"%OptionsSoundPlayer".play()
	Global.music_value = value
	Global.save_options()

func _on_custom_name_changed(text):
	Global.custom_name = text
	# Legacy multiplayer pulls from Network.player_name when launching a
	# match; mirror the change so the user's chosen name applies without
	# them having to re-open the legacy lobby.
	if text != "":
		Network.player_name = text
	Global.save_options()

func _on_custom_name_reset_pressed():
	$"%CustomName".text = ""
	Global.custom_name = ""
	Global.save_options()

func _on_name_hue_changed(value):
	Global.name_hue = value
	Global.name_color_customized = true
	_refresh_name_color_preview()
	if _name_color_publish_timer:
		_name_color_publish_timer.start()

func _on_name_saturation_changed(value):
	Global.name_saturation = value
	Global.name_color_customized = true
	_refresh_name_color_preview()
	if _name_color_publish_timer:
		_name_color_publish_timer.start()

func _on_name_color_publish_due():
	Global.save_options()
	Global.publish_name_color()

func _on_name_color_reset_pressed():
	# Move the sliders back to their defaults AND unset the customization
	# flag — display sites then fall back to whatever default tint they
	# would have used pre-customization. Signal-block the slider writes so
	# they don't immediately re-set the flag.
	$"%NameHueSlider".set_block_signals(true)
	$"%NameHueSlider".set_value(0.0)
	$"%NameHueSlider".set_block_signals(false)
	$"%NameSaturationSlider".set_block_signals(true)
	$"%NameSaturationSlider".set_value(0.5)
	$"%NameSaturationSlider".set_block_signals(false)
	Global.name_hue = 0.0
	Global.name_saturation = 0.5
	Global.name_color_customized = false
	Global.save_options()
	Global.publish_name_color()
	_refresh_name_color_preview()

func _refresh_name_color_preview():
	# Preview always shows the Steam profile name — the legacy multiplayer
	# name field is just the override used outside of Steam multiplayer, not
	# what shows in Steam lobbies / matches where the color actually applies.
	var name_text = "preview"
	if SteamHustle.STARTED and SteamHustle.STEAM_ID:
		var steam_name = Steam.getFriendPersonaName(SteamHustle.STEAM_ID)
		if steam_name is String and steam_name != "":
			name_text = steam_name
	$"%NameColorPreview".text = name_text
	if Global.has_name_color():
		$"%NameColorPreview".add_color_override("font_color", Global.get_name_color())
	else:
		$"%NameColorPreview".remove_color_override("font_color")

func _on_fullscreen_button_toggled(on):
	Global.set_fullscreen(on)

func _on_hitboxes_button_toggled(on):
	Global.set_hitboxes(on)

func _on_cap_framerate_button_toggled(on):
	Global.set_cap_framerate(on)

func _on_vsync_button_toggled(on):
	Global.set_vsync(on)

func _on_playback_controls_button_toggled(on):
	Global.set_playback_controls(on)

func _on_open_prediction_settings_pressed():
	$"%PredictionSettingsOpenButton".hide()
	$"%OptionsBar".show()

func _on_close_prediction_settings_pressed():
	$"%PredictionSettingsOpenButton".show()
	$"%OptionsBar".hide()

func toggle_help_screen():
	$"%HelpScreen".visible = !$"%HelpScreen".visible

func _on_join_lobby_success():
	if is_instance_valid(Global.current_game):
		return
	$"%HudLayer".hide()
	$"%SteamLobbyList".hide()
	$"%SteamLobby".show()
	$"%GameUI".hide()
	hide_main_menu(true)
#	$"%MainMenu".hide()

func hide_main_menu(all=false):
	if all:
		$"%MainMenu".hide()
	else:
		$"%ButtonContainer".hide()
		$"%Title".hide()
		$"%RoadmapContainer".hide()

func _on_view_replays_button_pressed():
	load_replays()
	hide_main_menu()

func _on_forfeit_button_pressed():
	if is_instance_valid(game) and !game.game_finished:
		var player_id = Network.player_id
		game.get_player(player_id).on_action_selected("Forfeit", null, null)
		Network.forfeit()
		forfeit_pressed = true
		actionable = false
	$"%PausePanel".hide()

func _on_opponent_disconnected():
	if is_instance_valid(game) and !game.game_finished:
		game.get_player((game.my_id % 2) + 1).on_action_selected("Forfeit", null, null)
		Network.forfeit(true)
		print("opponent disconnected")
		forfeit_pressed = true
		actionable = false
	$"%PausePanel".hide()

func _on_customize_pressed():
	$"%MainMenu".hide()
	$"%CustomizationScreen".init()
	$"%CustomizationScreen".show()
	pass

func load_replays():
	$"%ReplayWindow".show()
	for child in $"%ReplayContainer".get_children():
		child.free()
	var replay_map = ReplayManager.load_replays($"%ShowAutosavedReplays".pressed, $"%ShowBackupReplays".pressed)
	var buttons = []
	for key in replay_map:
		var button = preload("res://ui/ReplayWindow/ReplayButton.tscn").instance()
		add_child(button)
		button.setup(replay_map, key)
		button.connect("pressed", self, "_on_replay_button_pressed", [button])
		buttons.append(button)
		remove_child(button)
	buttons.sort_custom(self, "sort_replays")
	for button in buttons:
		$"%ReplayContainer".add_child(button)
	# Apply the current search filter against names immediately — matchup data
	# fills in asynchronously below, so we refilter after each batch to pick up
	# matchup-based matches as they arrive.
	_apply_replay_filter()
	for i in range(len(buttons)):
		if !is_instance_valid(self):
			break
		if !$"%ReplayWindow".visible:
			break
		if !is_instance_valid(buttons[i]):
			break
		var button = buttons[i]
		button.show_data()
		if i % 10 == 0:
			yield(button, "data_updated")
			_apply_replay_filter()

func _on_reset_zoom_pressed():
	if is_instance_valid(game):
		game.reset_zoom()

func _set_prediction_speed(speed: int):
	var btn = get_node_or_null("%%%dSpeed" % speed)
	if btn:
		btn.emit_signal("pressed")

func set_turn_time(time, minutes=false):
#	print("setting turn time to " + str(time))
	p1_turn_time = time * (60 if minutes else 1)
	p2_turn_time = time * (60 if minutes else 1)
	turn_time = time * (60 if minutes else 1)
	p1_turn_timer.wait_time = p1_turn_time
	p2_turn_timer.wait_time = p2_turn_time

func sort_replays(a, b):
	return a.modified > b.modified

func _on_replay_search_changed(_text):
	_apply_replay_filter()

func _on_replay_filter_toggle_changed(_pressed):
	_apply_replay_filter()

func _apply_replay_filter():
	if !has_node("%ReplayContainer"):
		return
	var query = $"%ReplaySearchEdit".text if has_node("%ReplaySearchEdit") else ""
	query = query.strip_edges()
	# Compile the query as a regex too — if it parses, that's an additional
	# match path; substring still works either way so users don't need to know
	# regex to filter by name.
	var rx = null
	if query != "":
		var candidate = RegEx.new()
		if candidate.compile(query) == OK:
			rx = candidate
	var same_version_only = Global.replay_version_mode == "same"
	var no_missing = has_node("%NoMissingCharactersToggle") and $"%NoMissingCharactersToggle".pressed
	for child in $"%ReplayContainer".get_children():
		var name_text = ""
		var matchup_text = ""
		var btn = child.get_node_or_null("%Button")
		if btn:
			name_text = btn.text
		var matchup = child.get_node_or_null("%MatchupLabel")
		if matchup:
			matchup_text = matchup.text
		var visible_now = _replay_matches_query(name_text, matchup_text, query, rx)
		# Version + missing-character filters only kick in once show_data has
		# populated those fields. Buttons whose data hasn't loaded yet (empty
		# version) stay visible — they'll refilter on the next batch yield.
		if visible_now and same_version_only and child.get("version") != null and child.version != "":
			if child.version != Global.VERSION:
				visible_now = false
		if visible_now and no_missing and child.get("has_missing_character"):
			visible_now = false
		child.visible = visible_now
	_refresh_replay_button_colors()

func _replay_matches_query(name_text: String, matchup_text: String, query: String, rx) -> bool:
	if query == "":
		return true
	var haystack = name_text + "\n" + matchup_text
	if haystack.findn(query) != -1:
		return true
	if rx != null and rx.search(haystack) != null:
		return true
	return false

var _pending_missing_char_replay = null
var _pending_old_version_replay = null

const VERSION_MODE_COLORS = {
	"all": Color(1, 1, 1, 1),
	"warn": Color(1, 0.85, 0.2, 1),
	"same": Color(1, 0.4, 0.4, 1),
}

func _on_replay_button_pressed(replay_button):
	if !is_instance_valid(replay_button):
		return
	# Missing-character replays always confirm — game.gd::setup would fail
	# to load the character anyway, so we stop the cliff dive before it
	# happens. Old-version warning only kicks in for "warn" mode (which
	# leaves them visible); "same" mode already hides them so we never see
	# the click here.
	if replay_button.has_missing_character:
		_pending_missing_char_replay = replay_button.path
		if has_node("%MissingCharConfirmDialog"):
			$"%MissingCharConfirmDialog".show()
		return
	if Global.replay_version_mode == "warn" and replay_button.version != "" \
			and replay_button.version != Global.VERSION:
		_pending_old_version_replay = replay_button.path
		if has_node("%OldVersionConfirmDialog"):
			$"%OldVersionConfirmDialog".show()
		return
	_load_replay_from_button(replay_button.path)

func _on_missing_char_confirmed():
	var path = _pending_missing_char_replay
	_pending_missing_char_replay = null
	if has_node("%MissingCharConfirmDialog"):
		$"%MissingCharConfirmDialog".hide()
	if path != null:
		_load_replay_from_button(path)

func _on_missing_char_cancelled():
	_pending_missing_char_replay = null
	if has_node("%MissingCharConfirmDialog"):
		$"%MissingCharConfirmDialog".hide()

func _on_old_version_confirmed():
	var path = _pending_old_version_replay
	_pending_old_version_replay = null
	if has_node("%OldVersionConfirmDialog"):
		$"%OldVersionConfirmDialog".hide()
	if path != null:
		_load_replay_from_button(path)

func _on_old_version_cancelled():
	_pending_old_version_replay = null
	if has_node("%OldVersionConfirmDialog"):
		$"%OldVersionConfirmDialog".hide()

func _on_version_mode_pressed():
	# Cycle "all" → "warn" → "same" → "all" …
	var i = Global.REPLAY_VERSION_MODES.find(Global.replay_version_mode)
	i = posmod(i + 1, Global.REPLAY_VERSION_MODES.size())
	Global.replay_version_mode = Global.REPLAY_VERSION_MODES[i]
	Global.save_options()
	_refresh_version_mode_label()
	# "warn" tints non-current-version buttons yellow; "same" hides them;
	# "all" shows them with no decoration — refresh both the button colors
	# and the visibility filter.
	_refresh_replay_button_colors()
	_apply_replay_filter()

func _refresh_version_mode_label():
	if !has_node("%VersionModeLabel"):
		return
	var mode = Global.replay_version_mode
	var label = $"%VersionModeLabel"
	label.text = mode
	var col = VERSION_MODE_COLORS.get(mode, Color.white)
	label.add_color_override("font_color", col)

func _refresh_replay_button_colors():
	if !has_node("%ReplayContainer"):
		return
	for child in $"%ReplayContainer".get_children():
		# Modulate the whole row (VBoxContainer) so the inner Button, the
		# matchup label, and the version label all pick up the tint via
		# Godot's parent-modulate propagation.
		if child.has_missing_character:
			# Missing-char red always wins; that's a guaranteed-broken replay,
			# not just a version mismatch.
			child.modulate = Color(1, 0.45, 0.45)
		elif child.version != "" and child.version != Global.VERSION:
			# Always yellow for different-version replays, regardless of
			# whether the current mode happens to hide them. "same" mode
			# never shows them so it's a no-op there; "all"/"warn" both get
			# the visual cue.
			child.modulate = VERSION_MODE_COLORS["warn"]
		else:
			child.modulate = Color(1, 1, 1, 1)

func _load_replay_from_button(path):
	var match_data = ReplayManager.load_replay(path)
	$"%ReplayWindow".hide()
	if replay_picker_for_challenge:
		replay_picker_for_challenge = false
		$"%ReplayChallengeTitle".hide()
		$"%SteamLobby".show()
		emit_signal("replay_picked_for_challenge", match_data, path)
		return
	emit_signal("loaded_replay", match_data)

func _on_replay_cancel_pressed():
	if replay_picker_for_challenge:
		replay_picker_for_challenge = false
		$"%ReplayWindow".hide()
		$"%ReplayChallengeTitle".hide()
		$"%SteamLobby".show()
		return
	Global.reload()

func open_replay_picker_for_challenge(opponent_name=""):
	replay_picker_for_challenge = true
	if opponent_name == "":
		$"%ReplayChallengeTitle".text = "Select a replay to resume with"
	else:
		$"%ReplayChallengeTitle".text = "Select a replay to resume with " + opponent_name
	$"%ReplayChallengeTitle".show()
	$"%SteamLobby".hide()
	load_replays()

#func _notification(what):
#	if (what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST):
#		pass
#		if will_forfeit():
#			_on_forfeit_button_pressed()
#			yield(get_tree().create_timer(2.0), "timeout")
#			get_tree().quit()
#		elif can_quit():
#			print ("You are quit!")
#			get_tree().quit() # default behavior

func will_forfeit():
	return !SteamLobby.SPECTATING and Network.multiplayer_active and is_instance_valid(game) and !game.game_finished and !game.forfeit and !ReplayManager.playback and !forfeit_pressed

func can_quit():
	return true
#	return !(is_instance_valid(game) and game.forfeit and !ReplayManager.playback and Network.forfeiter == Network.player_id)

func reset_ui():
	$"%HudLayer".hide()
	p1_turn_timer.stop()
	p2_turn_timer.stop()
	$"%P1TurnTimerBar".hide()
	$"%P1TurnTimerLabel".hide() 
	$"%P2TurnTimerBar".hide()
	$"%P2TurnTimerLabel".hide()
	$"%GameUI".hide()
	$"%ChatWindow".hide()
	$"%PostGameButtons".hide()
	$"%OpponentDisconnectedLabel".hide()
	forfeit_pressed = false
	actionable = false

func _on_quit_button_pressed():
	if will_forfeit():
		_on_forfeit_button_pressed()
	else:
		if can_quit():
			if !Network.steam:
				Network.stop_multiplayer()
				Global.reload()
			else:
				SteamLobby.exit_match_from_button()

func _on_quit_program_button_pressed():
	get_tree().quit()

func _on_sync_timer_request(id, time):
	if !chess_timer:
		return
	# sync_timer is only fired from end_turn_for — it's always a lock-in
	# event. Pause the receiving timer immediately so it doesn't keep ticking
	# in the gap between this RPC and the player_turn_ready signal that
	# would have paused it. Without this, spectators/opponents would briefly
	# see the bank tick down past the lock-in value (which the host froze on
	# their side), and increment-mode turn-start computations would diverge.
	if id == 1:
		p1_turn_timer.start(time)
		p1_turn_timer.paused = true
		# Explicitly update the label here — increment-mode _process freezes
		# the label while the timer is paused, so without this the label
		# stays at whatever local-time-tick value was rendered just before
		# the sync arrived (typically a few seconds behind host).
		if has_node("%P1TurnTimerLabel"):
			$"%P1TurnTimerLabel".text = time_convert(int(floor(time)))
		received_synced_time = true
		emit_signal("received_synced_time")
	elif id == 2:
		p2_turn_timer.start(time)
		p2_turn_timer.paused = true
		if has_node("%P2TurnTimerLabel"):
			$"%P2TurnTimerLabel".text = time_convert(int(floor(time)))
		received_synced_time = true
		emit_signal("received_synced_time")

func get_chess_timer_state():
	if !chess_timer:
		return null
	return {
		"p1_time_left": p1_turn_timer.time_left,
		"p2_time_left": p2_turn_timer.time_left,
		"turn_time": turn_time,
		"p1_debt": p1_debt,
		"p2_debt": p2_debt,
		"p1_just_ran_out": p1_just_ran_out,
		"p2_just_ran_out": p2_just_ran_out,
	}

func restore_chess_timer_state(state):
	if !state or !chess_timer:
		return
	# Seed each player's bank with their remaining time from the saved replay and
	# keep it FROZEN. This only runs on a replay-challenge resume, which is
	# immediately followed by the catch-up playback — the clock must not tick
	# until live control hands over (on_player_actionable unpauses it then).
	if state.has("p1_time_left"):
		p1_turn_timer.start(state.p1_time_left)
		p1_turn_timer.paused = true
	if state.has("p2_time_left"):
		p2_turn_timer.start(state.p2_time_left)
		p2_turn_timer.paused = true
	# Old replays predate debt tracking; default to 0 so they restore cleanly.
	p1_debt = float(state.get("p1_debt", 0))
	p2_debt = float(state.get("p2_debt", 0))
	p1_just_ran_out = bool(state.get("p1_just_ran_out", false))
	p2_just_ran_out = bool(state.get("p2_just_ran_out", false))
	# Mark the clock as already underway. Without this, game_started is still
	# false at the first live turn, so on_player_actionable takes the
	# `!game_started` branch and calls a bare start() — which re-arms the timer
	# to wait_time (the FULL per-player bank) and wipes the remainder we just
	# restored, handing both players a fresh full clock ("30 min of fluff").
	# Forcing it true routes that first turn through the per-turn `else` branch,
	# which preserves the restored bank.
	game_started = true
	# The skipped !game_started branch is also where MIN_TURN_TIME (low-time
	# threshold + chess refresh floor) gets seeded, so seed it here instead.
	if is_instance_valid(game) and game.match_data:
		if timer_mode == "chess":
			MIN_TURN_TIME = game.match_data.get("turn_min_length", MIN_TURN_TIME)
		elif timer_mode == "increment":
			MIN_TURN_TIME = game.match_data.get("increment_per_turn", 0)

func sync_timer(player_id):
	if Network.multiplayer_active:
		if player_id == Network.player_id:
			print("syncing timer")
			var timer = p1_turn_timer
			if player_id == 2:
				timer = p2_turn_timer
			Network.sync_timer(player_id, timer.time_left)


func id_to_action_buttons(player_id):
	if player_id == 1:
		return $"%P1ActionButtons"
	else:
		return $"%P2ActionButtons"

func init(game):
	forfeit_pressed = false
	if !ReplayManager.playback:
		$PostGameButtons.hide()
		$"%RematchButton".disabled = false
	self.game = game
	setup_action_buttons()
	if Network.multiplayer_active or SteamLobby.SPECTATING:
		game.connect("playback_requested", self, "_on_game_playback_requested")
		$"%ChatWindow".show()
	game_started = false
	timer_mode = game.match_data.get("timer_mode", "default")
	# Show timer UI only when there's actually a timer running. "none" hides
	# the labels entirely so the screen stays clean for untimed matches.
	var show_timer = (Network.multiplayer_active or SteamLobby.SPECTATING) and timer_mode != "none"
	$"%P1TurnTimerLabel".visible = show_timer
	$"%P2TurnTimerLabel".visible = show_timer
	# Persistent-bank modes carry timer state across turns and need
	# save/restore. "default" is per-turn (no persistence) and "none" has no
	# timer at all, so neither participates in chess_timer_state.
	chess_timer = timer_mode == "chess" or timer_mode == "increment"
	p1_debt = 0.0
	p2_debt = 0.0
	p1_just_ran_out = false
	p2_just_ran_out = false
	# Clear stale snapshot from any previous match — _process will repopulate
	# this every frame while chess_timer is on. Non-chess-timer matches leave
	# it null so saves don't bake in inapplicable state.
	ReplayManager.chess_timer_state = null
	timer_sync_tick = -1
	lock_in_tick = -INF
	p1_time_run_out = false
	p2_time_run_out = false

func _on_player_turn_ready(player_id):
	if !is_instance_valid(game):
		return
	lock_in_tick = game.current_tick
	if player_id != Network.player_id or SteamLobby.SPECTATING:
		$"%TurnReadySound".play()

	turns_taken[player_id] = true
	if player_id == 1:
		$"%P1TurnTimerBar".hide()
#		p1_turn_timer.stop()
		p1_turn_timer.paused = true

	elif player_id == 2:
		$"%P2TurnTimerBar".hide()
#		p2_turn_timer.stop()
		p2_turn_timer.paused = true
	
func _on_rematch_button_pressed():
	Network.request_rematch()
	$"%RematchButton".disabled = true

func _on_game_playback_requested():
	if Network.multiplayer_active and !ReplayManager.resimulating:
		$PostGameButtons.show()
		# A spectated match still shows the post-game menu so the viewer can
		# Quit — but they were never a participant, so no Rematch for them.
		# Gate on game.spectating, NOT SteamLobby.SPECTATING: the latter is
		# cleared the instant the watched player leaves "fighting" (the
		# spectator poll calls end_spectate), which is exactly when this fires,
		# so it already reads false here. game.spectating is the per-match flag
		# and survives. Hide explicitly since the button defaults to visible.
		if !quit_on_rematch and !SteamLobby.SPECTATING and !(is_instance_valid(game) and game.spectating):
			$"%RematchButton".show()
		else:
			$"%RematchButton".hide()
		Network.rematch_menu = true

func on_game_started():
	lobby.hide()
	$"%SteamLobby".hide()
	$MainMenu.hide()

func _on_singleplayer_pressed():
	Global.frame_advance = false
	SteamLobby.leave_Lobby()
	emit_signal("singleplayer_started")

func _on_direct_connect_button_pressed():
	direct_connect_lobby.show()
	hide_main_menu()

func _on_multiplayer_pressed():
	SteamLobby.leave_Lobby()
	lobby.show()
	hide_main_menu()
	
func _on_steam_multiplayer_pressed():
	$"%SteamLobbyList".show()
	hide_main_menu()
	

func _on_turn_ready():
	$"%P1TurnTimerBar".hide()
	$"%P2TurnTimerBar".hide()
	actionable = false
#	p1_turn_timer.stop()
#	p2_turn_timer.stop()
	
	var turns_taken = {
		1: false,
		2: false
	}


func open_replay_folder():
	var folder = ProjectSettings.globalize_path("user://replay")
	OS.shell_open(folder)

func end_turn_for(player_id):
	$"%TurnReadySound".play()
	turns_taken[player_id] = true
	if player_id == Network.player_id:
		sync_timer(player_id)
	if player_id == 1:
		$"%P1TurnTimerBar".hide()
#		p1_turn_timer.stop()
		p1_turn_timer.paused = true

	elif player_id == 2:
		$"%P2TurnTimerBar".hide()
#		p2_turn_timer.stop()
		p2_turn_timer.paused = true
	if Network.rematch_menu:
		hide_rematch_menu()

func setup_action_buttons():
	$"%P1ActionButtons".init(game, 1)
	$"%P2ActionButtons".init(game, 2)
	
func check_players_ready():
	if is_instance_valid(game):
		if game.is_waiting_on_player():
			if lock_in_tick != game.current_tick:
				on_player_actionable()

func _on_network_timer_timeout():
	if Network.multiplayer_active:
		if !Network.turn_synced:
			if is_instance_valid(game):
				if game.player_actionable and lock_in_tick != game.current_tick and !actionable:
					Network.rpc_("check_players_ready")

func on_player_actionable():
	if actionable and (Network.multiplayer_active and !Network.undo and !Network.auto):
		return
	while is_instance_valid(game) and !game.game_paused:
		yield(get_tree(), "idle_frame")
	Network.undo = false
	Network.auto = false
	actionable = true
	actionable_time = 0
#	yield(Network, "both_players_actionable")
#	if p1_turn_timer.wait_time == 0:
#		p1_turn_timer.wait_time = MIN_TURN_TIME
#	if p2_turn_timer.wait_time == 0:
#		 p2_turn_timer.wait_time = MIN_TURN_TIME
	if Network.multiplayer_active or SteamLobby.SPECTATING:
#		Network.rpc_("my_turn_started")
		var wait_start = OS.get_ticks_msec()
		while !(Network.can_open_action_buttons):
			if OS.get_ticks_msec() - wait_start > 3000 and !SteamLobby.SPECTATING:
				print("button-open watchdog: stuck waiting >3s, resending end_turn_simulation")
				if is_instance_valid(game):
					Network.rpc_("end_turn_simulation", [game.current_tick, Network.player_id])
				wait_start = OS.get_ticks_msec()
			yield(get_tree(), "physics_frame")

		print("starting turn timer")
#		if $"%P1ActionButtons".any_available_actions and $"%P2ActionButtons".any_available_actions:
		if timer_mode == "none":
			# No timer mode: skip all timer setup entirely.
			pass
		elif !game_started:
#		if p1_turn_timer.is_stopped():
			if is_instance_valid(game):
				# MIN_TURN_TIME doubles as the "low time" warning threshold
				# for the bar flash + outta-time sound. Chess pulls it from
				# turn_min_length; increment uses the increment itself (= one
				# turn's worth of time, so the warning fires when you've used
				# this turn's increment).
				if timer_mode == "chess":
					MIN_TURN_TIME = game.match_data.turn_min_length
				elif timer_mode == "increment":
					MIN_TURN_TIME = game.match_data.get("increment_per_turn", 0)
			p1_turn_timer.start()
			p2_turn_timer.start()
			game_started = true
		else:
			if timer_mode == "default":
				p1_turn_timer.start(turn_time)
				p2_turn_timer.start(turn_time)
			elif timer_mode == "increment":
				_apply_increment(1)
				_apply_increment(2)
				# Increment mode: each turn's bank can re-cross MIN_TURN_TIME,
				# so re-arm the low-time warning sound. Without this the
				# `p1_time_run_out` gate latches after the first turn's
				# warning and never plays again.
				p1_time_run_out = false
				p2_time_run_out = false
			else:
				if p1_turn_timer.time_left < MIN_TURN_TIME:
					p1_turn_timer.start(MIN_TURN_TIME)
				if p2_turn_timer.time_left < MIN_TURN_TIME:
					p2_turn_timer.start(MIN_TURN_TIME)


		if timer_mode != "none":
			p1_turn_timer.paused = false
			p2_turn_timer.paused = false
#		if game.current_tick != timer_sync_tick:
#			timer_sync_tick = game.current_tick
#			sync_timer(Network.player_id)
#			if !received_synced_time:
#				yield(self, "received_synced_time")
#				received_synced_time = false
		# Show the bars even in None mode — value stays at the default 1.0 so
		# they render as a full circle, and end_turn_for hides them on lock-in.
		# That gives spectators a "still thinking" indicator without showing
		# countdown text.
		$"%P1TurnTimerBar".show()
		$"%P2TurnTimerBar".show()

#	$"%P1SuperContainer".rect_min_size.y = 40
#	$"%P2SuperContainer".rect_min_size.y = 40
	$"%P1ActionButtons".activate()
	$"%P2ActionButtons".activate()
	if is_instance_valid(game):
		game.is_in_replay = false
	$"%AdvantageLabel".text = ""

#		else:
#			turn_timer.start(turn_time)

func _on_turn_timer_timeout(player_id):
		# Increment mode: bank ran out. Add a full increment to debt, reset
		# the bank to increment so the player keeps a non-zero clock, set the
		# just_ran_out flag so end_turn_for skips pay-debt and the next turn
		# skips +increment, then auto-lock like default mode.
		if timer_mode == "increment":
			var inc = float(game.match_data.get("increment_per_turn", 0))
			if player_id == 1:
				p1_debt += inc
				p1_just_ran_out = true
				p1_turn_timer.start(inc)
				if Network.player_id == player_id:
					$"%P1ActionButtons".timeout()
			else:
				p2_debt += inc
				p2_just_ran_out = true
				p2_turn_timer.start(inc)
				if Network.player_id == player_id:
					$"%P2ActionButtons".timeout()
			return
		if player_id == 1:
			if Network.player_id == player_id:
				$"%P1ActionButtons".timeout()
				p1_turn_timer.wait_time = MIN_TURN_TIME
				p1_turn_timer.start()
				p1_turn_timer.paused = true
		else:
			if Network.player_id == player_id:
				$"%P2ActionButtons".timeout()
				p2_turn_timer.wait_time = MIN_TURN_TIME
				p2_turn_timer.start()
				p2_turn_timer.paused = true

# Apply per-turn increment AND pay debt at the start of the player's turn.
# Done together at turn start (instead of pay-debt at lock-in) so:
#   1) the label between turns shows the player's actual lock-in bank, not
#      the post-pay-debt remainder (which flashes a confusingly-small value)
#   2) spectator + host stay in sync — both run this on the same network-
#      synced bank value at turn start, so debt and bank end up matching
#      regardless of who computed what at lock-in
# Order:
#   - !just_ran_out + debt > 0: pay debt with leftover bank, deduct from both
#   - debt > 0 (still): reset bank to increment ("in debt → no growth")
#   - debt == 0: bank += increment (normal Fischer increment)
#   - just_ran_out: clear the flag, skip the pay-debt step (the run-out is
#     the punishment — you don't immediately pay off the debt you just took)
func _apply_increment(player_id):
	if !is_instance_valid(game) or !game.match_data:
		return
	var inc = float(game.match_data.get("increment_per_turn", 0))
	var timer = p1_turn_timer if player_id == 1 else p2_turn_timer
	var bank = timer.time_left
	if player_id == 1:
		if !p1_just_ran_out and p1_debt > 0:
			var paid = min(bank, p1_debt)
			p1_debt -= paid
			bank -= paid
		p1_just_ran_out = false
	else:
		if !p2_just_ran_out and p2_debt > 0:
			var paid = min(bank, p2_debt)
			p2_debt -= paid
			bank -= paid
		p2_just_ran_out = false
	var debt = p1_debt if player_id == 1 else p2_debt
	if debt > 0:
		bank = inc
	else:
		bank = bank + inc
	# Hard cap on accumulated bank. Setting stored in minutes for the panel,
	# applied in seconds here. 0 means uncapped (the default).
	var max_minutes = float(game.match_data.get("increment_max_time", 0))
	if max_minutes > 0:
		var max_sec = max_minutes * 60.0
		if bank > max_sec:
			bank = max_sec
	timer.start(bank)
func pause():
	$"%PausePanel".visible = !$"%PausePanel".visible
	if $"%PausePanel".visible:
		if will_forfeit():
			$"%QuitToMainMenuButton".hide()
			$"%ForfeitButton".show()
		else:
			$"%QuitToMainMenuButton".show()
			$"%ForfeitButton".hide()
		$"%SaveReplayButton".disabled = false
		$"%SaveReplayButton".text = "save replay"
		$"%SaveReplayLabel".text = ""

func _on_hotkey_changed(_action):
	update_help_text()

func update_help_text():
	$"%TopInfo".text = _format_help([
		[Hotkeys.LOCK_IN, "Lock in"],
		[Hotkeys.WATCH_REPLAY, "Watch replay"],
		[Hotkeys.PAUSE, "Open menu"],
		[Hotkeys.TOGGLE_HUD, "Toggle HUD"],
	])
	$"%TopInfoMP".text = _format_help([
		[Hotkeys.LOCK_IN, "Lock in"],
		[Hotkeys.PAUSE, "Open menu"],
		[Hotkeys.OPEN_CHAT, "Chat"],
		[Hotkeys.TOGGLE_HUD, "Toggle HUD"],
	])
	$"%TopInfoReplay".text = _format_help([
		[Hotkeys.WATCH_REPLAY, "Watch replay"],
		[Hotkeys.EDIT_REPLAY, "Edit replay"],
		[Hotkeys.PAUSE, "Open menu"],
		[Hotkeys.TOGGLE_HUD, "Toggle HUD"],
	])

func _format_help(entries: Array) -> String:
	var parts = []
	for entry in entries:
		var key_name = Hotkeys.get_display_name(entry[0])
		if key_name == "":
			continue
		parts.append("%s: %s" % [key_name, entry[1]])
	return PoolStringArray(parts).join(" - ")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		if $"%OptionsContainer".visible:
			$"%OptionsContainer".hide()
			get_tree().set_input_as_handled()
			return
	if event.is_action_pressed(Hotkeys.OPEN_CHAT):
		if is_instance_valid(game):
			$"%ChatWindow".show()
			$"%ChatWindow".line_edit_focus()
	if event.is_action_pressed(Hotkeys.TOGGLE_HUD):
		visible = !visible
		$"../HudLayer/HudLayer".visible = ! $"../HudLayer/HudLayer".visible
		$"../GhostLayer".visible = visible
		Global.ui_hidden = !visible
	if event.is_action_pressed(Hotkeys.TOGGLE_FREE_CANCEL):
		_toggle_free_cancel()
	if event.is_action_pressed(Hotkeys.TOGGLE_FLIP):
		_toggle_flip()
	if event.is_action_pressed(Hotkeys.TOGGLE_PREDICTION):
		_toggle_prediction()
	if event.is_action_pressed(Hotkeys.TOGGLE_HITBOXES):
		_toggle_hitboxes()
	if event.is_action_pressed(Hotkeys.CLEAR_PARTICLES):
		_on_ClearParticlesButton_pressed()
	if event.is_action_pressed(Hotkeys.TOGGLE_PLAYBACK_CONTROLS):
		_toggle_playback_controls()
	# Pause / frame-advance are button shortcuts on the playback window, so they
	# only fire while it's open. When the user has turned off "playback hotkeys
	# require window", handle them here too — but only while the window is
	# closed, otherwise the button shortcut also fires and we'd double-toggle.
	if not Global.playback_hotkeys_require_window and not $"%ReplayControls".visible:
		if event.is_action_pressed(Hotkeys.TOGGLE_FRAME_ADVANCE):
			$"%ReplayControls".toggle_frame_advance()
		if event.is_action_pressed(Hotkeys.FRAME_ADVANCE):
			$"%ReplayControls".frame_advance_step()
	if event.is_action_pressed(Hotkeys.TOGGLE_PROJECTILE_OWNERS):
		_toggle_projectile_owners()
	if event.is_action_pressed(Hotkeys.TOGGLE_FULLSCREEN):
		_toggle_fullscreen()
	if event.is_action_pressed(Hotkeys.PLAYBACK_SPEED_1):
		_set_playback_speed(4)
	if event.is_action_pressed(Hotkeys.PLAYBACK_SPEED_2):
		_set_playback_speed(2)
	if event.is_action_pressed(Hotkeys.PLAYBACK_SPEED_3):
		_set_playback_speed(-1)
	if event.is_action_pressed(Hotkeys.PLAYBACK_SPEED_4):
		_set_playback_speed(1)
	if event.is_action_pressed(Hotkeys.RESET_ZOOM):
		_on_reset_zoom_pressed()
	if event.is_action_pressed(Hotkeys.ZOOM_IN):
		if is_instance_valid(game):
			game.zoom_in()
	if event.is_action_pressed(Hotkeys.ZOOM_OUT):
		if is_instance_valid(game):
			game.zoom_out()
	if event.is_action_pressed(Hotkeys.FREEZE_ON_READY):
		_toggle_freeze_on_ready()
	if event.is_action_pressed(Hotkeys.TOGGLE_AFTERIMAGES):
		_toggle_afterimage()
	if event.is_action_pressed(Hotkeys.TOGGLE_FREEZE_SOUND):
		_toggle_global_button("%FreezeSound")
	if event.is_action_pressed(Hotkeys.TOGGLE_EXTRA_INFO):
		_toggle_global_button("%ExtraInfoButton")
	if event.is_action_pressed(Hotkeys.UNDO):
		_trigger_undo()
	if event.is_action_pressed(Hotkeys.PREDICTION_SPEED_1):
		_set_prediction_speed(1)
	if event.is_action_pressed(Hotkeys.PREDICTION_SPEED_HALF):
		_set_prediction_speed(5)
	if event.is_action_pressed(Hotkeys.PREDICTION_SPEED_2):
		_set_prediction_speed(2)
	if event.is_action_pressed(Hotkeys.PREDICTION_SPEED_3):
		_set_prediction_speed(3)
	_handle_xy_nudge(event)
#			if !Network.multiplayer_active:
#				if is_instance_valid(game) and $"%ReplayControls".visible:
#					if event.scancode == KEY_P:
#						Global.frame_advance = !Global.frame_advance
#					if event.scancode == KEY_F:
#						game.advance_frame_input = true
#			if event.scancode == KEY_SPACE:
#				p1_action_buttons.space_pressed()
#				p2_action_buttons.space_pressed()
	if event is InputEventMouseButton:
		if event.pressed:
			$"%ChatWindow".unfocus_line_edit()

func time_convert(time_in_sec):
	var seconds = time_in_sec%60
	var minutes = (time_in_sec/60)%60
	var hours = (time_in_sec/60)/60

	#returns a string with the format "HH:MM:SS"
	if hours >= 1:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]

func hide_rematch_menu():
	Network.rematch_menu = false
	var post_game_buttons = get_node_or_null("%PostGameButtons")
	var disconnected_label = get_node_or_null("%OpponentDisconnectedLabel")
	if post_game_buttons:
		post_game_buttons.hide()
	if disconnected_label:
		disconnected_label.hide()

func _process(delta):
	# Freeze the turn clocks while a replay is catching up (replay challenge /
	# backup resume). During playback the recorded inputs drive the match and the
	# players aren't on the clock yet — letting the real-time Timer nodes tick
	# here would drain a player's bank through the whole catch-up and can even
	# time a phantom turn out before live play resumes. `resimulating` is the
	# fast rollback resync during live play (not a watched catch-up), so it's
	# excluded — same split as game.gd's is_in_replay.
	if timer_mode != "none" and ReplayManager.playback and not ReplayManager.resimulating:
		p1_turn_timer.paused = true
		p2_turn_timer.paused = true

	if chess_timer and is_instance_valid(game) and game.match_data:
		var state = {
			"p1_time_left": p1_turn_timer.time_left,
			"p2_time_left": p2_turn_timer.time_left,
			"turn_time": turn_time,
			"p1_debt": p1_debt,
			"p2_debt": p2_debt,
			"p1_just_ran_out": p1_just_ran_out,
			"p2_just_ran_out": p2_just_ran_out,
		}
		game.match_data["chess_timer_state"] = state
		# Mirror to ReplayManager so save-replay paths that don't share the
		# match_data dict reference (e.g. autosave from Network.gd) still bake
		# in a fresh snapshot. Spectators publish too — they're the ones most
		# likely to be the "live witness" feeding a replay challenge later.
		ReplayManager.chess_timer_state = state

	# Increment mode: freeze the label between turns. Once a player locks in,
	# the timer is paused and the displayed value should stay at whatever it
	# read at lock-in until the next turn's _apply_increment kicks the timer
	# again. Without this, host/spectator timing differences in the
	# sync-then-pause window would briefly show the bank ticking past the
	# lock-in value, which the user reads as "wrong by a few seconds".
	var p1_old_text = $"%P1TurnTimerLabel".text
	if !(timer_mode == "increment" and p1_turn_timer.is_paused()):
		$"%P1TurnTimerLabel".text = time_convert(int(floor(p1_turn_timer.time_left)))
	var p1_different_text = p1_old_text != $"%P1TurnTimerLabel".text

	var p2_old_text = $"%P2TurnTimerLabel".text
	if !(timer_mode == "increment" and p2_turn_timer.is_paused()):
		$"%P2TurnTimerLabel".text = time_convert(int(floor(p2_turn_timer.time_left)))
	var p2_different_text = p2_old_text != $"%P2TurnTimerLabel".text

	# Debt indicator: only meaningful in increment mode, shown red below the
	# main timer when the player has owed time. Hidden otherwise so chess and
	# untimed matches stay clean.
	var p1_debt_label = $"%P1TurnDebtLabel"
	var p2_debt_label = $"%P2TurnDebtLabel"
	if timer_mode == "increment" and $"%P1TurnTimerLabel".visible:
		p1_debt_label.visible = p1_debt > 0
		if p1_debt > 0:
			p1_debt_label.text = "-" + time_convert(int(ceil(p1_debt)))
		p2_debt_label.visible = p2_debt > 0
		if p2_debt > 0:
			p2_debt_label.text = "-" + time_convert(int(ceil(p2_debt)))
	else:
		p1_debt_label.visible = false
		p2_debt_label.visible = false

	if $"%VersionLabel".visible:
		$"%VersionLabel".text = "version " + Global.VERSION

	if Network.undo and Network.rematch_menu:
		hide_rematch_menu()

	var you_id = 1
	var opponent_id = 2
	if Network.multiplayer_active:
		you_id = Network.player_id
		opponent_id = (you_id % 2) + 1

	if is_instance_valid(game):
		# None mode: pin bar value at 1.0 so the bars stay full (= "still
		# thinking" indicator). The timer's never started, so is_paused() is
		# false (stopped != paused) and the normal update path below would
		# set bar.value = 0/turn_time = 0 — empty bar — which is wrong here.
		if timer_mode == "none":
			$"%P1TurnTimerBar".value = 1.0
			$"%P2TurnTimerBar".value = 1.0
		elif !p1_turn_timer.is_paused():
	#		if !turns_taken[1]:
				var bar = $"%P1TurnTimerBar"
				# Increment mode: each turn's starting bank is the timer's
				# current wait_time (timer.start(t) sets wait_time = t), so
				# the bar fills based on this turn's bank rather than the
				# fixed match-wide turn_time.
				var denom = p1_turn_timer.wait_time if timer_mode == "increment" else turn_time
				bar.value = p1_turn_timer.time_left / denom if denom > 0 else 1.0
				if p1_turn_timer.time_left < MIN_TURN_TIME:
					bar.visible = Utils.wave(-1, 1, 0.064) > 0
					if p1_different_text and you_id == 1 and p1_turn_timer.time_left:
						if Global.enable_timer_sound and (round(p1_turn_timer.time_left) == MIN_TURN_TIME):
							if !chess_timer or !p1_time_run_out:
								p1_time_run_out = true
								$"%P1OuttaTimeSound".play()
		if timer_mode != "none" and !p2_turn_timer.is_paused():
	#		if !turns_taken[2]:
				var bar = $"%P2TurnTimerBar"
				var denom = p2_turn_timer.wait_time if timer_mode == "increment" else turn_time
				bar.value = p2_turn_timer.time_left / denom if denom > 0 else 1.0
				if p2_turn_timer.time_left < MIN_TURN_TIME:
					bar.visible = Utils.wave(-1, 1, 0.064) > 0
					if p2_different_text and you_id == 2:
						if Global.enable_timer_sound and (round(p2_turn_timer.time_left) == MIN_TURN_TIME):
							if !chess_timer or !p2_time_run_out:
								p2_time_run_out = true
								$"%P2OuttaTimeSound".play()
#	if !is_instance_valid(game):
#		reset_ui()
#	else:
#		$"%HudLayer".show()

	if Input.is_action_just_pressed("pause"):
		pause()

	var advantage_label = $"%AdvantageLabel"
#	advantage_label.text = ""
	var ghost_game = get_parent().ghost_game
	if is_instance_valid(game):
		if game.game_paused:
			if is_instance_valid(ghost_game):
				var you = ghost_game.get_player(you_id)
				var opponent = ghost_game.get_player(opponent_id)
				
				var advantage = 0
				var block_advantage = 0
				
				block_advantage = -you.blocked_hitbox_plus_frames + opponent.blocked_hitbox_plus_frames

				if you.ghost_ready_tick != null and opponent.ghost_ready_tick != null:
					advantage = opponent.ghost_ready_tick - you.ghost_ready_tick

				if advantage >= 0:
					advantage_label.set("custom_colors/font_color", Color("1d8df5"))
					advantage_label.text = "frame advantage: +" + str(advantage)
				else:
					advantage_label.set("custom_colors/font_color", Color("ff333d"))
					advantage_label.text = "frame advantage: " + str(advantage)
				if advantage == 0:
					advantage_label.text = ""

				if block_advantage > 0:
					block_advantage_label.set("custom_colors/font_color", Color("94e4ff"))
					block_advantage_label.text = "block advantage: +" + str(block_advantage)
					
				elif block_advantage < 0:
					block_advantage_label.set("custom_colors/font_color", Color("ff7a81"))
					block_advantage_label.text = "block advantage: " + str(block_advantage)
				else:
					block_advantage_label.text = ""
					pass

		else:
			advantage_label.text = ""
			block_advantage_label.text = ""
	
		if !ReplayManager.playback:
			var p1 = game.get_player(1)
			var p2 = game.get_player(2)
			var combo = p1.combo_count > 0 or p2.combo_count > 0
			var trade = p1.combo_count > 0 and p2.combo_count > 0
			var initiative = !combo and p1.state_interruptable and p2.state_interruptable and !p1.busy_interrupt and !p2.busy_interrupt
			neutral_label.text = (("<-COMBO" if game.get_player(1).combo_count > 0 else " COMBO->") if combo else ("BUSY" if !initiative else "NEUTRAL")) if !trade else "TRADE"
			neutral_label.rect_position.x = 0 if combo else 1
			neutral_label.set("custom_colors/font_color", ((Color("1d8df5") if p1.combo_count > 0 else Color("ff333d")) if combo else Color.darkgray) if !trade else Color("c735d4"))
			neutral_label.modulate.a = 1.0 if combo else 0.5 if !initiative else 1.0
		else:
			neutral_label.text = ""
	$"%P1SuperContainer".rect_min_size.y = 50 if !p1_action_buttons.visible else 0
	$"%P2SuperContainer".rect_min_size.y = 50 if !p2_action_buttons.visible else 0
	$"%TopInfo".visible = is_instance_valid(game) and !ReplayManager.playback and game.is_waiting_on_player() and !Network.multiplayer_active and !game.game_finished and !Network.rematch_menu
	$"%TopInfoMP".visible = is_instance_valid(game) and !ReplayManager.playback and game.is_waiting_on_player() and Network.multiplayer_active and !game.game_finished and !Network.rematch_menu
	$"%TopInfoReplay".visible = is_instance_valid(game) and ReplayManager.playback and !game.game_finished and !Network.rematch_menu
	$"%HelpButton".visible = is_instance_valid(game) and game.game_paused
	$"%ResetZoomButton".visible = is_instance_valid(game) and game.camera_zoom != 1.0 and game.game_paused
	if is_instance_valid(game) and !Network.multiplayer_active:
		$"%ReplayControls".show()
	else:
		$"%ReplayControls".hide()
#	if $"%TopInfoMP".visible and !actionable:
#		on_player_actionable()
	$"%SoftlockResetButton".visible = false
	if Network.multiplayer_active and is_instance_valid(game):
		var my_action_buttons = p1_action_buttons if Network.player_id == 1 else p2_action_buttons
		$"%SoftlockResetButton".visible = (!my_action_buttons.visible or my_action_buttons.get_node("%SelectButton").disabled) and actionable_time > 5 and !(game.game_finished or ReplayManager.playback) and !SteamLobby.SPECTATING
		if !$"%SoftlockResetButton".visible:
			$"%SoftlockResetButton".disabled = false

		if !my_action_buttons.visible or my_action_buttons.get_node("%SelectButton").disabled:
			actionable_time += delta
		else:
			actionable_time = 0

func set_lobby_settings(settings):
	$"%CharacterSelect".lobby_match_settings = settings
	pass

func start_timers():
	yield(get_tree().create_timer(0.25), "timeout")
	if actionable:
		p1_turn_timer.paused = false
		p2_turn_timer.paused = false

func _on_SoftlockResetButton_pressed():
	Network.rpc_("send_chat_message", [Network.player_id, "-- wants to resync."])
	Network.request_softlock_fix()
	$"%SoftlockResetButton".disabled = true
	pass # Replace with function body.



func _on_ClearParticlesButton_pressed():
	if is_instance_valid(game):
		for particle in game.effects:
			if !is_instance_valid(particle):
				continue
			# Custom hitsparks carry CustomTrailParticle children that
			# self-process (auto_start_on_ready), so just hiding the parent
			# leaves them simulating — free the whole effect to actually
			# clear it. Plain effects (no self-driven trail) keep the old
			# hide behavior.
			var has_trail = false
			for child in particle.get_children():
				if child is CustomTrailParticle:
					has_trail = true
					break
			if has_trail:
				particle.queue_free()
			else:
				particle.hide()
		for player_id in [1, 2]:
			for p in game.get_player(player_id).aura_particles:
				if !is_instance_valid(p):
					continue
				p.restart()
				# Sources also keep an array of in-flight one-shot burst
				# clones — free them so clearing wipes existing dynamic-trigger
				# bursts, not just the source emitter's in-flight particles.
				if p.get("active_burst_clones") != null:
					for clone in p.active_burst_clones:
						if is_instance_valid(clone):
							clone.queue_free()
					p.active_burst_clones.clear()
	pass # Replace with function body.


func _on_RoadmapButton_toggled(button_pressed):
	$"%RoadmapListContainer".visible = button_pressed
	pass # Replace with function body.


# --- More Hotkeys handlers --------------------------------------------------

func _toggle_free_cancel():
	if not is_instance_valid(game):
		return
	var targets = []
	if Network.multiplayer_active:
		targets.append(p1_action_buttons if Network.player_id == 1 else p2_action_buttons)
	else:
		targets = [p1_action_buttons, p2_action_buttons]
	for ab in targets:
		var feint_btn = ab.get_node("%FeintButton")
		if not feint_btn.disabled:
			feint_btn.pressed = !feint_btn.pressed
			ab.send_ui_action()

func _toggle_flip():
	if not is_instance_valid(game):
		return
	var targets = []
	if Network.multiplayer_active:
		targets.append(p1_action_buttons if Network.player_id == 1 else p2_action_buttons)
	else:
		targets = [p1_action_buttons, p2_action_buttons]
	for ab in targets:
		var reverse_btn = ab.get_node("%ReverseButton")
		if not reverse_btn.disabled:
			reverse_btn.pressed = !reverse_btn.pressed
			ab.send_ui_action()

func _toggle_prediction():
	var btn = get_node_or_null("%GhostButton")
	if btn:
		btn.set_pressed(!btn.pressed)

func _toggle_hitboxes():
	Global.show_hitboxes = !Global.show_hitboxes
	$"%HitboxesButton".set_pressed_no_signal(Global.show_hitboxes)
	Global.save_options()

func _toggle_playback_controls():
	Global.show_playback_controls = !Global.show_playback_controls
	$"%PlaybackControls".set_pressed_no_signal(Global.show_playback_controls)
	Global.save_options()
	if is_instance_valid(game) and not Network.multiplayer_active:
		$"%ReplayControls".visible = Global.show_playback_controls

func _toggle_projectile_owners():
	Global.show_projectile_owners = !Global.show_projectile_owners
	$"%ProjectileOwnersButton".set_pressed_no_signal(Global.show_projectile_owners)
	Global.save_options()

func _toggle_fullscreen():
	Global.set_fullscreen(!Global.fullscreen)
	$"%FullscreenButton".set_pressed_no_signal(Global.fullscreen)

# Flip a check button that lives in global_option_check_buttons. Assigning
# `pressed` (not set_pressed_no_signal) fires the "toggled" signal, which is
# already wired to _on_global_option_toggled → Global.save_option, so the
# button visual + saved setting stay in sync exactly as a UI click would.
func _toggle_global_button(node_path: String):
	var btn = get_node_or_null(node_path)
	if btn:
		btn.pressed = !btn.pressed

# Freeze-on-ready lives on the main scene (FreezeOnMyTurn). Toggling it needs
# both signals a UI click sends: "toggled" (saves the option) and "pressed"
# (main.gd::start_ghost, which restarts the prediction with the new setting).
func _toggle_freeze_on_ready():
	var btn = get_node_or_null("%FreezeOnMyTurn")
	if btn == null:
		return
	btn.pressed = !btn.pressed
	btn.emit_signal("pressed")

# Same shape as _toggle_freeze_on_ready: AfterimageButton wires both "toggled"
# (saves ghost_afterimages) and "pressed" (main.gd::start_ghost). Programmatic
# `pressed = ...` only fires "toggled", so we re-emit "pressed" explicitly so
# the ghost restarts and the change takes effect immediately.
func _toggle_afterimage():
	var btn = get_node_or_null("%AfterimageButton")
	if btn == null:
		return
	btn.pressed = !btn.pressed
	btn.emit_signal("pressed")

func _trigger_undo():
	if not is_instance_valid(game):
		return
	if p1_action_buttons.try_undo():
		return
	p2_action_buttons.try_undo()

# mod values: 4 = 0.25x, 2 = 0.5x, -1 = 0.75x, 1 = 1.0x.
# slider.value_changed updates both Global.playback_speed_mod and the label.
func _set_playback_speed(mod):
	var slider_value = {4: 0, 2: 1, -1: 2, 1: 3}.get(mod, 3)
	var slider = get_node_or_null("%PlaybackSpeed")
	if slider:
		slider.value = slider_value
	else:
		Global.playback_speed_mod = mod


# --- XY plot arrow-key nudging (not rebindable) -----------------------------

func _handle_xy_nudge(event):
	if not is_instance_valid(Hotkeys.hovered_xy_plot):
		return
	var nudge = null
	# allow_echo=true lets OS key-repeat fire the nudge while the key is held
	# (no internal timer — same pattern as LimbFinder's arrow-key nudging).
	if event.is_action_pressed(Hotkeys.NUDGE_LEFT, true):
		nudge = Vector2(-0.01, 0)
	elif event.is_action_pressed(Hotkeys.NUDGE_RIGHT, true):
		nudge = Vector2(0.01, 0)
	elif event.is_action_pressed(Hotkeys.NUDGE_UP, true):
		nudge = Vector2(0, -0.01)
	elif event.is_action_pressed(Hotkeys.NUDGE_DOWN, true):
		nudge = Vector2(0, 0.01)
	if nudge == null:
		return
	var plot = Hotkeys.hovered_xy_plot
	var current = plot.value_float
	var raw_new = (current + nudge * plot.panel_radius).limit_length(plot.panel_radius)
	var new_value = raw_new
	if plot.snap and not Global.XY_SNAP_TOGGLE_ENABLED:
		# Sticky-snap zones: outside any zone, free movement; entering a zone
		# snaps to its center; nudging while inside a zone pops the result to
		# the zone boundary on the motion side so the next nudge starts from
		# outside the zone and continues free instead of re-snapping back.
		new_value = _xy_sticky_snap(plot, current, raw_new)
	plot.update_value(new_value, true, true)
	plot.emit_signal("data_changed")

# Mirrors XYPlot's internal SNAP_AMOUNT (half-width of a snap zone, in radians
# for angles and as a ratio of panel_radius for radius). _XY_ZONE_EXIT_EPSILON
# offsets the zone-exit position just past the boundary so the next nudge
# starts outside and isn't immediately resnapped by the "entering a zone" path.
const _XY_SNAP_AMOUNT = 0.1
const _XY_ZONE_EXIT_EPSILON = 0.001
# Below this magnitude the nudge counts as having no motion in that axis —
# guards against floating-point noise erroneously kicking the point out of a
# zone for a perfectly-radial (or perfectly-angular) nudge.
const _XY_MOTION_EPSILON = 0.0001

func _xy_sticky_snap(plot, current: Vector2, raw_new: Vector2) -> Vector2:
	var raw_radius = raw_new.length()
	if raw_radius < 0.001:
		return Vector2.ZERO
	var final_angle = raw_new.angle()
	if plot.snap_angles > 0:
		var step = TAU / plot.snap_angles
		var offset = 0.0
		if plot.snap_align_to_limit_center and plot.limit_angle:
			offset = plot.get_limit_center()
		var current_radius = current.length()
		var current_in_zone = false
		var current_snap = 0.0
		var current_angle = 0.0
		if current_radius > 0.001:
			current_angle = current.angle()
			current_snap = offset + round((current_angle - offset) / step) * step
			current_in_zone = abs(Utils.angle_diff(current_angle, current_snap)) < _XY_SNAP_AMOUNT
		if current_in_zone:
			# Utils.angle_diff(from, to) returns the signed displacement
			# from `from` to `to`. We want "current → final" — putting them
			# in the wrong order inverted the exit direction (the bug at
			# (0, -1) + LEFT popping right).
			var angular_motion = Utils.angle_diff(current_angle, final_angle)
			if abs(angular_motion) < _XY_MOTION_EPSILON:
				# Pure radial nudge — keep the snap angle locked.
				final_angle = current_snap
			else:
				# Pop to the zone boundary on the motion side. Next nudge
				# starts outside the zone and continues free.
				var dir = 1.0 if angular_motion > 0 else -1.0
				final_angle = current_snap + dir * (_XY_SNAP_AMOUNT + _XY_ZONE_EXIT_EPSILON)
		else:
			var raw_snap = offset + round((final_angle - offset) / step) * step
			if abs(Utils.angle_diff(final_angle, raw_snap)) < _XY_SNAP_AMOUNT:
				# Crossing INTO a zone — snap to its center.
				final_angle = raw_snap
	var final_radius = raw_radius
	if plot.snap_radius > 0.0:
		var current_radius_r = current.length()
		var target_r = plot.snap_radius * plot.panel_radius
		var zone_width = _XY_SNAP_AMOUNT * plot.panel_radius
		var current_in_r_zone = abs(current_radius_r - target_r) < zone_width
		if current_in_r_zone:
			var radial_motion = raw_radius - current_radius_r
			if abs(radial_motion) < _XY_MOTION_EPSILON * plot.panel_radius:
				final_radius = target_r
			else:
				var dir = 1.0 if radial_motion > 0 else -1.0
				final_radius = target_r + dir * (zone_width + _XY_ZONE_EXIT_EPSILON * plot.panel_radius)
		elif abs(raw_radius - target_r) < zone_width:
			final_radius = target_r
	final_radius = clamp(final_radius, 0.0, plot.panel_radius)
	return Vector2(cos(final_angle), sin(final_angle)) * final_radius


func _on_WorkshopUploader_pressed():
	on_workshop_uploader_clicked()
	pass # Replace with function body.
