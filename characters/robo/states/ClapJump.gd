extends RobotState

const GRAV = "0.58"
const STARTED_IN_AIR_GRAV = "0.80"
const MAX_FALL_SPEED = "3.0"
const STARTED_IN_AIR_MAX_FALL_SPEED = "8.0"

var jumping = false
var grav = GRAV
var max_fall_speed = MAX_FALL_SPEED

func _frame_0():
	grav = GRAV if host.is_grounded() else STARTED_IN_AIR_GRAV
	max_fall_speed = MAX_FALL_SPEED if host.is_grounded() else STARTED_IN_AIR_MAX_FALL_SPEED
	host.set_grounded(false)
	jumping = true

func _frame_1():
	host.move_directly_relative(-10, 0)

func _frame_2():
	host.move_directly_relative(1, -3)

func _frame_3():
	var force = fixed.normalized_vec_times("1.0", "-0.25", "8.0")
	if data.x * host.get_facing_int() == -1:
		force.x = fixed.mul(force.x, "-0.55")
	host.apply_force_relative(force.x, force.y)

func _tick():
#	host.apply_force(0, 1)
	
	host.apply_grav_custom(grav, max_fall_speed)
	if jumping and current_tick >= 10:
		current_tick = 9
	if jumping and current_tick > 1 and host.is_grounded():
		jumping = false
		host.big_landing_effect()
