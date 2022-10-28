extends WizardState

const SPEED = "12"

func is_usable():
	return .is_usable() and host.orb_projectile and !is_locked()

func _frame_1():
	if host.orb_projectile:
		var orb = host.objs_map[host.orb_projectile]
		var force = fixed.normalized_vec_times(str(data.x), str(data.y), SPEED)
		orb.push(force.x, force.y)

func is_locked():
	if host.orb_projectile:
		return host.objs_map[host.orb_projectile].locked
