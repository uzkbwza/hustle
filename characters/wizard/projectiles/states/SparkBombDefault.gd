extends DefaultFireball

const ACTIVATE_DISTANCE = "24"
const MIN_LIFETIME = 16
const Y_FRIC = "0.05"
const MOVE_SPEED = "1.5"
const AVOID_SPEED = "0.50"
const AVOID_DISTANCE = "24.0"

export var armed = false
export var arming_time = 15

func _enter():
	host.armed = armed

func _tick():
	if current_tick > arming_time and !armed:
		return "Armed"
	if armed:
		var pos = host.get_pos()
		var obj = host.creator.opponent
		var center = obj.get_hurtbox_center()
		if fixed.lt(fixed.vec_dist(str(pos.x), str(pos.y), str(center.x), str(center.y)), ACTIVATE_DISTANCE):
#			if host.get_opponent().combo_count <= 0:
			if host.delay_ticks <= 0:
				host.explode()
			return
		if host.delay_ticks > 0:
			host.delay_ticks -= 1
			if host.delay_ticks == 0:
				if host.exploded:
					host.explode()

	for obj_name in host.objs_map:
		var obj = host.objs_map[obj_name]
		if obj == null or (obj is BaseObj and obj.disabled) or obj == host:
			continue
		if obj.is_in_group("SparkBomb"):
			var obj_pos = host.obj_local_center(obj)
			if fixed.lt(fixed.vec_len(str(obj_pos.x), str(obj_pos.y)), AVOID_DISTANCE):
				var move_dir = fixed.normalized_vec_times(str(obj_pos.x), str(obj_pos.y), "-" + AVOID_SPEED)
				host.move_directly(move_dir.x, move_dir.y)
			pass
	
	var dir = host.obj_local_center(host.creator.opponent)
	var move_dir = fixed.normalized_vec_times(str(dir.x), str(dir.y), MOVE_SPEED)
	host.move_directly(move_dir.x, move_dir.y)
	host.apply_x_fric(Y_FRIC)
	host.apply_y_fric(Y_FRIC)
	host.apply_forces_no_limit()
	if current_tick >= lifetime:
		if host.delay_ticks <= 0:
			host.explode()
		return
