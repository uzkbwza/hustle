extends RobotState

var reversing_command_grab = false

func _enter():
	reversing_command_grab = data

#func _frame_0():
#	host.start_projectile_invulnerability()

func _frame_1():
	host.move_directly_relative(5, 0)
#
#func _frame_3():
#	host.end_projectile_invulnerability()
