extends RobotState

func _tick():
	host.apply_forces()

func _frame_3():
	host.move_directly_relative(-12, 0)
