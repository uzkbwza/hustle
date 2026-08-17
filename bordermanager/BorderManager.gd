extends Viewport



func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	_on_screen_resized()




func _on_screen_resized():
	size = OS.window_size
	
	VisualServer.viewport_set_size(get_viewport_rid(), size.x, size.y)
	VisualServer.viewport_attach_to_screen(get_viewport_rid(), Rect2(Vector2.ZERO, size))
	VisualServer.black_bars_set_margins(0, 0, 0, 0)

