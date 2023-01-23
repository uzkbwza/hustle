extends RobotState

const SPEED = "2.0"

export var dir = 1

func _tick():
	if dir != 0:
		host.apply_force_relative(fixed.mul(SPEED, str(dir)), "0")
		if current_tick % 12 == 0:
			host.play_sound("DriveMove")
	else:
		if current_tick % 12 == 0:
			host.play_sound("DriveIdle")
	host.apply_forces_no_limit()
