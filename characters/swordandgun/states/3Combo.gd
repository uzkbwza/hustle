extends CharacterState

export var down = false

func _frame_1():
	host.reset_momentum()
	if !down:
		var force = fixed.normalized_vec_times("0.5" if !down else "0.75", "-1.0" if !down else "1.0", "3.0")
		host.apply_force_relative(force.x, force.y)

func _frame_7():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5" if !down else "0.75", "-1.0" if !down else "1.0", "8.0")
	host.apply_force_relative(force.x, force.y)
	if down:
		spawn_particle_relative(particle_scene, Vector2(), Vector2(float(force.x) * host.get_facing_int(), float(force.y)))

func _frame_13():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5" if !down else "0.75", "-1.0" if !down else "1.0", "8.0")
	host.apply_force_relative(force.x, force.y)

func _frame_21():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5" if !down else "0.75", "-1.0" if !down else "1.0", "10.0")
	host.apply_force_relative(force.x, force.y)

func _tick():
	pass
