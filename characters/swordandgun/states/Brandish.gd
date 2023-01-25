extends SuperMove

export var quicker = false

func _frame_0():
	if !quicker and (host.bullets_left <= 0 or !host.is_ghost):
		fallback_state = "SlowHolster"
	else:
		fallback_state = "Shoot"

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()

func is_usable():
	return .is_usable() and (host.bullets_left > 0 or host.supers_available > 0) and host.has_gun
