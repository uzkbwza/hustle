extends HBoxContainer

signal value_changed(value)

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var buttons = []

var button_pressed

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is BaseButton:
			buttons.append(child)
	for button in buttons:
		button.connect("pressed", self, "_on_button_pressed", [button])
		button.set_pressed_no_signal(false)
	get_node("%" + ("%sSpeed" % str(Global.ghost_speed))).set_pressed_no_signal(true)

	for button in buttons:
		if button.pressed:
			button_pressed = button

		
func _on_button_pressed(button):
	for b in buttons:
		b.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)
	button_pressed = button
	var speed =  get_speed()
	Global.ghost_speed = speed
	Global.save_options()
	emit_signal("value_changed", speed)

func get_speed():
	if button_pressed == $"%1Speed":
		return 1
	elif button_pressed == $"%2Speed":
		return 2
	elif button_pressed == $"%3Speed":
		return 3
	elif button_pressed == $"%4Speed":
		return 4
