extends CharacterState

var left_ground = false

func _enter():
	left_ground = false

func _frame_6():
	left_ground = true

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	if left_ground and host.is_grounded():
		queue_state_change("Landing", 15)
