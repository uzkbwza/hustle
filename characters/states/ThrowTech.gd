extends CharacterState

func _frame_0():
	host.reverse_state = false
	host.start_invulnerability()
#	host.update_facing()
	host.set_facing(host.get_opponent_dir())

func _frame_1():
#	host.update_facing()

	host.update_data()
	host.move_directly_relative(-10, 0)
	host.apply_force_relative("-8", "0")

func _tick():
	host.apply_grav()
	host.apply_fric()
	host.apply_forces()
