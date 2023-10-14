extends RobotState

const DESCEND_SPEED = "13"
const MIN_HEIGHT = -20

var descending = false

func _frame_0():
	descending = false
#	can_fly = true

func _frame_3():
	descending = true
#	can_fly = false

func _tick():
	if descending:
		host.set_vel(fixed.mul(host.get_vel().x, "0.05"), DESCEND_SPEED)
		descending = false
		if host.flying_dir:
			host.flying_dir.x = 0
	host.apply_forces()
	if host.is_grounded():
		return "Landing"

#func is_usable():
#	return .is_usable() and host.get_pos().y < MIN_HEIGHT
