extends DefaultFireball

const ACTIVATE_DISTANCE = "24"
const MIN_LIFETIME = 20
const Y_FRIC = "0.05"
const MOVE_SPEED = "1.0"

func _tick():
	if current_tick > MIN_LIFETIME:
		var pos = host.get_pos()
		var obj = host.creator.opponent
		var center = obj.get_hurtbox_center()
		if fixed.lt(fixed.vec_dist(str(pos.x), str(pos.y), str(center.x), str(center.y)), ACTIVATE_DISTANCE):
			return "Explode"
	var dir = host.obj_local_center(host.creator.opponent)
	var move_dir = fixed.normalized_vec_times(str(dir.x), str(dir.y), MOVE_SPEED)
	host.move_directly(move_dir.x, move_dir.y)
#	if current_tick >= lifetime:
#		return "Explode"
	host.apply_y_fric(Y_FRIC)
	if current_tick == 60:
		host.reset_momentum()
