extends TextureRect

var col

var mouse_pressed = false
var mouse_entered = false

var mouse_pos = Vector2()
var mouse_uv = Vector2()

var value = 1.0

onready var value_picker_rect = $"%ValuePickerRect"

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			mouse_pressed = event.pressed
			

func _on_ValueRect_mouse_entered():
	mouse_entered = true
	pass # Replace with function body.

func _on_ValueRect_mouse_exited():
	mouse_entered = false
	pass # Replace with function body.

func _process(delta):
	if mouse_entered and mouse_pressed:
		mouse_pos = get_local_mouse_position()
		mouse_pos.x = clamp(mouse_pos.x, 0, rect_size.x)
		mouse_pos.y = 0
		mouse_uv = mouse_pos
		mouse_uv.x /= rect_size.x
		mouse_uv.y = 0
		value = mouse_uv.x
	value_picker_rect.rect_position.x = mouse_pos.x - 1
	update()
