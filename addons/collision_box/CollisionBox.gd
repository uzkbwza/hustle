tool

extends Node2D

class_name CollisionBox

export var x: int = 0
export var y: int = 0
export var width: int = 20
export var height: int = 20
export var can_draw = true

#var editor_can_draw = false
var editor_selected = false

var pos_x = 0
var pos_y = 0

var facing = "Right"

func update_position(x: int, y: int):
	pos_x = x
	pos_y = y

func x_facing():
	return x if facing == "Right" else -x

func get_absolute_position():
	return {
		"x": pos_x + x_facing(),
		"y": pos_y + y,
	}

func get_aabb():
	var x = x_facing()
	var x1: int = (x - width) + (pos_x)
	var x2: int = (x + width) + (pos_x)
	var y1: int = (y - height) + (pos_y)
	var y2: int = (y + height) + (pos_y)

	return {
		"x1": x1,
		"x2": x2,
		"y1": y1,
		"y2": y2
	}

func copy_to(box: CollisionBox):
	box.x = x
	box.y = y
	box.width = width
	box.height = height

func get_overlap(box: CollisionBox):
	var overlap = {
	}
	var aabb1 = get_aabb()
	var aabb2 = box.get_aabb()

	overlap["x1"] = Utils.int_max(aabb1.x1, aabb2.x1)
	overlap["y1"] = Utils.int_max(aabb1.y1, aabb2.y1)

	overlap["x2"] = Utils.int_min(aabb1.x2, aabb2.x2)
	overlap["y2"] = Utils.int_min(aabb1.y2, aabb2.y2)

	return overlap

func get_overlap_center(box: CollisionBox):
	var overlap = get_overlap(box)
	return {
		"x": (overlap.x1 + overlap.x2) / 2,
		"y": (overlap.y1 + overlap.y2) / 2
	}

func get_center():
	var aabb = get_aabb()
	return {
		"x": (aabb.x1 + aabb.x2) / 2,
		"y": (aabb.y1 + aabb.y2) / 2
	}

func get_center_float():
	var aabb = get_aabb()
	return Vector2((aabb.x1 + aabb.x2) / 2.0, (aabb.y1 + aabb.y2) / 2.0)

func get_overlap_center_float(box: CollisionBox):
	# used for hit effects
	var overlap = get_overlap(box)
	var center = Vector2((overlap.x1 + overlap.x2) / 2.0, (overlap.y1 + overlap.y2) / 2.0)
	return center

func get_hit_particle_location(box: CollisionBox):
	return get_overlap_center_float(box)

func overlaps(box: CollisionBox):
	if width == 0 and height == 0:
		return false
	if box.width == 0 and box.height == 0:
		return false
	if get("IS_SWEPT") or box.get("IS_SWEPT"):
		return false

	var aabb1 = get_aabb()
	var aabb2 = box.get_aabb()
	return !(aabb1.x1 > aabb2.x2 or aabb1.x2 < aabb2.x1 or aabb1.y1 > aabb2.y2 or aabb1.y2 < aabb2.y1)

func get_rect_float():
	var aabb = get_aabb()
	var x = x_facing()
	# for display purposes ONLY!!! DO NOT USE THIS FOR GAME LOGIC!!!!!!
	###################################################################
	return Rect2(x - width, y - height, width * 2, height * 2)

func box_draw():
		var parent = get_parent()
		if parent.is_in_group("BaseObj"):
			if parent.disabled:
				return
		var color = Color.red
		if "CollisionBox" in name:
			color = Color.teal
		elif "Hurtbox" in name:
			color = Color.yellow
			if parent.is_in_group("BaseObj"):
				if parent.projectile_invulnerable:
					color = Color.pink
				if parent.throw_invulnerable:
					color = Color.green
				if parent.aerial_attack_immune:
					color = Color.blueviolet
				if parent.grounded_attack_immune:
					color = Color.brown
				if parent.invulnerable:
					color = Color.blue
		
		elif "ThrowBox" in name:
			color = Color.purple
		
		var rect = get_rect_float()
		var fill = color
		var stroke = color
		fill.a = 0.25
		stroke.a = 0.5
		draw_rect(rect, fill, true)
		draw_rect(rect, stroke, false)

func can_draw_box():
	if !can_draw:
		return false
	if Engine.editor_hint:
		if editor_selected:
			return true
	else:
		return Global.show_hitboxes

func _ready():
	z_index = 1000

func _process(delta):
	update()
	if Engine.editor_hint:
		editor_selected = false

func _draw():
	if !can_draw_box():
		return
	
	box_draw()
