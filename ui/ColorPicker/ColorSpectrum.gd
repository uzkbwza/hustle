extends ColorRect

var mouse_entered = false
var mouse_pressed = false
var picked = false
var mouse_pos = Vector2()
var mouse_uv = Vector2()

var col = Color.white

var value = 1.0

func update_color():
	col = Vector3();

	# Use polar coordinates instead of cartesian
	var toCenter = Vector2(0.5, 0.5) - mouse_uv
	var angle = atan2(toCenter.y,toCenter.x)
	var radius = toCenter.length()*2.0

	# Map the angle (-PI to PI) to the Hue (from 0 to 1)
	# and the Saturation to the radius
	col = Color.from_hsv((angle/TAU)+0.5,radius,value);

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		mouse_pressed = true
		picked = true
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


func _on_ColorSpectrum_mouse_entered():
	mouse_entered = true
	pass # Replace with function body.


func _on_ColorSpectrum_mouse_exited():
	mouse_entered = false
	pass # Replace with function body.

func _update_from_mouse():
	mouse_pos = get_local_mouse_position()
	mouse_pos.x = clamp(mouse_pos.x, 0, rect_size.x)
	mouse_pos.y = clamp(mouse_pos.y, 0, rect_size.y)
	mouse_uv = mouse_pos
	mouse_uv.x /= rect_size.x
	mouse_uv.y /= rect_size.y
	update_color()

func _process(delta):
	update()
