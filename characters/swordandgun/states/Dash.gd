extends CharacterState

func _frame_0():
	host.move_directly(0, -1)
	host.set_grounded(false)
	if host.initiative:
		host.start_invulnerability()

func _frame_4():
	host.end_invulnerability()
