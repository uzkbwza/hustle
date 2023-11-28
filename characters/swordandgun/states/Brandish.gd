extends SuperMove

const IS_GUN_PULL = true

export var quicker = false

func _frame_0():
	if !quicker and (host.bullets_left <= 0 or !host.is_ghost):
		fallback_state = "SlowHolster"
	else:
		fallback_state = "Shoot2"
#
#func _frame_7():
#	interruptible_on_opponent_turn = true

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()

func is_usable():
	return .is_usable() and (host.bullets_left > 0 or host.supers_available > 0) and host.has_gun
