extends CharacterState

const X_FRIC = "0.06"
const SPEED_LIMIT = "22"

func _frame_2():
	if host.initiative:
		host.start_projectile_invulnerability()
	if host.reverse_state and host.combo_count <= 0:
		host.add_penalty(25)

func _tick():
	host.apply_forces_no_limit()
	host.apply_x_fric(X_FRIC)
	host.limit_speed(SPEED_LIMIT)

func _frame_13():
	host.end_projectile_invulnerability()
