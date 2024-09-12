extends Node

class_name Utils

const cardinal_dirs = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
const diagonal_dirs = [Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1)]
const dirs = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1)]
const INVALID_FILE_CHARS = "<>:/\\|?*"

#func _input(event):
#	if event is InputEventKey:
#		if event.is_action_pressed("debug_reload"):
#			Global.reload()
#
#func play_fx_in_level(scene: PackedScene, position: Vector2, rotation=0, flipped=false):
#	var fx = scene.instantiate()
#	current_level.add_child.call_deferred(fx)
#	fx.set_deferred("global_position", position)
#	if flipped:
#		fx.scale.x = -1
#	fx.rotation = rotation
#	return fx
##	await get_tree().physics_frame
static func filter_filename(text):
	var filtered_file_name = ""
	for char_ in text:
		if not char_ in INVALID_FILE_CHARS:
			filtered_file_name += char_
		else:
			filtered_file_name += "_"
	return filtered_file_name

static func int_abs(n: int):
	if n < 0:
		n *= -1
	return n

static func get_copiable_properties(node: Node):
	var list = PoolStringArray()
	for property in node.get_script().get_script_property_list():
		var name = property.name
		var value = node.get(name)
		var type: = typeof(value)
		var valid = true
		match type:
			TYPE_OBJECT: valid = false
			TYPE_ARRAY: valid = false
			TYPE_DICTIONARY: valid = false
			TYPE_NIL: valid = false
			TYPE_STRING_ARRAY: valid = false

		if !valid:
			continue
		list.append(name)
	return list

static func int_sign(n: int):
	if n == 0:
		return 0
	if n < 0:
		return -1
	return 1

static func int_sign2(n: int):
	if n < 0:
		return -1
	return 1

static func frames(n, fps=60):
	return (n / float(fps))

static func split_lines(string):
	if !string:
		return []
	var lines = []
	for s in string.split("\n"):
		var line = s.strip_edges()
		if line:
			lines.append(line)
	return lines

static func int_clamp(n: int, min_: int, max_: int):
	if n > min_ and n < max_:
		return n
	if n <= min_:
		return min_
	if n >= max_:
		return max_

static func int_min(n1: int, n2: int):
	if n1 < n2:
		return n1
	return n2

static func int_max(n1: int, n2: int):
	if n1 > n2:
		return n1
	return n2

static func starts_with(string: String, pattern: String):
	return string.trim_prefix(pattern) != string

static func map(value, istart, istop, ostart, ostop):
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
	
static func map_int(value:int, istart:int, istop:int, ostart:int, ostop:int):
	return ostart + (ostop - ostart) * ((value - istart) / (istop - istart))

static func map_pow(value, istart, istop, ostart, ostop, power):
	return ostart + (ostop - ostart) * (pow((value - istart) / (istop - istart), power))

static func tree_set_all_process(p_node: Node, p_active: bool, p_self_too: bool = false) -> void:
	if not p_node:
		push_error("p_node is empty")
		return
	var p = p_node.is_processing()
	var pp = p_node.is_physics_processing()
	p_node.propagate_call("set_process", [p_active])
	p_node.propagate_call("set_physics_process", [p_active])
	if not p_self_too:
		p_node.set_process(p)
		p_node.set_physics_process(pp)

static func snap(value, step):
	return round(value / step) * step

static func approach(a, b, amount):
	if a < b:
		a += amount
		if a > b:
			return b
	else:
		a -= amount
		if a < b:
			return b
	return a

static func int_lerp(a: int, b: int, f: int):
	return (a*(1024-f) + b * f) >> 10


static func get_closest_node(node: Node2D, node_list: Array) -> Node2D:
	var closest = null
	var closest_dist = INF
	for n in node_list:
		var dist = node.global_position.distance_squared_to(n.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = n
	return closest

static func get_first_player(node):
	return node.get_tree().get_nodes_in_group("player")[0]

static func ang2vec(angle):
	return Vector2(cos(angle), sin(angle))

static func get_angle_from_to(node, position):
	var target = node.get_angle_to(position)
	target = target if abs(target) < PI else target + TAU * -sign(target)
	return target
	
static func angle_diff(from, to):
	return fposmod(to-from + PI, PI*2) - PI
	
static func comma_sep(number):
	var string = str(int(number))
	var mod = string.length() % 3
	var res = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]
	return res

static func float_time():
	return Time.get_ticks_msec() / 1000.0

static func wave(from, to, duration, offset=0):
	var t = Time.get_ticks_msec() / 1000.0
	var a = (to - from) * 0.5
	return from + a + sin((((t) + duration * offset) / duration) * TAU) * a

static func pulse(duration:float=1.0, width:float=0.5) -> bool:
	return wave(0.0, 1.0, duration) < width

static func remove_duplicates(array: Array):
	var seen = []
	var new = []
	for i in array.size():
		var value = array[i]
		if value in seen:
			continue
		seen.append(value)
		new.append(value)
	return new

static func is_in_circle(point: Vector2, circle_center: Vector2, circle_radius: float):
	return veci_distance_to(point, circle_center) < circle_radius

static func veci_distance_to(start: Vector2, end: Vector2):
	return veci_to_vec(start).distance_to(veci_to_vec(end))

static func veci_to_vec(veci: Vector2) -> Vector2:
	return Vector2(veci.x, veci.y)

static func sin_0_1(value):
	return (sin(value) / 2.0) + 0.5

static func veci_length(v: Vector2):
	return Vector2(v.x, v.y).length()

static func clamp_cell(cell: Vector2, map: Array2D) -> Vector2:
	return Vector2(clamp(cell.x, 0, map.width - 1), clamp(cell.y, 0, map.height - 1))

static func stepify(s, step):
	return round(s / step) * step

static func line(start: Vector2, end: Vector2):
	# Bresenham's algorithm
	var temp
	var x1 = int(start.x)
	var y1 = int(start.y)
	var x2 = int(end.x)
	var y2 = int(end.y)
	var dx = x2 - x1
	var dy = y2 - y1
	
	var steep = abs(dy) > abs(dx)
	if steep:
		temp = x1
		x1 = y1
		y1 = temp
		temp = x2
		x2 = y2
		y2 = temp

	var swapped = false
	if x1 > x2:
		temp = x1
		x1 = x2
		x2 = temp
		temp = y1
		y1 = y2
		y2 = temp
		swapped = true
		
	dx = x2 - x1
	dy = y2 - y1
	var error: int = int(dx / 2.0)
	var ystep = 1 if y1 < y2 else -1
	var y = y1
	var points = []
	for x in range(x1, x2 + 1):
		points.append(Vector2(y, x) if steep else Vector2(x, y))
		error = error - abs(dy)
		if error < 0:
			y += ystep
			error += dx
	if swapped:
		points.reverse()
	return points

static func random_triangle_point(a, b, c):
	return a + sqrt(randf()) * (-a + b + randf() * (c - b))

static func triangle_area(a, b, c):
	var ba = a - b
	var bc = c - b
	return abs(ba.cross(bc)/2)

static func get_polygon_bounding_box(polygon: PoolVector2Array) -> Rect2:
	var top_left = Vector2(INF, INF)
	var bottom_right = Vector2(-INF, -INF)
	for point in polygon:
		if point.x < top_left.x:
			top_left.x = point.x
		if point.y < top_left.y:
			top_left.y = point.y
		if point.x > bottom_right.x:
			bottom_right.x = point.x
		if point.y > bottom_right.y:
			bottom_right.y = point.y
	return Rect2(top_left, bottom_right - top_left)

#static func get_random_point_in_polygon(polygon: PackedVector2Array, rng: BetterRng, num_points = 1, min_distance_between_points=0):
#	var points = Geometry2D.triangulate_polygon(polygon)
#	var size = polygon.size()
#	var tris = []
#	for i in range(0, points.size(), 3):
#		tris.append([polygon[points[i]], polygon[points[i + 1]], polygon[points[i + 2]]])
#	var get_point = (func():
#		var tri = rng.weighted_random_choice(tris, func(t): return triangle_area(tris[t][0], tris[t][1], tris[t][2]))
#		return random_triangle_point(tri[0], tri[1], tri[2]))
#	if num_points == 1:
#		return get_point.call()
#	else:
#		var chosen_points = []
#		if min_distance_between_points == 0:
#			for i in range(num_points):
#				chosen_points.append(get_point.call())
#		else:
#			var quad_tree = QuadTree.new(get_polygon_bounding_box(polygon), 1)
#			var max_try_count = 0
#			for i in range(num_points):
#				var tries = 0
#				var valid_point = false
#				var point
#				var max_tries = 1000
#				while tries == 0 or !(valid_point or tries >= max_tries):
#					point = get_point.call()
#					if chosen_points.is_empty():
#						valid_point = true
#					else:
#						valid_point = true
#						for nearby_point in quad_tree.search(point, min_distance_between_points, min_distance_between_points):
#							if point.distance_to(nearby_point) < min_distance_between_points:
#								valid_point = false
#					tries += 1
#					if tries >= max_tries:
#						max_try_count += 1
##					Debug.dbg_max("tries", tries)
#				quad_tree.insert(point)
##					print("didnt insert point into tree")
##				print("acquired point %d" % i)
#				chosen_points.append(point)
##				Debug.dbg("max_try_count", max_try_count)
#		return chosen_points

static func distance_to_line_segment(xy1, xy2, xy3): # x3,y3 is the point
	var x1 = xy1.x
	var x2 = xy2.x
	var x3 = xy3.x
	var y1 = xy1.y
	var y2 = xy2.y
	var y3 = xy3.y
	
	var px = x2-x1
	var py = y2-y1

	var norm = px*px + py*py

	var u =  ((x3 - x1) * px + (y3 - y1) * py) / float(norm)

	if u > 1:
		u = 1
	elif u < 0:
		u = 0

	var x = x1 + u * px
	var y = y1 + u * py

	var dx = x - x3
	var dy = y - y3

	# Note: If the actual distance does not matter,
	# if you only want to compare what this function
	# returns to other results of this function, you
	# can just return the squared distance instead
	# (i.e. remove the sqrt) to gain a little performance

	return sqrt(dx*dx + dy*dy)


static func is_point_in_capsule(p: Vector2, xy1: Vector2, xy2: Vector2, radius: float):
	return distance_to_line_segment(xy1, xy2, p) < radius


static func spring(x:float,  v:float, xt:float, zeta:float, omega:float, h:float):
	# thanks chaoclypse
	var f = 1.0 + 2.0 * h * zeta * omega;
	var oo = omega * omega;
	var hoo = h * oo;
	var hhoo = h * hoo;
	var detInv = 1.0 / (f + hhoo);
	var detX = f * x + h * v + hhoo * xt;
	var detV = v + hoo * (xt - x);
	x = detX * detInv;
	v = detV * detInv;
	return [x,v];

# usage:
#     var temp = H.vector_spring(position,velocity,target_pos,dampening,speed,delta);
#     position = temp[0]
#     velocity = temp[1]

static func compare(val1, val2):

	if val1 == val2:
		return true
	elif typeof(val1) != typeof(val2):
		return false
	elif val1 is Dictionary and val2 is Dictionary:
		for key in val1:
			if val2.has(key):
				if !compare(val1[key], val2[key]):
					return false
			else:
				return false
		return true
	elif val1 is Array and val2 is Array:
		if val1.size() != val2.size():
			return false
		for i in range(val1.size()):
			if !compare(val1[i], val2[i]):
				return false
		return true
	elif val1 is Object and val2 is Object:
		for property in val1.get_property_list():
			var prop1 = val1.get(property.name)
			var prop2 = val2.get(property.name)
			if !compare(prop1, prop2):
				return false
		return true
	return false

static func pass_signal_along(from: Node, to: Node, signal_name, to_signal_name:String=""):
	from.connect(signal_name, to, "emit_signal", [signal_name if to_signal_name == "" else to_signal_name])

static func vector_spring(vec:Vector2, vel:Vector2, target:Vector2, zeta:float,  omega:float,  h:float):
	var x = vec.x;
	var y = vec.y;
	var t1 = spring(x, vel.x, target.x, zeta, omega, h);
	x = t1[0]
	vel.x = t1[1]
	var t2=spring(y, vel.y, target.y, zeta, omega, h);
	y = t2[0]
	vel.y = t2[1]
	vec = Vector2(x, y);
	return [vec,vel];

static func fixed_vec2_string(x: String, y: String):
	return {
		"x": x,
		"y": y,
	}

static func is_mouse_in_control(control: Control):
	var rect = control.get_global_rect()
	var mouse_position = control.get_global_mouse_position()
	return rect.has_point(mouse_position)

static func number_from_string(string):
	var chars = ""
	for char_ in string:
		if char_.is_valid_integer():
			chars += char_
	return int(chars)

static func get_files_in_folder(folder: String, extension=""):
	var dir = Directory.new()
	if !folder.ends_with("/"):
		folder += "/"
	dir.open(folder)
	dir.list_dir_begin()
	var files = []
	while true:
		var file = folder + dir.get_next()
		if file == folder:
			break
		if extension == "":
			files.append(file)
		else:
			if file.ends_with(extension):
				files.append(file)
	return files
