extends WizardState

func is_usable():
	return .is_usable() and host.orb_projectile and (host.is_grounded() or host.air_movements_left > 0)

func _frame_0():
	if !host.is_grounded() and !host.infinite_resources:
		host.air_movements_left -= 1
#	interruptible_on_opponent_turn = false
	host.move_directly(0, -1)
	host.set_grounded(false)
	host.tether_ticks = host.TETHER_TICKS

func _tick():
	if current_tick > 8:
		if host.is_grounded():
			return "Landing"
	else:
		host.set_grounded(false)
