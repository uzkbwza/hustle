extends RobotState

export var chainsaw_start_tick = 10
export var chainsaw_end_tick = 19

const HITBOX_DISTANCE = "48"

var start_x
var start_y
var middle_x
var middle_y
var end_x
var end_y

var last_hitbox_x = null
var last_hitbox_y = null

onready var hitbox = $Hitbox
onready var hitbox2 = $Hitbox2

func _ready():
	hitbox.start_tick = chainsaw_start_tick + 1
	hitbox2.start_tick = chainsaw_start_tick + 1
	hitbox.active_ticks = chainsaw_end_tick - chainsaw_start_tick + 1
	hitbox2.active_ticks = chainsaw_end_tick - chainsaw_start_tick + 1
	iasa_on_hit = chainsaw_end_tick

func _enter():
	var start_vec = xy_to_dir(data["Start"].x, data["Start"].y)
	var end_vec = xy_to_dir(data["End"].x, data["End"].y)
	
	if host.get_facing_int() < 0:
#		start_vec.x = fixed.mul(start_vec.x, "-1")
		start_vec.y = fixed.mul(start_vec.y, "-1")
#		end_vec.x = fixed.mul(end_vec.x, "-1")
		end_vec.y = fixed.mul(end_vec.y, "-1")
#		middle_y = fixed.mul(middle_y, "-1")
#	middle_x = fixed.div(fixed.add(start_vec.x, end_vec.x), "2")
#	middle_y = fixed.div(fixed.add(start_vec.y, end_vec.y), "2")
	start_x = start_vec.x
	start_y = start_vec.y
	end_x = end_vec.x
	end_y = end_vec.y
#	if fixed.sign(middle_x) != host.get_facing_int():
#		middle_x = fixed.mul(middle_x, "-1")

func _frame_0():
	last_hitbox_x = null
	last_hitbox_y = null
	iasa_at = 34

func _tick():
	if current_tick < chainsaw_start_tick:
		host.chainsaw_arm.visible = false
	if current_tick >= chainsaw_start_tick and current_tick <= chainsaw_end_tick:
		var i = chainsaw_start_tick - current_tick
		var end = chainsaw_end_tick - chainsaw_start_tick
		host.chainsaw_arm.visible = true
		var t = fixed.abs(fixed.div(str(i), str(end)))
#		print(t)
		var current_x
		var current_y
		var start_vec = {
			"x": start_x,
			"y": start_y
		}
		var end_vec = {
			"x": end_x,
			"y": end_y,
		}
		var angle = fixed.lerp_angle(fixed.vec_to_angle(start_vec.x, start_vec.y), fixed.vec_to_angle(end_vec.x, end_vec.y), t)
		var hitbox_pos = fixed.angle_to_vec(angle)
		current_x = hitbox_pos.x
		current_y = hitbox_pos.y

#		if fixed.gt(t, "0.5"):
#			current_x = fixed.lerp_string(str(middle_x), end_vec.x, fixed.sub(fixed.mul(t, "2"), "0.5"))
#			current_y = fixed.lerp_string(str(middle_y), end_vec.y, fixed.sub(fixed.mul(t, "2"), "0.5"))
#		else:
#			current_x = fixed.lerp_string(start_vec.x, str(middle_x), fixed.mul(t, "3"))
#			current_y = fixed.lerp_string(start_vec.y, str(middle_y), fixed.mul(t, "3"))

		hitbox_pos = fixed.vec_mul(hitbox_pos.x, hitbox_pos.y, HITBOX_DISTANCE)
		var hitbox2_pos = fixed.vec_div(hitbox_pos.x, hitbox_pos.y, "2")
		var center_x = host.hurtbox.x
		var center_y = host.hurtbox.y
		hitbox.x = host.get_facing_int() * (fixed.round(hitbox_pos.x) + center_x)
		hitbox.y = ((fixed.floor(hitbox_pos.y) * host.get_facing_int()) + center_y) - 6
		hitbox2.x = host.get_facing_int() * (fixed.round(hitbox2_pos.x) + center_x)
		hitbox2.y = ((fixed.floor(hitbox2_pos.y) * host.get_facing_int()) + center_y) - 6
		var ghost_index = fixed.round(fixed.mul(t, str(len(host.chainsaw_arm_ghosts))))
		var arm_angle = float(angle)
		if ghost_index < len(host.chainsaw_arm_ghosts):
			if !host.chainsaw_arm_ghosts[ghost_index].visible:
				host.chainsaw_arm_ghosts[ghost_index].visible = true
				host.chainsaw_arm_ghosts[ghost_index].global_rotation = arm_angle
				
		var kb_dir
		var last_hitbox_pos = {
			"x": last_hitbox_x,
			"y": last_hitbox_y
		}
		if last_hitbox_x != null:
			kb_dir = fixed.vec_sub(str(hitbox.x), str(hitbox.y), str(last_hitbox_pos.x), str(last_hitbox_pos.y))
			kb_dir = fixed.normalized_vec(kb_dir.x, kb_dir.y)
		else:
			kb_dir = { "x": 1, "y": -1 }
			
		last_hitbox_x = hitbox.x
		last_hitbox_y = hitbox.y
		hitbox.dir_x = kb_dir.x
		hitbox.dir_y = kb_dir.y
		hitbox2.dir_x = kb_dir.x
		hitbox2.dir_y = kb_dir.y
		host.chainsaw_arm.global_rotation = arm_angle
	pass
#
#func _on_hit_something(obj, hitbox):
#	._on_hit_something(obj, hitbox)
#	if obj.is_in_group("Fighter"):
#		host.colliding_with_opponent = false
#	iasa_at = chainsaw_end_tick

func _exit():
	for ghost in host.chainsaw_arm_ghosts:
		ghost.hide()
	last_hitbox_x = null
	last_hitbox_y = null
	host.chainsaw_arm.hide()
