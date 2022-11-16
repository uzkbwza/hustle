extends CanvasLayer

onready var p1_action_buttons = $"%P1ActionButtons"
onready var p2_action_buttons = $"%P2ActionButtons"

signal singleplayer_started()
signal multiplayer_started()
signal loaded_replay(match_data)
signal received_synced_time()

var game
var turns_taken = {
	1: false,
	2: false
}

var turn_time = 30

var p1_turn_time = 30
var p2_turn_time = 30

var lock_in_tick = -INF

const DISCORD_URL = "https://discord.gg/yomi"
const TWITTER_URL = "https://twitter.com/ivy_sly_"
const IVY_SLY_URL = "https://www.ivysly.com"
const ITCH_URL = "https://ivysly.itch.io/yomi-hustle"
const MIN_TURN_TIME = 5.0

onready var lobby = $Lobby
onready var direct_connect_lobby = $DirectConnectLobby
onready var p1_turn_timer = $"%P1TurnTimer"
onready var p2_turn_timer = $"%P2TurnTimer"

var p1_synced_time = null
var p2_synced_time = null

var game_started = false
var timer_sync_tick = -1
var actionable = false

var received_synced_time = false

func _ready():
	$"%SingleplayerButton".connect("pressed", self, "_on_singleplayer_pressed")
	$"%MultiplayerButton".connect("pressed", self, "_on_multiplayer_pressed")
	$"%DirectConnectButton".connect("pressed", self, "_on_direct_connect_button_pressed")
	$"%RematchButton".connect("pressed", self, "_on_rematch_button_pressed")
	$"%QuitButton".connect("pressed", self, "_on_quit_button_pressed")
	$"%QuitToMainMenuButton".connect("pressed", self, "_on_quit_button_pressed")
	$"%QuitProgramButton".connect("pressed", self, "_on_quit_program_button_pressed")
	$"%ResumeButton".connect("pressed", self, "pause")
	$"%ReplayButton".connect("pressed", self, "load_replays")
	$"%ReplayCancelButton".connect("pressed", self, "_on_replay_cancel_pressed")
	$"%OpenReplayFolderButton".connect("pressed", self, "open_replay_folder")
	$"%P1ActionButtons".connect("turn_ended", self, "end_turn_for", [1])
	$"%P2ActionButtons".connect("turn_ended", self, "end_turn_for", [2])
	$"%ShowAutosavedReplays".connect("pressed", self, "load_replays")
	$"%DiscordButton".connect("pressed", OS, "shell_open", [DISCORD_URL])
	$"%IvySlyLinkButton".connect("pressed", OS, "shell_open", [IVY_SLY_URL])
	$"%TwitterButton".connect("pressed", OS, "shell_open", [TWITTER_URL])
	$"%ItchButton".connect("pressed", OS, "shell_open", [ITCH_URL])
	$"%VersionLabel".text = "version " + Global.VERSION

	Network.connect("player_turns_synced", self, "on_player_actionable")
	Network.connect("player_turn_ready", self, "_on_player_turn_ready")
	Network.connect("turn_ready", self, "_on_turn_ready")
	Network.connect("sync_timer_request", self, "_on_sync_timer_request")
	Network.connect("check_players_ready", self, "check_players_ready")
	
	p1_turn_timer.connect("timeout", self, "_on_turn_timer_timeout", [1])
	p2_turn_timer.connect("timeout", self, "_on_turn_timer_timeout", [2])
	for lobby in [$"%Lobby", $"%DirectConnectLobby"]:
		lobby.connect("quit_on_rematch", $"%RematchButton", "hide")
	
	$"%OptionsBackButton".connect("pressed", $"%OptionsContainer", "hide")
	$"%OptionsButton".connect("pressed", $"%OptionsContainer", "show")
	$"%PauseOptionsButton".connect("pressed", $"%OptionsContainer", "show")
	$"%MusicButton".set_pressed_no_signal(Global.music_enabled)
	$"%MusicButton".connect("toggled", self, "_on_music_button_toggled")
	$"%FullscreenButton".set_pressed_no_signal(Global.fullscreen)
	$"%FullscreenButton".connect("toggled", self, "_on_fullscreen_button_toggled")
	$"%HitboxesButton".set_pressed_no_signal(Global.show_hitboxes)
	$"%HitboxesButton".connect("toggled", self, "_on_hitboxes_button_toggled")
	$"%PlaybackControls".set_pressed_no_signal(Global.show_playback_controls)
	$"%PlaybackControls".connect("toggled", self, "_on_playback_controls_button_toggled")
	$NetworkSyncTimer.connect("timeout", self, "_on_network_timer_timeout")
	
func _on_music_button_toggled(on):
	Global.set_music_enabled(on)
	Global.save_options()

func _on_fullscreen_button_toggled(on):
	Global.set_fullscreen(on)

func _on_hitboxes_button_toggled(on):
	Global.set_hitboxes(on)

func _on_playback_controls_button_toggled(on):
	Global.set_playback_controls(on)

func load_replays():
	$"%ReplayWindow".show()
	for child in $"%ReplayContainer".get_children():
		child.free()
	var replay_map = ReplayManager.load_replays($"%ShowAutosavedReplays".pressed)
	var buttons = []
	for key in replay_map:
		var button = preload("res://ui/ReplayWindow/ReplayButton.tscn").instance()
		button.text = key
		button.path = replay_map[key]["path"]
		button.modified = replay_map[key]["modified"]
		button.connect("pressed", self, "_on_replay_button_pressed", [button.path])
		buttons.append(button)
	buttons.sort_custom(self, "sort_replays")
	for button in buttons:
		$"%ReplayContainer".add_child(button)
	$"%MainMenu".hide()

func set_turn_time(time):
#	print("setting turn time to " + str(time))
	p1_turn_time = time * 60
	p2_turn_time = time * 60
	turn_time = time * 60
	p1_turn_timer.wait_time = p1_turn_time
	p2_turn_timer.wait_time = p2_turn_time

func sort_replays(a, b):
	return a.modified > b.modified

func _on_replay_button_pressed(path):
	var match_data = ReplayManager.load_replay(path)
	emit_signal("loaded_replay", match_data)
	$"%ReplayWindow".hide()

func _on_replay_cancel_pressed():
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	Network.stop_multiplayer()
	get_tree().reload_current_scene()

func _on_quit_program_button_pressed():
	get_tree().quit()

func _on_sync_timer_request(id, time):
	if id == 1:
		var paused = p1_turn_timer.paused
		p1_turn_timer.start(time)
		p1_turn_timer.paused = paused
		received_synced_time = true
		emit_signal("received_synced_time")
	elif id == 2:
		var paused = p2_turn_timer.paused
		p2_turn_timer.start(time)
		p2_turn_timer.paused = paused
		received_synced_time = true
		emit_signal("received_synced_time")

func sync_timer(player_id):
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
	if !ReplayManager.playback:
		$PostGameButtons.hide()
		$"%RematchButton".disabled = false
	self.game = game
	setup_action_buttons()
	if Network.multiplayer_active:
		game.connect("playback_requested", self, "_on_game_playback_requested")
		$"%P1TurnTimerLabel".show()
		$"%P2TurnTimerLabel".show()
		$"%ChatWindow".show()
	game_started = false
	timer_sync_tick = -1
	lock_in_tick = -INF

func _on_player_turn_ready(player_id):
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

	lock_in_tick = game.current_tick

	$"%TurnReadySound".play()
	turns_taken[player_id] = true

func _on_rematch_button_pressed():
	Network.request_rematch()
	$"%RematchButton".disabled = true

func _on_game_playback_requested():
	if Network.multiplayer_active:
		$PostGameButtons.show()
		$"%RematchButton".show()
		Network.rematch_menu = true

func on_game_started():
	lobby.hide()
	$MainMenu.hide()

func _on_singleplayer_pressed():
	emit_signal("singleplayer_started")

func _on_direct_connect_button_pressed():
	direct_connect_lobby.show()
	$"%MainMenu".hide()

func _on_multiplayer_pressed():
	lobby.show()
	$"%MainMenu".hide()

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
	turns_taken[player_id] = true

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
	if actionable and Network.multiplayer_active:
		return
	actionable = true
#	if p1_turn_timer.wait_time == 0:
#		p1_turn_timer.wait_time = MIN_TURN_TIME
#	if p2_turn_timer.wait_time == 0:
#		 p2_turn_timer.wait_time = MIN_TURN_TIME
	if Network.multiplayer_active:
		Network.rpc_("my_turn_started")
		yield(Network, "opponent_turn_started")
		print("starting turn timer")
#		if $"%P1ActionButtons".any_available_actions and $"%P2ActionButtons".any_available_actions:
		if !game_started:
#		if p1_turn_timer.is_stopped():
			p1_turn_timer.start()
			p2_turn_timer.start()
			game_started = true
		else:
			if p1_turn_timer.time_left < MIN_TURN_TIME:
				p1_turn_timer.start(MIN_TURN_TIME)
			if p2_turn_timer.time_left < MIN_TURN_TIME:
				p2_turn_timer.start(MIN_TURN_TIME)

		p1_turn_timer.paused = false
		p2_turn_timer.paused = false
#		if game.current_tick != timer_sync_tick:
#			timer_sync_tick = game.current_tick
#			sync_timer(Network.player_id)
#			if !received_synced_time:
#				yield(self, "received_synced_time")
#				received_synced_time = false
		$"%P1TurnTimerBar".show()
		$"%P2TurnTimerBar".show()

#	$"%P1SuperContainer".rect_min_size.y = 40
#	$"%P2SuperContainer".rect_min_size.y = 40
	$"%P1ActionButtons".activate()
	$"%P2ActionButtons".activate()
	$"%AdvantageLabel".text = ""

#		else:
#			turn_timer.start(turn_time)

func _on_turn_timer_timeout(player_id):
		if player_id == 1:
			if Network.player_id == player_id:
				$"%P1ActionButtons".timeout()
				p1_turn_timer.wait_time = MIN_TURN_TIME
				p1_turn_timer.start()
				p1_turn_timer.paused = true
		else:
			if Network.player_id == player_id:
				$"%P2ActionButtons".timeout()
				p1_turn_timer.wait_time = MIN_TURN_TIME
				p1_turn_timer.start()
				p1_turn_timer.paused = true
func pause():
	$"%PausePanel".visible = !$"%PausePanel".visible
	if $"%PausePanel".visible:
		$"%SaveReplayButton".disabled = false
		$"%SaveReplayButton".text = "save replay"
		$"%SaveReplayLabel".text = ""

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_ENTER:
				if Network.multiplayer_active:
					$"%ChatWindow".show()
					$"%ChatWindow".line_edit_focus()
			if event.scancode == KEY_F1:
				visible = !visible
				$"../HudLayer/HudLayer".visible = ! $"../HudLayer/HudLayer".visible
#			if !Network.multiplayer_active:
#				if is_instance_valid(game) and $"%ReplayControls".visible:
#					if event.scancode == KEY_P:
#						Global.frame_advance = !Global.frame_advance
#					if event.scancode == KEY_F:
#						game.advance_frame_input = true
#			if event.scancode == KEY_SPACE:
#				p1_action_buttons.space_pressed()
#				p2_action_buttons.space_pressed()

func time_convert(time_in_sec):
	var seconds = time_in_sec%60
	var minutes = (time_in_sec/60)%60
	var hours = (time_in_sec/60)/60

	#returns a string with the format "HH:MM:SS"
	if hours >= 1:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	return "%02d:%02d" % [minutes, seconds]

func _process(_delta):
	if !p1_turn_timer.is_paused():
#		if !turns_taken[1]:
			var bar = $"%P1TurnTimerBar"
			bar.value = p1_turn_timer.time_left / turn_time
			if p1_turn_timer.time_left < 5:
				bar.visible = Utils.wave(-1, 1, 0.064) > 0
	if !p2_turn_timer.is_paused():
#		if !turns_taken[2]:
			var bar = $"%P2TurnTimerBar"
			bar.value = p2_turn_timer.time_left / turn_time
			if p2_turn_timer.time_left < 5:
				bar.visible = Utils.wave(-1, 1, 0.064) > 0
	$"%P1TurnTimerLabel".text = time_convert(int(floor(p1_turn_timer.time_left)))
	$"%P2TurnTimerLabel".text = time_convert(int(floor(p2_turn_timer.time_left)))

	if Input.is_action_just_pressed("pause"):
		pause()

	var advantage_label = $"%AdvantageLabel"
#	advantage_label.text = ""
	var ghost_game = get_parent().ghost_game
	if is_instance_valid(ghost_game) and is_instance_valid(game):
		if game.game_paused:
			var you_id = 1
			var opponent_id = 2
			if Network.multiplayer_active:
				you_id = Network.player_id
				opponent_id = (you_id % 2) + 1
			var you = ghost_game.get_player(you_id)
			var opponent = ghost_game.get_player(opponent_id)
			if you.ghost_ready_tick != null and opponent.ghost_ready_tick != null:
				var advantage = opponent.ghost_ready_tick - you.ghost_ready_tick
				if advantage >= 0:
					advantage_label.set("custom_colors/font_color", Color("64d26b"))
					advantage_label.text = "frame advantage: +" + str(advantage)
				else:
					advantage_label.set("custom_colors/font_color", Color("ff333d"))
					advantage_label.text = "frame advantage: " + str(advantage)
		else:
			advantage_label.text = ""
	$"%P1SuperContainer".rect_min_size.y = 50 if !p1_action_buttons.visible else 0
	$"%P2SuperContainer".rect_min_size.y = 50 if !p2_action_buttons.visible else 0
	$"%TopInfo".visible = is_instance_valid(game) and !ReplayManager.playback and game.is_waiting_on_player() and !Network.multiplayer_active and !game.game_finished and !Network.rematch_menu
	$"%TopInfoMP".visible = is_instance_valid(game) and !ReplayManager.playback and game.is_waiting_on_player() and Network.multiplayer_active and !game.game_finished and !Network.rematch_menu
	$"%TopInfoReplay".visible = is_instance_valid(game) and ReplayManager.playback and !game.game_finished and !Network.rematch_menu
	if is_instance_valid(game) and !Network.multiplayer_active:
		$"%ReplayControls".show()
	else:
		$"%ReplayControls".hide()
#	if $"%TopInfoMP".visible and !actionable:
#		on_player_actionable()
