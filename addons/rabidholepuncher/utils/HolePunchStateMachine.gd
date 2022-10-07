extends Node
class_name HolePunchStateMachine, "res://addons/rabidholepuncher/assets/state_machine.svg"
"""
Simplification of Generic State Machine from GDQuest
Credits to GDQuest for parts of this code
"""

export var initial_state: = NodePath()

onready var state: HolePunchState = get_node(initial_state) setget set_state
onready var _state_name: = state.name


func _init() -> void:
	add_to_group("state_machine")


func _ready() -> void:
	yield(owner, "ready")
	state.enter()


func _process(delta: float) -> void:
	state.process(delta)


func transition_to(target_state_path: String, msg: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		return
	var target_state: = get_node(target_state_path)
	state.exit()
	state = target_state
	state.enter(msg)


func set_state(value: HolePunchState) -> void:
	state = value
	_state_name = state.name
