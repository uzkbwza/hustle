extends SuperMove

func _frame_6():
	host.spawn_orb()

func is_usable():
	return .is_usable() and host.orb_projectile == null
