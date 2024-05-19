extends RobotState

const DESCEND_SPEED = "13"
const MIN_HEIGHT = -20

var descending = false
var apply_gravity = false

func _frame_0():
	descending = false
	apply_gravity = false
#	can_fly = true

func _frame_3():
	descending = true
#	can_fly = false

func _tick():
	if descending:
		host.set_vel(fixed.mul(host.get_vel().x, "0.05"), DESCEND_SPEED)
		descending = false
		if host.flying_dir:
			host.flying_dir = { "x": 0, "y": host.flying_dir.y }

	if fixed.lt(host.get_vel().y, "0"):
		apply_gravity = true

	if host.flying_dir == null and apply_gravity:
		host.apply_grav()

	host.apply_forces()
	if host.is_grounded():
		return "Landing"

#func is_usable():
#	return .is_usable() and host.get_pos().y < MIN_HEIGHT

func on_got_perfect_parried():
	host.hitlag_ticks += 4
