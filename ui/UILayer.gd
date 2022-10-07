extends CanvasLayer

onready var p1_action_buttons = $"%P1ActionButtons"
onready var p2_action_buttons = $"%P2ActionButtons"

signal singleplayer_started()
signal multiplayer_started()

var game

onready var lobby = $Lobby

func _ready():
	$"%SingleplayerButton".connect("pressed", self, "_on_singleplayer_pressed")
	$"%MultiplayerButton".connect("pressed", self, "_on_multiplayer_pressed")
	$"%RematchButton".connect("pressed", self, "_on_rematch_button_pressed")
	Network.connect("player_turns_synced", self, "on_player_actionable")

func init(game):
	if !ReplayManager.playback:
		$PostGameButtons.hide()
		$"%RematchButton".disabled = false
		
	self.game = game
	setup_action_buttons()
	if Network.multiplayer_active:
		game.connect("playback_requested", self, "_on_game_playback_requested")
		

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

func _on_multiplayer_pressed():
	lobby.show()

func setup_action_buttons():
	$"%P1ActionButtons".init(game, 1)
	$"%P2ActionButtons".init(game, 2)

func on_player_actionable():
#	if id == 1:
		$"%P1ActionButtons".activate()
#	if id == 2:
		$"%P2ActionButtons".activate()
