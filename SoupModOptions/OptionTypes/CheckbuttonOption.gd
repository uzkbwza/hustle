extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var btn:CheckButton

func _build():
	btn = CheckButton.new()
	btn.text = display_name
	btn.pressed = current_value
	btn.mouse_filter = MOUSE_FILTER_PASS
	add_child(btn)
	btn.connect("toggled",self,"option_changed")
	
func option_changed(value):
	set_value(value)
	emit_signal("option_changed", fullpath, value)
	
func set_value(value:bool):
	btn.pressed = value
	current_value = value

