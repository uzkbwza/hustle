tool 

extends Hitbox

class_name SweptHitbox

const IS_SWEPT = true

export  var _c_Raycast = 0
export  var to_x = 0
export  var to_y = 0

func _fixed_clamp(
	n: String,
	start: String, end: String
):
	if host.fixed.lt(n, start):
		return start
	elif host.fixed.gt(n, end):
		return end
	else:
		return n

func _fixed_max(
	a: String,
	b: String
):
	return a if host.fixed.gt(a, b) else b

func _fixed_min(
	a: String,
	b: String
):
	return a if host.fixed.lt(a, b) else b
	
func _aabb_intersect(aabb: Dictionary):
	var fixed: FixedMath = host.fixed
	var x1 = x_facing() + pos_x - width
	var x2 = x_facing() + pos_x + width
	var y1 = y + pos_y - height
	var y2 = y + pos_y + height
	if x1 > aabb.x2 or x2 < aabb.x1 or y1 > aabb.y2 or y2 < aabb.y1:
		return null
	else:
		return "0"

func _seg_seg_intersect(start: int, delta: int, padding: int, n1: int, n2: int):
	var fixed: FixedMath = host.fixed

	var near: int
	var far: int
	if delta > 0:
		near = n1 - padding
		far = n2 + padding
	else:
		near = n2 + padding
		far = n1 - padding

	var recip: String = fixed.div("1.0", str(delta))

	var near_time: String = fixed.mul(str(near - start), recip)
	if fixed.ge(near_time, "1"):
		return null
	
	var far_time: String = fixed.mul(str(far - start), recip)
	if fixed.le(far_time, "0"):
		return null
		
	return near_time

func _seg_rect_intersect(box: CollisionBox):
	var fixed: FixedMath = host.fixed

	var start_x: int = x_facing() + pos_x
	var start_y: int = y + pos_y

	var aabb = box.get_aabb()

	# segment starts inside rect
	if start_x > aabb.x1 and start_x < aabb.x2 and start_y > aabb.y1 and start_y < aabb.y2:
		return "0"

	var delta_x: int = to_x_facing()
	var delta_y: int = to_y
	
	var zero_y = delta_y == 0
	var zero_x = delta_x == 0
	# less strenuous tests if segment is straight
	if zero_x != zero_y:
		if zero_y:
			if start_y > aabb.y1 - height and start_y < aabb.y2 + height:
				return _seg_seg_intersect(start_x, delta_x, width, aabb.x1, aabb.x2)
			else:
				return null
		if zero_x:
			if start_x > aabb.x1 - width and start_x < aabb.x2 + width:
				return _seg_seg_intersect(start_y, delta_y, height, aabb.y1, aabb.y2)
			else:
				return null
	# aabb intersection if segment is (0, 0)
	elif zero_x and zero_y:
		return _aabb_intersect(aabb)

	var near_x: int
	var far_x: int
	if delta_x > 0:
		near_x = aabb.x1 - width
		far_x = aabb.x2 + width
	else:
		near_x = aabb.x2 + width
		far_x = aabb.x1 - width

	var near_y: int
	var far_y: int
	if delta_y > 0:
		near_y = aabb.y1 - height
		far_y = aabb.y2 + height
	else:
		near_y = aabb.y2 + height
		far_y = aabb.y1 - height

	var recip_x: String = fixed.div("1.0", str(delta_x))
	var recip_y: String = fixed.div("1.0", str(delta_y))

	var near_time_x: String = fixed.mul(str(near_x - start_x), recip_x)
	var far_time_y:  String = fixed.mul(str(far_y - start_y),  recip_y)
	
	if fixed.gt(near_time_x, far_time_y):
		return null
	
	var near_time_y: String = fixed.mul(str(near_y - start_y), recip_y)
	var far_time_x:  String = fixed.mul(str(far_x - start_x),  recip_x)
	
	if fixed.gt(near_time_y, far_time_x):
		return null
	
	var near_time: String = _fixed_max(near_time_x, near_time_y)
	var far_time:  String = _fixed_min(far_time_x, far_time_y)
	
	if fixed.ge(near_time, "1") or fixed.le(far_time, "0"):
		return null
		
	return near_time
	
func _seg_rect_test(box: CollisionBox):
	return _seg_rect_intersect(box) != null

func _seg_rect_delta(box: CollisionBox):
	var near_time = _seg_rect_intersect(box)
	if near_time == null:
		return null

	var fixed: FixedMath = host.fixed

	var hit_time = _fixed_clamp(near_time, "0", "1")

	var delta_x = str(to_x_facing())
	var delta_y = str(to_y)
	
	return {
		"x": fixed.mul(delta_x, hit_time),
		"y": fixed.mul(delta_y, hit_time)
	}


func get_sweep_center():
	var fixed: FixedMath = host.fixed

	var start = get_center()	
	
	var delta_x = to_x_facing()
	var delta_y = to_y
	
	var delta_half = fixed.vec_mul(str(delta_x), str(delta_y), "0.5")
	
	return {
		"x": start.x + fixed.round(delta_half.x),
		"y": start.y + fixed.round(delta_half.y)
	}

func get_sweep_center_float():
	var delta = Vector2(to_x_facing(), to_y)
	
	return get_center_float() + (delta / 2.0)

func to_x_facing():
	return to_x if facing == "Right" else - to_x

func get_aabb():
	# given how everything is implemented, this will only happen when trying to
	#  test for CollisionBox.overlaps(SweptHitbox), which only occurs when
	#  a SweptHitbox is used as a hurtbox
#	assert(false, "calling get_aabb() on a SweptHitbox")
	
	pass

func overlaps(box: CollisionBox):
	if box.width == 0 and box.height == 0:
		return false
	return _seg_rect_test(box)

func box_draw():
	var parent = get_parent()
	if parent.is_in_group("BaseObj"):
		if parent.disabled:
			return 
	var color = Color.red
	if throw:
		color = Color.purple
		
	var to_x_facing = to_x_facing()
	
	var top_origin_is_flat = (to_y >= 0)
	var right_origin_is_flat = (to_x_facing < 0)

	var size = Vector2(width, height)
	var size_neg = Vector2(-width, height)

	var offset = Vector2(x_facing(), y)
	var to_offset = offset + Vector2(to_x_facing, to_y)

	var offset1
	var offset2

	if right_origin_is_flat:
		offset1 = to_offset
		offset2 = offset
	else:
		offset1 = offset
		offset2 = to_offset

	var p1
	var p2

	if top_origin_is_flat == right_origin_is_flat:
		p1 = size
		p2 = size_neg
	else:
		p1 = size_neg
		p2 = -size
	
	var points = [
		offset1 + p1,
		offset1 + p2,
		offset1 - p1,

		offset2 - p1,
		offset2 - p2,
		offset2 + p1
	]

	var fill = color
	var stroke = color
	fill.a = 0.25
	stroke.a = 0.5
	draw_colored_polygon(points, fill)

	# draw_polyline needs a closing point
	points.push_back(points[0])
	draw_polyline(points, stroke)

func spawn_whiff_particle():
	if whiff_particle:
		host.spawn_particle_effect(whiff_particle, Vector2(x + pos_x, y + pos_y), Vector2(x_facing(), 0))
	
func get_center():
	return {
		"x": x_facing() + pos_x,
		"y": y + pos_y
	}
	
func get_center_float():
	return Vector2(x_facing() + pos_x, y + pos_y)

func get_overlap_center_float(box: CollisionBox):
	var start = Vector2(x_facing() + pos_x, y + pos_y)
	
	var delta = Vector2(to_x_facing(), to_y)

	var box_center = box.get_center_float()
	
	var box_center_delta = box_center - start
	
	var approx_center_delta = box_center_delta.project(delta)
	
	var l = approx_center_delta.distance_to(box_center_delta)
	
	var avg_size = float(width + height) / 2.0
	var avg_size_vec = Vector2(avg_size, avg_size)
	var box_avg_size = float(box.width + box.height) / 2.0
	var box_avg_size_vec = Vector2(box_avg_size, box_avg_size)

	var approx_center_dist = max(avg_size - ((avg_size - (l - box_avg_size)) / 2.0), 0)
	
	approx_center_delta = approx_center_delta.move_toward(box_center_delta, approx_center_dist)
	
	return start + approx_center_delta
