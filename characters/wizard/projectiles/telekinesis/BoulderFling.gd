extends ObjectState

export var disable_when_this_far_from_terrain = 4
export var speed = "16.0"
export var launch = true

func _enter():
	host.launched = true
	if launch:
		var force = fixed.normalized_vec_times(data.x, data.y, speed)
		host.apply_force(force.x, force.y)
		host.movable = false
	if host.creator:
		if host.creator.boulder_projectile == host.obj_name:
			host.creator.boulder_projectile = null

func _tick():
	var pos = host.get_pos()
	if current_tick > 3:
		if pos.y > -disable_when_this_far_from_terrain:
			host.disable()
		elif host.stage_width - Utils.int_abs(pos.x) < disable_when_this_far_from_terrain:
			host.disable()
		elif host.has_ceiling and Utils.int_abs(-host.ceiling_height - pos.y) < disable_when_this_far_from_terrain:
			host.disable()
	if launch:
		host.apply_forces_no_limit()
		host.limit_speed(speed)


func _on_hit_something(obj, hitbox):
	if obj.is_in_group("Fighter"):
		host.disable()

	._on_hit_something(obj, hitbox)

