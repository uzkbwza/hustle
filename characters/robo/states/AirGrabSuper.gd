extends RobotState

func _enter_shared():
	host.kill_process_super_level = host.supers_available
	if host.kill_process_super_level == 9:
		if host.combo_count <= 0:
			host.kill_process_super_level = 200
		else:
			host.kill_process_super_level = 11
	._enter_shared()
	for i in range(host.supers_available):
		host.use_super_bar()


func _frame_0():
	host.flying_dir = null
	host.fly_ticks_left = 0

func _frame_1():
	host.start_invulnerability()
	host.start_projectile_invulnerability()

func _frame_9():
	host.end_invulnerability()
