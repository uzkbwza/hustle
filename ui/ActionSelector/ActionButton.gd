extends Control

class_name ActionButton

signal was_pressed(action)
signal toggled(on)
signal data_changed()

var action_name = ""
var action_title = ""

onready var initiative_texture = $"%InitiativeTexture"
onready var guard_break_texture = $"%GuardBreakTexture"

var data_node = null
var container = null
var custom_texture = false
var reversible = false
var flip_icon = true
var state = null
var is_guard_break = false
var has_initiative_effect = false

var earliest_hitbox = 0

func setup(name, title, texture=null):
	action_name = name
	action_title = title
	if texture:
		$"%TextureRect".texture = texture
		custom_texture = true
#	$"%Button".text = title
#	hint_tooltip = title
#	$"%Button".hint_tooltip = title

func end_setup():
	if guard_break_texture:
		guard_break_texture.visible = is_guard_break
	pass

func set_player_id(player_id):
	if player_id != 1 and custom_texture and flip_icon:
		$"%TextureRect".flip_h = true

func is_reversible():
	if state == null:
		return reversible
	return state.flip_allowed() and state.reversible

func set_pressed(on):
	$"%Button".pressed = on

func is_pressed():
	return $"%Button".pressed

func get_disabled():
	return $"%Button".disabled

func set_initiative(init):
	if initiative_texture == null:
		return
	initiative_texture.hide()
	has_initiative_effect = false
	if init and state.initiative_effect:
		initiative_texture.show()
		has_initiative_effect = true

func set_data_node(node):
	data_node = node
	if node:
		node.connect("data_changed", self, "emit_signal", ["data_changed"])

func get_data():
	if data_node:
		return data_node.get_data()
	return null

func _ready():
	$"%Button".connect("mouse_entered", self, "emit_signal", ["mouse_entered"])
	$"%Button".connect("mouse_exited", self, "emit_signal", ["mouse_exited"])
	$"%Button".connect("toggled", self, "on_toggled")
	connect("visibility_changed", self, "on_visibility_changed")

func on_visibility_changed():
	if state and state.flip_with_facing:
		$"%TextureRect".flip_h = state.host.get_opponent_dir() < 0 if state.host.opponent.current_state().name != "Grabbed" else state.host.get_facing_int() < 0

func on_toggled(on):
	emit_signal("toggled", on)
	emit_signal("was_pressed", action_name)

func set_pressed_no_signal(on):
	$"%Button".set_pressed_no_signal(on)


func set_disabled(on):
	$"%Button".set_disabled(on)
