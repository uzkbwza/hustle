extends LineEdit

signal message_ready(message)

func _ready():
	$"%SendButton".connect("pressed", self, "send_message")

func _gui_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_ENTER:
				send_message()
		$KeyboardSound.play()

func send_message():
	if text.strip_edges() == "":
		return
	emit_signal("message_ready", text.strip_edges())
