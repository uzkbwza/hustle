extends PanelContainer

export var internal_name:String
export var display_name:String
var default_value
var current_value
var fullpath:String
var ignore = false

signal option_changed

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		name = internal_name
		current_value = default_value
		theme_type_variation = "InvisPanelContainer"
		size_flags_horizontal = SIZE_EXPAND_FILL
		_build()

func _build():
	pass

func _ready():
	
	pass

func get_value_for_save():
	return current_value

