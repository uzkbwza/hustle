extends Window


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$"%ShowButton".connect("pressed", Global, "set_playback_controls", [false])
	$"%ShowButton".connect("pressed", self, "hide")
	$"%PauseButton".connect("toggled", self, "_on_pause_toggled")
	$"%FrameAdvance".connect("pressed", self, "_on_frame_advance")
	
func show():
	if Global.show_playback_controls:
		_on_pause_toggled(Global.frame_advance)
		$"%PauseButton".set_pressed_no_signal(Global.frame_advance)
		$"%PlaybackSpeed".value = {
			4: 0,
			2: 1,
			1: 2,
			0: 3,
		}[Global.playback_speed_mod]
		.show()

func _on_frame_advance():
	if is_instance_valid(Global.current_game):
		Global.current_game.advance_frame_input = true

func _on_pause_toggled(on):
	if on:
		Global.frame_advance = true
		$"%PauseButton".icon = preload("res://ui/PlaybackWindow/pause_play1.png")
	else:
		Global.frame_advance = false
		$"%PauseButton".icon = preload("res://ui/PlaybackWindow/pause_play2.png")

func _on_HSlider_value_changed(value):
	if value == 0:
		Global.playback_speed_mod = 4
		$"%SpeedText".text = "x0.25"
	elif value == 1:
		Global.playback_speed_mod = 2
		$"%SpeedText".text = "x0.5"
	elif value == 2:
		Global.playback_speed_mod = 1
		$"%SpeedText".text = "x1.0"
	elif value == 3:
		Global.playback_speed_mod = 0
		$"%SpeedText".text = "x4.0"
