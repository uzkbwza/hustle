extends RobotState

export var throw_invuln_length = 9

func _frame_0():
	host.start_throw_invulnerability()

func _tick():
	if current_tick == throw_invuln_length:
		host.end_throw_invulnerability()
