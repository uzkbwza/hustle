extends VBoxContainer

signal data_changed()

onready var default = $Direction.value

export var centered = true

export var min_value = 0
export var max_value = 100

var buffer_value_changed = false

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_RIGHT and $Direction.get_rect().has_point(get_local_mouse_position()):
			$Direction.value = default

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
