extends CharacterState

func _frame_1():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5", "-1.0", "3.0")
	spawn_particle_relative(particle_scene, Vector2(), Vector2(float(force.x), float(force.y)))
	host.apply_force_relative(force.x, force.y)

func _frame_7():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5", "-1.0", "8.0")
	host.apply_force_relative(force.x, force.y)

func _frame_13():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5", "-1.0", "8.0")
	host.apply_force_relative(force.x, force.y)

func _frame_21():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5", "-1.0", "10.0")
	host.apply_force_relative(force.x, force.y)

func _tick():
	
	pass
