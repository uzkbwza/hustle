extends LineEdit

signal message_ready(message)

var _last_key_sound_ms := 0
var _send_pending := false
var _sending := false

func _ready():
	$"%SendButton".connect("pressed", self, "send_message")

func _gui_input(event):
	if event is InputEventKey:
		if event.pressed and !event.echo:
			if event.is_action_pressed(Hotkeys.SEND_CHAT):
				_queue_send()
				return
			if event.unicode >= 32 or event.scancode == KEY_BACKSPACE:
				var now = OS.get_ticks_msec()
				if now - _last_key_sound_ms >= 45:
					_last_key_sound_ms = now
					$KeyboardSound.play()

func send_message():
	_queue_send()

func _queue_send():
	if _send_pending:
		return
	_send_pending = true
	call_deferred("_deferred_send")

func _deferred_send():
	_send_pending = false
	if _sending:
		return
	var outgoing = text.strip_edges()
	if outgoing == "":
		return
	_sending = true
	emit_signal("message_ready", outgoing)
	_sending = false

func clear_after_send():
	call_deferred("_clear_text")

func _clear_text():
	clear()
