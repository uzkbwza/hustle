extends VBoxContainer

signal data_changed()

export var centered = true

var buffer_value_changed = false

func _ready():
	if !centered:
		$Direction.min_value = 0
	$Label.text = name
	$Direction.connect("value_changed", self, "on_value_changed")
	pass # Replace with function body.

func on_value_changed(value):
	buffer_value_changed = true
	$ValueLabel.text = str(value)

func _process(_delta):
	if buffer_value_changed and !Input.is_mouse_button_pressed(BUTTON_LEFT):
		emit_signal("data_changed")
		buffer_value_changed = false

func get_value():
	return int($Direction.value)

func get_data():
	return {
		"x": get_value()
	}
