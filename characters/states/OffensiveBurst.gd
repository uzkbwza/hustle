extends CharacterState

var started_falling = false

func _frame_1():
	host.update_grounded()
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

func is_usable():
	return .is_usable() and (host.bursts_available > 0)
