extends CharacterState

onready var throw_box = $ThrowBox

export var forward_throw_state = "ForwardThrow"
export var back_throw_state = "BackThrow"
export var down_throw_state = "AirDownThrow"

func _enter():
	if data is Dictionary:
		if data.x == 0 and data.y == 1:
			throw_box.throw_state = down_throw_state
		elif data.x == host.get_facing_int() and data.y == 0:
			throw_box.throw_state = forward_throw_state
		elif data.x == -host.get_facing_int() and data.y == 0:
			throw_box.throw_state = back_throw_state

func _frame_1():
	throw_techable = true

func _frame_9():
	throw_techable = false

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	if started_in_air and air_type == AirType.Aerial:
		if host.is_grounded():
			queue_state_change("Landing", 6)
