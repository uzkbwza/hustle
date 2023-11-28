extends Node

class_name StateInterface

# State interface for StateMachine
onready var state_name = name

#export var animation = "" setget , get_animation
var animation = ""

var host
var active = false
var data = null
var initialized = false
var queued_state = null

signal queue_change(state, self_)
signal queue_change_with_data(state, data, self_)

func get_animation():
	if animation == "":
		return get_name()
	else:
		return animation

func queue_state_change(state, data=null):
	queued_state = state
	if data == null:
		emit_signal("queue_change", state, self)
		return
	emit_signal("queue_change_with_data", state, data, self)

func _previous_state_name():
	return get_parent().states_stack[-2].name if get_parent().states_stack.size() > 1 else ""

func _previous_state():
	if get_parent().states_stack.size() > 1:
		return get_parent().states_stack[-2]

func init():
	initialized = true
	pass

func _enter_tree():
	host = get_parent().host

func _exit_tree():
	if active:
		_exit()

# virtual state logic methods

#######################
# shared methods for a state type. these will be called for every subclass of this state type, 
# before their individual methods
func _enter_shared():
	pass

func _update_shared(_delta):
	pass

# for fixed_step games
func _tick_shared():
	pass

func _integrate_shared(_state):
	# To use with _integrate_forces(state)
	pass

func _exit_shared():
	#  Cleanup and exit state
	pass
#######################

func _enter():
	# Initialize state 
	pass

func _tick_before():
	pass

# for fixed_step games
func _tick():
	pass

func _tick_after():
	pass

func _update(_delta):
	#  To use with _process or _physics_process
	pass
	
func _integrate(_state):
	# To use with _integrate_forces(state)
	pass

func _exit():
	#  Cleanup and exit state
	pass

func _animation_finished():
	pass
