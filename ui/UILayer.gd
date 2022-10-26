extends CanvasLayer

onready var p1_action_buttons = $"%P1ActionButtons"
onready var p2_action_buttons = $"%P2ActionButtons"

signal singleplayer_started()
signal multiplayer_started()

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
	$"%P1ActionButtons".connect("turn_ended", self, "end_turn_for", [1])
	$"%P2ActionButtons".connect("turn_ended", self, "end_turn_for", [2])
	Network.connect("player_turns_synced", self, "on_player_actionable")
	Network.connect("player_turn_ready", self, "_on_player_turn_ready")
	Network.connect("turn_ready", self, "_on_turn_ready")
	turn_timer.connect("timeout", self, "_on_turn_timer_timeout")

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

func _process(_delta):
	if !turn_timer.is_stopped():
		var bars = [$"%P1TurnTimerBar", $"%P2TurnTimerBar"]
		for i in range(2):
#			if !turns_taken[i+1]:
				var bar = bars[i]
				bar.value = turn_timer.time_left / turn_timer.wait_time
				if turn_timer.time_left < 5:
					bar.visible = Utils.wave(-1, 1, 0.032) > 0
