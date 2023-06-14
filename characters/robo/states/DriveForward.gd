extends RobotState

const SPEED_LIMIT = "20"

export var SPEED = "3.0"

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
	host.limit_speed(SPEED_LIMIT)

#func _frame_1():
#	if dir == 1:
#		host.start_projectile_invulnerability()
