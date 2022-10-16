extends Control

signal data_changed()

export var NW = true
export var N = true
export var NE = true
export var W = true
export var Neutral = true
export var E = true
export var SW = true
export var S = true
export var SE = true

export var consider_facing = true

var facing = 1
var pressed_button = null

func _ready():
	for button in get_buttons():
		button.connect("pressed", self, "_on_button_pressed", [button])
	$Label.text = name
	init()
	_on_button_pressed($"%Neutral")

func init():
#	pressed_button = null
	for button in get_buttons():
		button.disabled = false
	
	for dir in ["NW", "N", "NE", "W", "Neutral", "E", "SW", "S", "SE"]:
		var button = get_node("%"+dir)
		if !get(dir):
			var disabled_button = get_node("%" + dir_to_facing(dir)) if consider_facing else button
			if disabled_button == pressed_button:
				pressed_button = null
			disabled_button.disabled = true
			
			continue
		if pressed_button == null or pressed_button.disabled:
			button.pressed = true
			_on_button_pressed(button)
	
	$"%Top".show()
	$"%Middle".show()
	$"%Bottom".show()

	try_hide_section($"%Top")
	try_hide_section($"%Middle")
	try_hide_section($"%Bottom")

func try_hide_section(section):
	var hidden = true
	for button in section.get_children():
		if !button.disabled:
			hidden = false
	if hidden:
		section.hide()

func dir_to_facing(dir):
	if facing > 0:
		return dir
	match dir:
		"NW": return "NE"
		"NE": return "NW"
		"W": return "E"
		"E": return "W"
		"SW": return "SE"
		"SE": return "SW"
	return dir

func _on_button_pressed(button):
	emit_signal("data_changed")
	for b in get_buttons():
		if button != b:
			b.pressed = false
	button.set_pressed_no_signal(true)
	pressed_button = button

func get_buttons():
	var buttons = []
	buttons.append_array($"%Top".get_children())
	buttons.append_array($"%Middle".get_children())
	buttons.append_array($"%Bottom".get_children())
	return buttons

func get_value(dir):
	match dir:
		"NW": return get_vec_int(-1, -1)
		"N": return get_vec_int(0, -1)
		"NE": return get_vec_int(1, -1)
		"W": return get_vec_int(-1, 0)
		"Neutral": return get_vec_int(0, 0)
		"E": return get_vec_int(1, 0)
		"SW": return get_vec_int(-1, 1)
		"S": return get_vec_int(0, 1)
		"SE": return get_vec_int(1, 1)

func get_data():
	return get_value(pressed_button.name) if pressed_button else "Neutral"

func get_vec_int(x: int, y: int):
	return {
		"x": x,
		"y": y,
	}
