extends VBoxContainer

signal data_changed()

export var centered = true

func _ready():
	if !centered:
		$Direction.min_value = 0
	$Label.text = name
	$Direction.connect("value_changed", self, "on_value_changed")
	pass # Replace with function body.

func on_value_changed(value):
	emit_signal("data_changed")
	$ValueLabel.text = str(value)

func get_value():
	return int($Direction.value)

func get_data():
	return {
		"x": get_value()
	}
