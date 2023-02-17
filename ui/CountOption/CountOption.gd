extends VBoxContainer

signal data_changed()

export var min_value = 0
export var max_value = 10

var buffer_value_changed = false

func _ready():
	$Label.text = name
	update_values()
	$HSlider.connect("value_changed", self, "on_value_changed")
	on_value_changed($HSlider.value)

func update_values():
	$HSlider.min_value = min_value
	$HSlider.max_value = max_value

func on_value_changed(value):
	buffer_value_changed = true
	$ValueLabel.text = str(value)

func _process(_delta):
	if buffer_value_changed and !Input.is_mouse_button_pressed(BUTTON_LEFT):
		emit_signal("data_changed")
		buffer_value_changed = false

func get_value():
	return int($HSlider.value)
	
func get_data():
	return {
		"count": get_value()
	}
