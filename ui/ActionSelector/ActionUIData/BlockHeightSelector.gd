extends Control

signal data_changed()

onready var high = $High
onready var low = $Low

func get_value():
	return { "x": 0, "y": 0 if high.pressed else 1 }
	
func get_data():
	return { "x": 0, "y": 0 if high.pressed else 1 }

func set_height(on: bool):
	if on:
		_on_High_toggled(on)
	else:
		_on_Low_toggled(on)

func _on_High_toggled(button_pressed):
	high.set_pressed_no_signal(true)
	low.set_pressed_no_signal(false)
	emit_signal("data_changed")

func _on_Low_toggled(button_pressed):
	high.set_pressed_no_signal(false)
	low.set_pressed_no_signal(true)
	emit_signal("data_changed")
