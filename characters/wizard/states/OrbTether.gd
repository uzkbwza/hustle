extends WizardState

const FALLOFF = "0.95"
const SPEED = "1.25"

func is_usable():
	return .is_usable() and host.orb_projectile and (host.is_grounded() or host.air_movements_left > 0)

func _frame_0():
	if !host.is_grounded():
		host.air_movements_left -= 1
	interruptible_on_opponent_turn = false
	host.move_directly(0, -1)
	host.set_grounded(false)

func _tick():
	if host.orb_projectile:
		var orb = host.objs_map[host.orb_projectile]
		if !orb.disabled:
			var dir = host.obj_local_center(orb)
			var force = fixed.normalized_vec_times(str(dir.x), str(dir.y), fixed.mul(SPEED, fixed.powu(FALLOFF, current_tick)))
			host.apply_force(force.x, force.y)
	if current_tick > 8:
		if host.is_grounded():
			return "Landing"
		interruptible_on_opponent_turn = true
