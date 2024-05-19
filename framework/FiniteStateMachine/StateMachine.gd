extends Node

class_name StateMachine

const STACK_SIZE = 32

var states_stack = []
var states_map = {}
var state
var queued_states = []
var queued_data = []

var initialized = false

signal state_changed(states_stack)
signal state_exited(state)

export var starting_state: String = ""
export var host_node_path: NodePath
# if you are using both of these, make sure you don't update the 
# AnimatedSprite's current animation with the AnimationPlayer - this will be 
# done automatically if the state name matches the animation name.
export var animation_player_path: NodePath
export var animated_sprite_path: NodePath

var animated_sprite
var animation_player

var is_ready = false
var host

#class QueuedState:
#	var state: StateInterface
#	var predicate_object: Object = self
#	var predicate_method: String = "p"
#
#	func p():
#		return true
#
#	func _init(state):
#		self.state = state

func _ready():
	is_ready = true

func _enter_tree():
	var custom_host = get_node_or_null(host_node_path)
	if !is_instance_valid(custom_host):
		host = get_parent()
	else:
		host = custom_host

#func _init():
#	# Must be called with array of states before anything.
#	# The first state in the array is the starting state for the machine.
#	var states_array = get_children()
#	if states_array.size() == 0:
#		call_deferred("add_child", StateInterface.new())
#		call_deferred("init")
#		return
#
#	var state_name
#	for new_state in states_array:
#		if new_state is StateInterface:
#			states_map[state_name] = new_state
#			new_state.queue_change.connect(queue_state)
#		else:
#			print("Invalid state %s for node %s" % [new_state.get_name(), host.get_name()])
#			new_state.queue_free()
#	_change_state(states_array[0].name)
#
#	initialized = true

func init(st: String = "", data=null) -> bool:
	if !is_ready:
		yield(self, "ready")
	if initialized:
		return
	if starting_state:
		st = starting_state
	var can_initialize = false
	var states_array = get_children()
	if states_array == []:
		queue_free()
		return false
	for new_state in states_array:
		if new_state is StateInterface:
			states_map[new_state.get_name()] = new_state
			can_initialize = true
			new_state.connect("queue_change", self, "queue_state")
			new_state.connect("queue_change_with_data", self, "queue_state")
			new_state.host = host
			new_state.init()
		else:
			print("Invalid state %s for node %s" % [new_state.get_name(), host.get_name()])
			new_state.queue_free()
			states_array.erase(new_state)
	if !can_initialize:
		queue_free()
		return false
		
	animated_sprite = weakref(get_node_or_null(animated_sprite_path))
	animation_player = weakref(get_node_or_null(animation_player_path))
	
	var a = self.animation_player.get_ref()
	if a != null:
		a.connect("animation_finished", self, "auto_transition")

	if st != "":
		_change_state(states_map[st].get_name(), data)
	else:
		_change_state(states_array[0].get_name(), data)
	initialized = true
	return true

func auto_transition(_anim_name):
	var next = state._animation_finished()
	if next:
		queue_state(next)

func queue_state(new_state, data=null, old_state=state):
	if old_state.active:
		queued_states = []
		queued_data = []
		queued_states.push_back(new_state)
		queued_data.append(data)

func update(delta):
	if queued_states.size() > 0:
		var state = queued_states.pop_front()
		var data = queued_data.pop_front()
		_change_state(state, data)
	var next_state_name = state._update_shared(delta)
	if next_state_name == null:
		next_state_name = state._update(delta)
	if next_state_name:
		queue_state(next_state_name)

func tick():
	if queued_states.size() > 0:
		var state = queued_states.pop_front()
		var data = queued_data.pop_front()
		_change_state(state, data)
	state._tick_before()
	var next_state_name = state._tick_shared()
	if next_state_name == null:
		next_state_name = state._tick()
	if next_state_name == null:
		next_state_name = state._tick_after()
	if next_state_name:
		queue_state(next_state_name)

func deactivate():
	state.active = false
	state._exit_shared()
	state._exit()
	emit_signal("state_exited", state)

func integrate(st):
	state._integrate_shared(st)
	state._integrate(st)

func _change_state(state_name: String, data=null, enter=true, exit=true) -> void:
	assert(states_map.has(state_name), "you tried to enter a state that doesn't exist, CHUMP")
	if !states_map.has(state_name):
		return
	var next_state = states_map[state_name]
	queued_states = []
	queued_data = []

	if state:
		if exit:
			state._exit_shared()
			state._exit()
			emit_signal("state_exited", state)
		state.active = false
		state.set_physics_process(false)
		state.set_process(false)

	state = next_state
	states_stack.push_back(state)
	if states_stack.size() > STACK_SIZE:
		states_stack.pop_front()
	state.active = true
	state.set_physics_process(true)
	state.set_process(true)
#	Debug.dbg("stack size", states_stack.size())
	
#	var animation_player = self.animation_player.get_ref()
#	if animation_player != null:
##		if animation_player.has_animation("RESET"):
##			animation_player.play("RESET")
#		if animation_player.has_animation(state.animation):
#			animation_player.play.call_deferred(state.animation)
#	var animated_sprite = self.animated_sprite.get_ref()
#	if animated_sprite != null and animated_sprite.frames.has_animation(state.animation):
#		animated_sprite.frame = 0
#		animated_sprite.play.call_deferred(state.animation)

	state.data = data

	if enter:
		var new_state = state._enter_shared()
		if new_state:
			_change_state(new_state)
			return
		new_state = state._enter()
		if new_state:
			_change_state(new_state)
			return
	
	emit_signal("state_changed", states_stack)

func try(method: String, args: Array = []):
	if state.has_method(method):
		state.callv(method, args)

func last_x_states(x, names=true):
	var states = states_stack.slice(-x, states_stack.size())
	if names:
		var s = []
		for state in states:
			s.append(state.name)
		states = s
	states.reverse()
	return states

func get_state(state_name):
	if states_map.has(state_name):
		return states_map[state_name]
