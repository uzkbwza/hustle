extends CharacterState

export var down = false

const TRACKING_SPEED = "2.0"
const TRACKING_MIN_DIST = "32"

var hit_opponent = false

func _frame_0():
	hit_opponent = false

func _frame_1():
	if !down:
		host.reset_momentum()
		var force = fixed.normalized_vec_times("0.5" if !down else "0.85", "-1.0" if !down else "1.0", "4.0")
		host.apply_force_relative(force.x, force.y)

func _frame_6():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5" if !down else "0.85", "-1.0" if !down else "1.0", "8.0")
	host.apply_force_relative(force.x, force.y)
	if down:
		spawn_particle_relative(particle_scene, Vector2(), Vector2(float(force.x) * host.get_facing_int(), float(force.y)))

func _frame_10():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5" if !down else "0.85", "-1.0" if !down else "1.0", "10.0")
	host.apply_force_relative(force.x, force.y)

func _frame_19():
	host.reset_momentum()
	var force = fixed.normalized_vec_times("0.5" if !down else "0.85", "-1.0" if !down else "1.0", "12.0")
	host.apply_force_relative(force.x, force.y)

func _tick():
	if hit_opponent:
		var pos = host.obj_local_center(host.opponent)
		if fixed.gt(fixed.vec_len(str(pos.x), str(pos.y)), TRACKING_MIN_DIST):
			var dir = fixed.normalized_vec_times(str(pos.x), str(pos.y), TRACKING_SPEED)
			host.move_directly(dir.x, dir.y)

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj == host.opponent:
		hit_opponent = true
