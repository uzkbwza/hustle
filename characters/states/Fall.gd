extends CharacterState

func _tick():
	host.apply_grav()
	host.apply_forces()
	if current_tick > 1 and host.is_grounded():
		return "Landing"
