extends ThrowState

func _frame_0():
	if !host.is_grounded():
		host.reset_momentum()
		host.start_invulnerability()

func _tick():
	if current_tick > 18:
		host.apply_grav()
