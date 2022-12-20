extends RobotState

func _frame_0():
	host.start_throw_invulnerability()

func _frame_9():
	host.end_throw_invulnerability()
