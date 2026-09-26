extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var align = Label.ALIGN_CENTER
var label:Label
var color = Color.white

func _build():
	ignore = true # don't save anything for this value.
	
	label = Label.new()
	add_child(label)
	label.autowrap = true
	label.text = display_name
	label.size_flags_horizontal = 3
	label.align = align
	label.add_color_override("font_color", color)
