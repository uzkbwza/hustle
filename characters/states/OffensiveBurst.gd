extends CharacterState

var started_falling = false

func _frame_0():
	host.use_burst()
	host.start_projectile_invulnerability()
	host.update_grounded()
	started_falling = false
	host.start_invulnerability()

func _frame_15():
	host.end_invulnerability()
	started_falling = true

func _tick():
	if started_falling:
		host.apply_grav()
	host.apply_forces()
	if current_tick > 15:
		host.end_invulnerability()

func is_usable():
	return host.burst_enabled and .is_usable() and (host.bursts_available > 0)
