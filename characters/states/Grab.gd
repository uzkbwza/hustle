extends CharacterState

onready var throw_box = $ThrowBox

const DASH_LAG = 3
const DASH_SPEED = "14"

export var forward_throw_state = "ForwardThrow"
export var back_throw_state = "BackThrow"
export var down_throw_state = "AirDownThrow"

var dash_lag = 0

func _enter():
	if data is Dictionary:
		var dir = data if data.has("x") else data["Direction"]
		var dash = data.get("Dash")
		if dash:
			dash_lag = DASH_LAG
			host.apply_force_relative(DASH_SPEED, "0")

		if dir.x == 0 and dir.y == 1:
			throw_box.throw_state = down_throw_state
		elif dir.x == host.get_facing_int() and dir.y == 0:
			throw_box.throw_state = forward_throw_state
		elif dir.x == -host.get_facing_int() and dir.y == 0:
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
	if dash_lag > 0:
		current_tick = 0
		dash_lag -= 1
