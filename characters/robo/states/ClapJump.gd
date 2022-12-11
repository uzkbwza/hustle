extends RobotState

const GRAV = "0.58"
const MAX_FALL_SPEED = "3.0"

func _frame_1():
	host.move_directly_relative(-10, 0)

func _frame_2():
	host.move_directly_relative(1, -3)
	host.set_grounded(false)

func _tick():
#	host.apply_force(0, 1)
	
	host.apply_grav_custom(GRAV, MAX_FALL_SPEED)
	if current_tick > 3 and host.is_grounded():
		return "ClapLand"
