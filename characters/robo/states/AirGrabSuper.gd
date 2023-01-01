extends RobotState

func _enter_shared():
	host.kill_process_super_level = host.supers_available
	if host.kill_process_super_level == 9:
		host.kill_process_super_level = 10
	._enter_shared()
	for i in range(host.supers_available):
		host.use_super_bar()


func _frame_0():
	host.start_invulnerability()
	host.flying_dir = null
	host.fly_ticks_left = 0

func _frame_7():
	host.end_invulnerability()
