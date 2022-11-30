extends ColorRect

var mouse_entered = false
var mouse_pressed = false
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

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			mouse_pressed = event.pressed
			

func _on_ColorSpectrum_mouse_entered():
	mouse_entered = true
	pass # Replace with function body.


func _on_ColorSpectrum_mouse_exited():
	mouse_entered = false
	pass # Replace with function body.

func _process(delta):
	if mouse_entered and mouse_pressed:
		mouse_pos = get_local_mouse_position()
		mouse_pos.x = clamp(mouse_pos.x, 0, rect_size.x)
		mouse_pos.y = clamp(mouse_pos.y, 0, rect_size.y)
		mouse_uv = mouse_pos
		mouse_uv.x /= rect_size.x
		mouse_uv.y /= rect_size.y
		update_color()
	update()
