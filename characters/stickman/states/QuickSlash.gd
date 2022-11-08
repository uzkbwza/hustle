extends SuperMove

const MOVE_DISTANCE = 120

var hitboxes = []
var move_dir

var dist = MOVE_DISTANCE
var start_pos_x
var start_pos_y

func _enter():
	dist = MOVE_DISTANCE
	hitboxes = []
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			child.x = 0
			child.y = 0
	if data:
		move_dir = xy_to_dir(data.x, data.y)
#		move_dir = fixed.normalized_vec_times(move_dir.x, move_dir.y, "1.0")
	else:
		move_dir = { "x": str(host.get_facing_int()), "y": "0" }
		
	var move_vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, "20")

	host.apply_force(move_vec.x,  fixed.div(move_vec.y, "2"))

#	move_vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, str(MOVE_DISTANCE))
#	var pos = host.get_pos()
#	var dest = {
#		"x": fixed.add(str(pos.x), move_vec.x), 
#		"y": fixed.add(str(pos.y), move_vec.y),
#	}
#
#	if !fixed.eq(dest.y, str(pos.y)):
#		var x_intercept = fixed.get_x_intercept(str(pos.x), str(pos.y), dest.x, dest.y)
#		var len_ = fixed.vec_len(move_vec.x, move_vec.y)
#		var sub = fixed.vec_sub(x_intercept, "0", str(pos.x), str(pos.y))
#		var dest_len = fixed.vec_len(sub.x, sub.y)
#		if fixed.lt(dest_len, len_):
#			dist = dest_len
#		else:
#			dist = str(MOVE_DISTANCE)
#	else:
#		dist = str(MOVE_DISTANCE)
#	for i in range(hitboxes.size()):
#		var vec
#		if i > 0:
#			var ratio = fixed.div(str(i), str(hitboxes.size()))
#			var length = fixed.mul(fixed.mul(dist, "-2"), ratio)
#			vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, length)
#		else:
#			vec = {"x": "0", "y": "0"}
##		vec = fixed.vec_mul(vec.x, vec.y, str(-MOVE_DISTANCE))
#		hitboxes[i].x = fixed.round(fixed.mul(vec.x, str(host.get_facing_int())))
#		hitboxes[i].y = fixed.round(fixed.sub(vec.y, "16"))
#
func _frame_1():
	var start_pos = host.get_pos().duplicate()
	start_pos_x = start_pos.x
	start_pos_y = start_pos.y

func _frame_4():
	pass
#	host.move_directly(MOVE_DISTANCE / 4, 0)

func _frame_5():
	host.start_invulnerability()
	host.move_directly(0, -2)


	var move_vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, str(MOVE_DISTANCE))


	host.move_directly(move_vec.x, move_vec.y)
	host.update_data()
	
	var end_pos = host.get_pos().duplicate()
	
	for i in range(hitboxes.size()):
		var ratio = fixed.div(str(i), str(hitboxes.size()))
		hitboxes[i].x = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_x), str(end_pos.x), ratio), str(host.get_pos().x))) * host.get_facing_int()
		hitboxes[i].y = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_y), str(end_pos.y), ratio), str(host.get_pos().y))) - 16
	
	move_vec.x = end_pos.x - start_pos_x
	move_vec.y = end_pos.y - start_pos_y
	var pos = host.get_pos_visual()
	var particle_dir = Vector2(float(move_vec.x), float(move_vec.y)).normalized()
	host.spawn_particle_effect(preload("res://characters/stickman/QuickSlashEffect.tscn"), Vector2(start_pos_x, start_pos_y - 13), particle_dir)
	host.update_data()

func _frame_6():
	host.reset_momentum()
	var move_vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, "10")
	host.apply_force(move_vec.x,  fixed.mul(move_dir.y, "1.0"))
	host.apply_force("0",  "-1")
#	host.apply_force("20", "-1")
	host.end_invulnerability()

func _tick():
	if current_tick > 6:
		if host.is_grounded():
			queue_state_change("Landing", 2)
	host.apply_grav()
	host.apply_fric()
	host.apply_forces_no_limit()
