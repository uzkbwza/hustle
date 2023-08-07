extends CharacterState

onready var throw_box = $ThrowBox

const IS_GRAB = true
const DASH_LAG = 3
const DASH_SPEED = "14"
const JUMP_HEIGHT = "-10"

export var jump_grab = false

export var forward_throw_state = "ForwardThrow"
export var back_throw_state = "BackThrow"
export var down_throw_state = "AirDownThrow"

var dash_lag = 0

func _enter():
	if data == null:
		if _previous_state().get("IS_GRAB"):
			data = _previous_state().data
	if data is Dictionary:
		var dir = data if data.has("x") else data["Direction"]
		var dash = data.get("Dash")
		var jump = data.get("Jump")
		if dash and !jump:
			dash_lag = DASH_LAG
			host.apply_force_relative(DASH_SPEED, "0")
		if jump:
			if air_type == AirType.Grounded:
				return "JumpGrab"

		if dir.x == 0 and dir.y == 1:
			throw_box.throw_state = down_throw_state
		elif dir.x == host.get_facing_int() and dir.y == 0:
			throw_box.throw_state = forward_throw_state
		elif dir.x == -host.get_facing_int() and dir.y == 0:
			throw_box.throw_state = back_throw_state
	if jump_grab:
		host.apply_force_relative(DASH_SPEED, JUMP_HEIGHT)

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
