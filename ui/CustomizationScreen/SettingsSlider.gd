extends Control

class_name SettingsSlider

signal value_changed(value)

onready var slider = $"%HSlider"
onready var value = $"%HSlider".value
var mouse_entered = false

export var default_value = 0.0
export var min_value = 0.0
export var max_value = 100.0
export var step = 0.01

# Called when the node enters the scene tree for the first time.
func _ready():
	slider.min_value = min_value
	slider.max_value = max_value
	slider.value = default_value
	slider.step = step
	$"%Label".text = name
	$"%Value".text = str(value)

func _on_HSlider_value_changed(value):
	self.value = value
	emit_signal("value_changed", value)
	$"%Value".text = str(value)

func set_value(value):
	slider.value = value
	_on_HSlider_value_changed(value)

func get_data():
	return value

#func _input(event):
#	if !mouse_entered:
#		return
#	if event is InputEventMouseButton:
#		if event.pressed:
#			if event.button_index == BUTTON_RIGHT:

#
#
#func _on_SettingsSlider_mouse_entered():
#	mouse_entered = true
#	pass # Replace with function body.
#
#
#func _on_SettingsSlider_mouse_exited():
#	mouse_entered = false
	pass # Replace with function body.


func _on_ResetButton_pressed():
	slider.value = default_value
	_on_HSlider_value_changed(default_value)
