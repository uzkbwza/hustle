extends RobotState

func _tick():
	if current_tick == 3 and host.turn_frames < 10:
		current_tick = 2 
