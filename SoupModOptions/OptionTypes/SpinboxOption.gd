#tool
extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var spinbox:SpinBox
var label:Label
# spinbox vars
export var min_value = 0
export var max_value = 100
export var step = 1
export var value = 0
export var exp_edit = false
export var rounded = true
export var allow_greater = false
export var allow_lesser = false

# Called when the node enters the scene tree for the first time.
func _build():
	name = internal_name
	var hsep = HBoxContainer.new()
	label = Label.new()
	spinbox = SpinBox.new()
	hsep.add_child(label)
	hsep.add_child(spinbox)
	add_child(hsep)
	hsep.size_flags_horizontal = 3
	label.size_flags_horizontal = 3
	spinbox.size_flags_horizontal = 3
	spinbox.size_flags_stretch_ratio = 0.4
	label.text = display_name
	spinbox.min_value = min_value
	spinbox.max_value = max_value
	spinbox.step = step
	spinbox.value = value
	spinbox.exp_edit = exp_edit
	spinbox.rounded = rounded
	spinbox.allow_greater = allow_greater
	spinbox.allow_lesser = allow_lesser
	
	spinbox.connect("value_changed", self, "option_changed")
	
#func _process(delta):
#	if Engine.editor_hint:
#		$"Label".text = text
#		$"SpinBox".min_value = min_value
#		$"SpinBox".max_value = max_value
#		$"SpinBox".step = step
#		$"SpinBox".value = value
#		$"SpinBox".exp_edit = exp_edit
#		$"SpinBox".rounded = rounded
#		$"SpinBox".allow_greater = allow_greater
#		$"SpinBox".allow_lesser = allow_lesser

func option_changed(value):
	current_value = value
	emit_signal("option_changed", fullpath, value)

func set_value(value):
	current_value = value
	spinbox.value = value



