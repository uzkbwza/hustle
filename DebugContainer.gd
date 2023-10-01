extends HBoxContainer

func _input(event):
	if event.is_action_pressed("open_debug_panel") and OS.is_debug_build():
		visible = !visible
