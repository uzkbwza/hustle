extends WizardState

const MAX_DIST = "512"
const PARTICLE = preload("res://characters/wizard/GeyserParticleEffect.tscn")
const PROJECTILE = preload("res://characters/wizard/projectiles/GeyserProjectile.tscn")

var center_x = 0
var center_y = 0

var particle

func _tick():
	if started_in_air and (current_tick > 10 or current_tick < 6) and host.is_grounded():
		return "Landing"

func _exit():
	if particle:
		particle.queue_free()
		particle = null

func _frame_7():
	var dir = xy_to_dir(data["x"], data["y"])
	particle = spawn_particle_relative(PARTICLE, particle_position, Vector2(float(dir.x), float(dir.y)))
	var pos = host.get_pos()
	center_x = pos.x
	center_y = pos.y

func _frame_9():
	var dir = xy_to_dir(data["x"], data["y"])
#	particle = spawn_particle_relative(PARTICLE, particle_position, Vector2(float(dir.x), float(dir.y)))
	var opp_pos = host.obj_local_center(host.opponent)
	var dist = fixed.vec_len(str(opp_pos.x), str(opp_pos.y))
	if fixed.gt(dist, MAX_DIST):
		dist = MAX_DIST
	var pos = host.get_pos()
	var diff_x = pos.x - center_x
	var diff_y = pos.y - center_y
	var particle_pos = fixed.normalized_vec_times(dir.x, dir.y, dist)
	var obj_pos = {
		"x": fixed.round(particle_pos.x) - diff_x,
		"y": fixed.round(particle_pos.y) - diff_y - 16,
	}
	if obj_pos.y <= 0:
		var obj = host.spawn_object(PROJECTILE, obj_pos.x * host.get_facing_int(), obj_pos.y)
