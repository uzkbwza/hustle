extends CharacterState

func _frame_1():
	throw_techable = true

func _frame_9():
	throw_techable = false

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	if started_in_air and air_type == AirType.Aerial:
		if host.is_grounded():
			queue_state_change("Landing", 6)
