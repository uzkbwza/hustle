extends CanvasLayer

onready var p1_action_buttons = $"%P1ActionButtons"
onready var p2_action_buttons = $"%P2ActionButtons"

signal singleplayer_started()
signal multiplayer_started()
signal loaded_replay(match_data)

var game
var turns_taken = {
	1: false,
	2: false
}

const BOTH_ACTIONABLE_TURN_TIMER = 30
const ONE_ACTIONABLE_TURN_TIMER = 15

onready var lobby = $Lobby
onready var direct_connect_lobby = $DirectConnectLobby
onready var turn_timer = $"%TurnTimer"
func _ready():
	$"%SingleplayerButton".connect("pressed", self, "_on_singleplayer_pressed")
	$"%MultiplayerButton".connect("pressed", self, "_on_multiplayer_pressed")
	$"%DirectConnectButton".connect("pressed", self, "_on_direct_connect_button_pressed")
	$"%RematchButton".connect("pressed", self, "_on_rematch_button_pressed")
	$"%QuitButton".connect("pressed", self, "_on_quit_button_pressed")
	$"%QuitToMainMenuButton".connect("pressed", self, "_on_quit_button_pressed")
	$"%ResumeButton".connect("pressed", self, "pause")
	$"%ReplayButton".connect("pressed", self, "load_replay")
	$"%ReplayCancelButton".connect("pressed", $"%ReplayWindow", "hide")
	$"%OpenReplayFolderButton".connect("pressed", self, "open_replay_folder")
	$"%P1ActionButtons".connect("turn_ended", self, "end_turn_for", [1])
	$"%P2ActionButtons".connect("turn_ended", self, "end_turn_for", [2])
	Network.connect("player_turns_synced", self, "on_player_actionable")
	Network.connect("player_turn_ready", self, "_on_player_turn_ready")
	Network.connect("turn_ready", self, "_on_turn_ready")
	turn_timer.connect("timeout", self, "_on_turn_timer_timeout")

func load_replay():
	$"%ReplayWindow".show()
	for child in $"%ReplayContainer".get_children():
		child.free()
	var replay_map = ReplayManager.load_replays()
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

func sort_replays(a, b):
	return a.modified > b.modified

func _on_replay_button_pressed(path):
	var match_data = ReplayManager.load_replay(path)
	emit_signal("loaded_replay", match_data)
	$"%ReplayWindow".hide()

func _on_quit_button_pressed():
	Network.stop_multiplayer()
	get_tree().reload_current_scene()

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

func _on_player_turn_ready(player_id):
	if player_id == 1:
		$"%P1TurnTimerBar".hide()
	elif player_id == 2:
		$"%P2TurnTimerBar".hide()
	turns_taken[player_id] = true

func _on_rematch_button_pressed():
	Network.request_rematch()
	$"%RematchButton".disabled = true

func _on_game_playback_requested():
	$PostGameButtons.show()
	$"%RematchButton".show()

func on_game_started():
	lobby.hide()
	$MainMenu.hide()

func _on_singleplayer_pressed():
	emit_signal("singleplayer_started")

func _on_direct_connect_button_pressed():
	direct_connect_lobby.show()

func _on_multiplayer_pressed():
	lobby.show()

func _on_turn_ready():
	$"%P1TurnTimerBar".hide()
	$"%P2TurnTimerBar".hide()
	turn_timer.stop()
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

func on_player_actionable():
	$"%P1ActionButtons".activate()
	$"%P2ActionButtons".activate()
#	if Network.multiplayer_active:
#		if $"%P1ActionButtons".any_available_actions and $"%P2ActionButtons".any_available_actions:
#			turn_timer.start(BOTH_ACTIONABLE_TURN_TIMER)
#		else:
#			turn_timer.start(ONE_ACTIONABLE_TURN_TIMER)
#		$"%P1TurnTimerBar".show()
#		$"%P2TurnTimerBar".show()

func _on_turn_timer_timeout():
	$"%P1ActionButtons".timeout()
	$"%P2ActionButtons".timeout()

func pause():
	$"%PausePanel".visible = !$"%PausePanel".visible
	if $"%PausePanel".visible:
		$"%SaveReplayButton".disabled = false
		$"%SaveReplayButton".text = "save replay"
		$"%SaveReplayLabel".text = ""

func _process(_delta):
	if !turn_timer.is_stopped():
		var bars = [$"%P1TurnTimerBar", $"%P2TurnTimerBar"]
		for i in range(2):
#			if !turns_taken[i+1]:
				var bar = bars[i]
				bar.value = turn_timer.time_left / turn_timer.wait_time
				if turn_timer.time_left < 5:
					bar.visible = Utils.wave(-1, 1, 0.032) > 0
	if Input.is_action_just_pressed("pause"):
		pause()
	$"%TopInfo".visible = is_instance_valid(game) and !ReplayManager.playback and game.is_waiting_on_player() and !Network.multiplayer_active and !game.game_finished
	$"%TopInfoMP".visible = is_instance_valid(game) and !ReplayManager.playback and game.is_waiting_on_player() and Network.multiplayer_active and !game.game_finished
	$"%TopInfoReplay".visible = is_instance_valid(game) and ReplayManager.playback and !game.game_finished
