extends VBoxContainer

export var centered = true

func _ready():
	if !centered:
		$Direction.min_value = 0
	$Label.text = name
	$Direction.connect("value_changed", self, "on_value_changed")
	pass # Replace with function body.

func on_value_changed(value):
	$ValueLabel.text = str(value)

func get_value():
	return int($Direction.value)

func get_data():
	return {
		"x": get_value()
	}
