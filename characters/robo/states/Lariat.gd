extends RobotState

func _frame_0():
	if host.initiative:
		host.start_aerial_attack_invulnerability()

func _frame_8():
	host.end_aerial_attack_invulnerability()
