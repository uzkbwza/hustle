extends Label

const RECT_PADDING = 2
const RECT_COLOR = Color("4464d26b")

var help_text

func _ready():
	help_text = text
	text = ""

func _process(delta):
	update()

func _draw():
	draw_rect(Rect2(Vector2(-RECT_PADDING, -RECT_PADDING), rect_size + Vector2.ONE * RECT_PADDING), RECT_COLOR, false, 2.0, false)

func _on_HelpText_mouse_entered():
	text = help_text
	pass # Replace with function body.

func _on_HelpText_mouse_exited():
	text = ""
	pass # Replace with function body.
