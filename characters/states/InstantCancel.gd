extends SuperMove

func _enter():
	spawn_particle_relative(preload("res://fx/InstantCancelEffect.tscn"), Vector2(0, -16))
	pass

func _tick():
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
