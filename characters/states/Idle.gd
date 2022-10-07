extends CharacterState

func _tick():
	host.apply_fric()
	host.apply_forces()
	if !host.is_grounded():
		return "Fall"
