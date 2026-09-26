#tool
extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var slider:HSlider
var label:Label
var spinbox:SpinBox
# slider vars
var min_value = 0
var max_value = 100
var step = 1
var value = 0
var exp_edit = false
var rounded = true
var allow_greater = false
var allow_lesser = false

func _build():
	name = internal_name
	var vsep = VBoxContainer.new()
	var hsep = HBoxContainer.new()
	spinbox = SpinBox.new()
	label = Label.new()
	slider = HSlider.new()
	hsep.add_child(label)
	hsep.add_child(spinbox)
	vsep.add_child(hsep)
	vsep.add_child(slider)
	add_child(vsep)
	vsep.size_flags_horizontal = 3
	label.size_flags_horizontal = 3
	slider.size_flags_horizontal = 3
	spinbox.size_flags_stretch_ratio = 0.4
	label.text = display_name
	
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = value
	slider.exp_edit = exp_edit
	slider.rounded = rounded
	slider.allow_greater = allow_greater
	slider.allow_lesser = allow_lesser
	
	slider.share(spinbox)
	
	slider.connect("value_changed", self, "option_changed")
	

func option_changed(value):
	set_value(value)
	emit_signal("option_changed", fullpath, value)

func set_value(value):
	current_value = value
	slider.value = value




