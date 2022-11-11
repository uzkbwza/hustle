extends CharacterState

var left_ground = false

func _enter():
	left_ground = false

#func _frame_1():
#	left_ground = false

func _frame_7():
	left_ground = true

func _tick():
	if current_tick <= 6:
		left_ground = false
	if current_tick < 24:
		host.start_projectile_invulnerability()
	else:
		host.end_projectile_invulnerability()
		
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	if left_ground and host.is_grounded():
		queue_state_change("Landing", 15)
