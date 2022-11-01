extends Control

class_name ActionButton

signal was_pressed(action)
signal toggled(on)
signal data_changed()

var action_name = ""
var action_title = ""

var data_node = null
var container = null
var custom_texture = false
var reversible = false

func setup(name, title, texture=null):
	action_name = name
	action_title = title
	if texture:
		$"%TextureRect".texture = texture
		custom_texture = true
#	$"%Button".text = title

func set_player_id(player_id):
	if player_id != 1 and custom_texture:
		$"%TextureRect".flip_h = true

func set_pressed(on):
	$"%Button".pressed = on

func is_pressed():
	return $"%Button".pressed

func get_disabled():
	return $"%Button".disabled

func set_data_node(node):
	data_node = node
	if node:
		node.connect("data_changed", self, "emit_signal", ["data_changed"])

func get_data():
	if data_node:
		return data_node.get_data()
	return null

func _ready():
#	$"%Button".connect("pressed", self, "on_pressed")
	$"%Button".connect("mouse_entered", self, "emit_signal", ["mouse_entered"])
	$"%Button".connect("mouse_exited", self, "emit_signal", ["mouse_exited"])
	$"%Button".connect("toggled", self, "on_toggled")

func on_toggled(on):
	emit_signal("toggled", on)
	emit_signal("was_pressed", action_name)

#func on_pressed():
#	emit_signal("was_pressed", action_name)

func set_pressed_no_signal(on):
	$"%Button".set_pressed_no_signal(on)


func set_disabled(on):
	$"%Button".set_disabled(on)
