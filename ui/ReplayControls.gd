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
	$"%PlayReplayButton".connect("pressed", self, "_on_play_replay_pressed")
	$"%EditReplayButton".connect("pressed", self, "_on_edit_replay_pressed")
	Hotkeys.connect("binding_changed", self, "_refresh_hotkey_labels")
	_refresh_hotkey_labels()

func _on_play_replay_pressed():
	_fire_action(Hotkeys.WATCH_REPLAY)

func _on_edit_replay_pressed():
	_fire_action(Hotkeys.EDIT_REPLAY)

func _fire_action(action):
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)

func _refresh_hotkey_labels(_action = ""):
	var pause_key = Hotkeys.get_display_name(Hotkeys.TOGGLE_FRAME_ADVANCE)
	var advance_key = Hotkeys.get_display_name(Hotkeys.FRAME_ADVANCE)
	$"%PauseHotkeyLabel".text = ("(%s)" % pause_key) if pause_key else ""
	$"%FrameAdvanceHotkeyLabel".text = ("(%s)" % advance_key) if advance_key else ""

func show():
	if Global.show_playback_controls:
		_on_pause_toggled(Global.frame_advance)
		$"%PauseButton".set_pressed_no_signal(Global.frame_advance)
		$"%PlaybackSpeed".value = {
			4: 0,
			2: 1,
			-1: 2,
			1: 3,
		}[Global.playback_speed_mod]
		.show()

func _on_frame_advance():
	# While a replay is actively playing, the frame-advance key pauses it
	# instead of stepping — you single-step once it's already paused. Lets the
	# one key both pause and step playback.
	if ReplayManager.playback and !Global.frame_advance:
		toggle_frame_advance()
		return
	if is_instance_valid(Global.current_game):
		Global.current_game.advance_frame_input = true

# Same actions the window's button shortcuts trigger, exposed so the playback
# hotkeys can fire while the window is closed (when the
# playback_hotkeys_require_window option is off). See UILayer._input.
func toggle_frame_advance():
	var on = !Global.frame_advance
	_on_pause_toggled(on)
	$"%PauseButton".set_pressed_no_signal(on)

func frame_advance_step():
	_on_frame_advance()

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
		Global.playback_speed_mod = -1
		$"%SpeedText".text = "x0.75"
	elif value == 3:
		Global.playback_speed_mod = 1
		$"%SpeedText".text = "x1.0"
