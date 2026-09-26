extends "res://SoupModOptions/OptionTypes/ModOptionObject.gd"

var label:Label
var lineedit:LineEdit

func _build():
	var vsep = VBoxContainer.new()
	label = Label.new()
	lineedit = LineEdit.new()
	
	label.text = display_name
	lineedit.text = current_value
	vsep.add_child(label)
	vsep.add_child(lineedit)
	add_child(vsep)
	
	lineedit.connect("text_changed", self, "option_changed")
	
func option_changed(value):
	current_value = value
	emit_signal("option_changed", fullpath, value)
	
func set_value(value:String):
	current_value = value
	lineedit.text = value
	
func get_value_for_save():
	return current_value
