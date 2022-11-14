extends CharacterState

func _frame_0():
	host.start_invulnerability()
	
func _tick():
	host.apply_fric()
	host.apply_forces()
