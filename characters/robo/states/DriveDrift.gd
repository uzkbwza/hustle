extends CharacterState

const X_FRIC = "0.12"

func _tick():
	host.apply_forces_no_limit()
	if current_tick < 8:
		host.apply_x_fric(X_FRIC)
	else:
		host.apply_x_fric("0.07")

func _frame_0():
	host.start_projectile_invulnerability()

func _frame_10():
	host.end_projectile_invulnerability()
