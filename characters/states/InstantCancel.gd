extends SuperMove

func _enter():
	spawn_particle_relative(preload("res://fx/InstantCancelEffect.tscn"), host.hurtbox_pos_relative_float())
	pass

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()

func is_usable():
	return .is_usable() and host.current_state().state_name != "Burst" and not "InstantCancel" in host.current_state().state_name
