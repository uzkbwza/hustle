extends RobotState

func _frame_4():
	if host.initiative:
		host.start_aerial_attack_invulnerability()

func _frame_15():
	host.end_aerial_attack_invulnerability()
