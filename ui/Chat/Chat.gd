extends Window


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var showing = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$"%ShowButton".connect("pressed", self, "toggle")
	$"%LineEdit".connect("message_ready", self, "on_message_ready")
	Network.connect("chat_message_received", self, "on_chat_message_received")
	if static_:
		$"%ShowButton".hide()
#	toggle()

func line_edit_focus():
	$"%LineEdit".grab_focus()

func on_chat_message_received(player_id: int, message: String):
	var color = "ff333d" if player_id == 2 else "1d8df5"
	var text = ProfanityFilter.filter(("<[color=#%s]" % [color]) + Network.pid_to_username(player_id) + "[/color]>: " + message)
	var node = RichTextLabel.new()
	node.bbcode_enabled = true
	node.append_bbcode(text)
	node.fit_content_height = true
	if !(player_id == Network.player_id):
		$"ChatSound".play()
	$"%MessageContainer".call_deferred("add_child", node)
	yield(get_tree(), 'idle_frame')
	yield(get_tree(), 'idle_frame')
	$"%ScrollContainer".scroll_vertical = 10000000000000000

func on_message_ready(message):
	$"%TooLongLabel".hide()
	if Network.multiplayer_active:
		if len(message) < 1000:
			$"%LineEdit".clear()
			Network.rpc_("send_chat_message", [Network.player_id, message])
		else:
			$"%TooLongLabel".show()
			$"%TooLongLabel".text = "message too long (" + str(len(message)) + "/1000)"

func toggle():
	visible = !visible
#	if showing:
#		$"%Contents".hide()
#		showing = false
#		yield(get_tree(), "idle_frame")
#		rect_size.y = 0
#	else:
#		$"%Contents".show()
#		showing = true
