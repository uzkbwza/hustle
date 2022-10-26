extends WizardState

export var locks_orb = false

func is_usable():
	return .is_usable() and host.orb_projectile and !is_locked() if locks_orb else is_locked()

func _frame_1():
	if host.orb_projectile:
		var orb = host.objs_map[host.orb_projectile]
		if locks_orb:
			orb.lock()
		else:
			orb.unlock()

func is_locked():
	if host.orb_projectile:
		return host.objs_map[host.orb_projectile].locked
