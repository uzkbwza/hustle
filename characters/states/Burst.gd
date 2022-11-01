extends CharacterState

var started_falling = false

func _enter():
	host.start_projectile_invulnerability()
	host.opponent.reset_combo()
	started_falling = false
	host.use_burst()
	host.start_invulnerability()

func _frame_15():
	host.end_invulnerability()
	started_falling = true

func _tick():
	if started_falling:
		host.apply_grav()
	host.apply_forces()

func _exit():
	host.end_projectile_invulnerability()

func is_usable():
	return host.burst_enabled and .is_usable() and (host.bursts_available > 0)
