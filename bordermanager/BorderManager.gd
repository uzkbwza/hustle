extends Viewport


func _ready():
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	Global.connect("option_changed", self, "_on_option_changed")
	_on_screen_resized()
	_on_option_changed("show_border_art", Global.show_border_art)



func _on_option_changed(option, value):
	if option == "show_border_art":
		$BorderArt.visible = value



func _on_screen_resized():
	var win_size = OS.window_size
	var target_aspect = Global.RESOLUTION.x / Global.RESOLUTION.y
	var current_aspect = win_size.x / win_size.y
	if current_aspect > target_aspect:
		size = Vector2(Global.RESOLUTION.y * current_aspect, Global.RESOLUTION.y)
	else:
		size = Vector2(Global.RESOLUTION.x, Global.RESOLUTION.x * (1/current_aspect))
	VisualServer.viewport_set_size(get_viewport_rid(), size.x, size.y)
	VisualServer.viewport_attach_to_screen(get_viewport_rid(), Rect2(Vector2.ZERO, win_size))
	VisualServer.black_bars_set_margins(0, 0, 0, 0)



func show_character_art():
	$BorderArt.show_character_art()

func show_menu_art():
	$BorderArt.show_menu_art()



func set_style_params(id, params):
	$BorderArt.set_style_params(id, params)

func apply_style(id, style):
	$BorderArt.apply_style(id, style)

func set_border_background(id, tex):
	$BorderArt.set_border_background(id, tex)
	
func set_border_art(id, tex):
	$BorderArt.set_border_art(id, tex)


