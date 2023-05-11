extends ObjectState

export var disable_when_this_far_from_terrain = 4
export var speed = "16.0"
export var launch = true
export var bounces = 0
export var bounce_multiplier = "-0.9"

func _enter():
	host.launched = true
	if launch:
		var force = fixed.vec_mul(data.x, data.y, speed)
		host.apply_force(force.x, force.y)
		host.movable = false
	else:
		host.stop_particles()
	if host.creator:
		if host.creator.boulder_projectile == host.obj_name:
			host.creator.boulder_projectile = null

func _tick():
	var pos = host.get_pos()
	var vel = host.get_vel()
	if current_tick > 3:
		if pos.y > -disable_when_this_far_from_terrain:
			if bounces > 0:
				bounces -= 1
				host.play_sound("Bounce")
				host.set_vel(vel.x, fixed.mul(vel.y, bounce_multiplier))
				host.set_pos(pos.x, -disable_when_this_far_from_terrain)
			else:
				host.disable()
		elif host.stage_width - Utils.int_abs(pos.x) < disable_when_this_far_from_terrain:
			if bounces > 0:
				bounces -= 1
				host.play_sound("Bounce")
				host.set_vel(fixed.mul(vel.x, bounce_multiplier), vel.y)
			else:
				host.disable()
		elif host.has_ceiling and Utils.int_abs(-host.ceiling_height - pos.y) < disable_when_this_far_from_terrain:
			host.disable()
	if launch:
		host.apply_forces_no_limit()
		host.limit_speed(speed)

func _on_hit_something(obj, hitbox):
	if obj.is_in_group("Fighter"):
		host.hit_action(obj)
		host.disable()
	._on_hit_something(obj, hitbox)
