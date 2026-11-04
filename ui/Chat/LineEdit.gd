extends LineEdit

signal message_ready(message)

var _last_key_sound_ms := 0

func _ready():
	$"%SendButton".connect("pressed", self, "send_message")

func _gui_input(event):
	if event is InputEventKey:
		if event.pressed and !event.echo:
			if event.is_action_pressed(Hotkeys.SEND_CHAT):
				send_message()
				accept_event()
				return
			if event.unicode >= 32 or event.scancode == KEY_BACKSPACE:
				var now = OS.get_ticks_msec()
				if now - _last_key_sound_ms >= 45:
					_last_key_sound_ms = now
					$KeyboardSound.play()

func send_message():
	if text.strip_edges() == "":
		return
	emit_signal("message_ready", text.strip_edges())
