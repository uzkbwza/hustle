extends SuperMove

func _enter():
	spawn_particle_relative(preload("res://fx/InstantCancelEffect.tscn"), host.hurtbox_pos_relative_float())
	pass

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
