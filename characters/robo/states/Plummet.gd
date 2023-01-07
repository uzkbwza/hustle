extends RobotState

const DESCEND_SPEED = "13"
const MIN_HEIGHT = -20

var descending = false

func _frame_0():
	descending = false

func _frame_3():
	descending = true

func _tick():
	if descending:
		host.set_vel("0", DESCEND_SPEED)
	host.apply_forces()
	if host.is_grounded():
		return "Landing"

#func is_usable():
#	return .is_usable() and host.get_pos().y < MIN_HEIGHT
