extends Control

signal pressed(action)
signal toggled(on)

var action_name = ""
var action_title = ""

var data_node = null
var container = null

func setup(name, title):
	action_name = name
	action_title = title
	$"%Button".text = title

func set_pressed(on):
	$"%Button".pressed = on

func is_pressed():
	return $"%Button".pressed

func get_disabled():
	return $"%Button".disabled

func get_data():
	if data_node:
		return data_node.get_data()
	return null

func _ready():
	$"%Button".connect("pressed", self, "on_pressed")
	$"%Button".connect("mouse_entered", self, "emit_signal", ["mouse_entered"])
	$"%Button".connect("mouse_exited", self, "emit_signal", ["mouse_exited"])
	$"%Button".connect("toggled", self, "on_toggled")

func on_toggled(on):
	emit_signal("toggled", on)

func on_pressed():
	emit_signal("pressed", action_name)

func set_pressed_no_signal(on):
	$"%Button".set_pressed_no_signal(on)


func set_disabled(on):
	$"%Button".set_disabled(on)
