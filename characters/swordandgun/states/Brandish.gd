extends CharacterState

func _frame_0():
	if host.bullets_left <= 0:
		fallback_state = "SlowHolster"
	else:
		fallback_state = "Shoot"

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()

func is_usable():
	return (host.bullets_left > 0 or host.supers_available > 0) and host.has_gun
