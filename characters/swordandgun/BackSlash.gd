extends CharacterState

func _frame_0():
	if host.read_advantage:
		host.start_invulnerability()

func _frame_6():
	host.end_invulnerability()
