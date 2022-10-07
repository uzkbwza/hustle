class_name EC_CreateCategory
extends EditorProperty

var category_material = preload("res://addons/export_categories/ec_category_material.tres")


func _init():
	set_process(false)


func _process(_delta: float) -> void:
	pass


func update_property() -> void:
	label = update_label(label)
	
	# Make non-editable
	read_only = true
	
	# Material for setting blend mode to "add"
	material = category_material
	
	# Red just to make some contrast
	draw_red = true
	


func update_label(label: String) -> String:
	var previous_label = label
	var trimmed_label =  previous_label.trim_prefix("C").trim_prefix(" ")
	
	# Remove the _c_ from the label
	var new_label = trimmed_label
	
	# Totaly arbitrary amount of █
	var prefix = '[ '
	var suffix = ' ]'
	
	# Concatenate prefix + new_label + suffix
	new_label = str(prefix, new_label, suffix)
	
	
	# Return the new label
	return new_label
