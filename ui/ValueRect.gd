extends TextureRect

var col

var mouse_pressed = false
var mouse_entered = false

var mouse_pos = Vector2()
var mouse_uv = Vector2()

var value = 1.0

onready var value_picker_rect = $"%ValuePickerRect"

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		mouse_pressed = true
		_update_from_mouse()
		accept_event()

func _input(event):
	if not mouse_pressed:
		return
	if event is InputEventMouseMotion:
		_update_from_mouse()
		get_tree().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
		mouse_pressed = false
		_update_from_mouse()


func _on_ValueRect_mouse_entered():
	mouse_entered = true
	pass # Replace with function body.

func _on_ValueRect_mouse_exited():
	mouse_entered = false
	pass # Replace with function body.

func _update_from_mouse():
	mouse_pos = get_local_mouse_position()
	mouse_pos.x = clamp(mouse_pos.x, 0, rect_size.x)
	mouse_pos.y = 0
	mouse_uv = mouse_pos
	mouse_uv.x /= rect_size.x
	mouse_uv.y = 0
	value = mouse_uv.x

func _process(delta):
	value_picker_rect.rect_position.x = mouse_pos.x - 1
	update()
