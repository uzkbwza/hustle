extends CharacterState

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()

func is_usable():
	return host.bullets_left > 0
