extends CharacterState

func _tick():
	host.apply_grav()
	host.apply_forces()
	if host.is_grounded():
		return "Landing"
