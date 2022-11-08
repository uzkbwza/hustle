extends ObjectState


func create_particle():
	spawn_particle_relative(preload("res://characters/stickman/projectiles/SummonParticle.tscn"))

func _frame_1():
	create_particle()

func _tick():
	host.apply_grav()
	host.apply_fric()
	host.apply_forces()
	if host.is_grounded():
		return "Slide"
	host.set_facing(host.get_facing_int()) # without this the ghost is flipped for some reason

#func _frame_23():
#	stopped = false
#	var kickback = fixed.normalized_vec_times(str(data.x), str(data.y), KICKBACK)
#	host.apply_force_relative(kickback.x, kickback.y)
#	for i in range(-2, 1):
#		var dir = fixed.rotate_vec(str(data.x), str(data.y), fixed.deg2rad(str((i * host.get_facing_int()) * SPREAD_DEGREES)))
#		var kunai_data = { "dir": dir }
#		host.spawn_object(preload("res://characters/stickman/projectiles/Kunai.tscn"), 0, 0, true, kunai_data)
#	pass
