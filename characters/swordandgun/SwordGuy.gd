extends Fighter

signal bullet_used()

onready var shooting_arm = $"%ShootingArm"

const BARREL_LOCATION_X = "26"
const BARREL_LOCATION_Y = "-5"
const GUN_PICKUP_DISTANCE = "26"
const IS_COWBOY = true # lol
const RIFT_PROJECTILE = preload("res://characters/swordandgun/projectiles/AfterImageExplosion.tscn")
const AFTER_IMAGE_MAX_DIST = "300"

var bullets_left = 6
var cut_projectile = null
var lasso_projectile = null
var after_image_object = null
var used_aerial_h_slash = false
var used_aerial_l_slice = false
var has_gun = true
var gun_projectile = null
var consecutive_shots = 1
var shot_dir_x = 100
var shot_dir_y = 0
var lightning_slice_x = 0
var lightning_slice_y = 0
var up_swipe_momentum = true
var buffer_bullet_cancelling = false
var bullet_cancelling = false
var stance_teleport_x = 0
var detonating = false
var shifting = false
var shifted_this_frame = false
var stance_teleport_y = 0
var ticks_until_time_shift = 0

func _ready():
	shooting_arm.set_material(sprite.get_material())

func init(pos=null):
	.init(pos)
	bullets_left = 6

func copy_to(f):
	.copy_to(f)
	f.bullet_cancelling = bullet_cancelling

func get_barrel_location(angle):
	var barrel_location = fixed.rotate_vec(BARREL_LOCATION_X, BARREL_LOCATION_Y, angle)
	barrel_location.y = fixed.sub(barrel_location.y, "24")
	return barrel_location

func tick():
	if after_image_object:
		var obj = obj_from_name(after_image_object)
		if obj:
			if detonating:
				detonating = false
				obj.detonating = true
			else:
				if fixed.gt(distance_to(obj), AFTER_IMAGE_MAX_DIST):
					obj.detonating = true
			if shifting:
				if !is_grounded():
					if air_movements_left > 0:
						air_movements_left -= 1
				set_grounded(obj.is_grounded())
				if !obj.is_grounded():
					move_directly(0, -1)
				ticks_until_time_shift = 2
				hitlag_ticks += 6

	if hitlag_ticks <= 0:
		if ticks_until_time_shift > 0:
			var obj = obj_from_name(after_image_object)
			ticks_until_time_shift -= 1
			if ticks_until_time_shift == 1:
				if obj:
					play_sound("TimeShift")
					set_pos(obj.get_pos().x, obj.get_pos().y)
					hitlag_ticks += 2
					obj.disable()
					after_image_object = null
					shifted_this_frame = true
	.tick()

	if shifted_this_frame:
		update_facing()
		shifted_this_frame = false

	if ticks_until_time_shift > 0:
		sprite.animation = "TimeShift"

	if objs_map.has(cut_projectile):
		var proj = objs_map[cut_projectile]
		if proj == null or proj.disabled:
			cut_projectile = null
	if is_grounded():
		if used_aerial_h_slash:
			used_aerial_h_slash = false
		if used_aerial_l_slice:
			used_aerial_l_slice = false
		if !up_swipe_momentum:
			up_swipe_momentum = true
	if combo_count > 0:
		up_swipe_momentum = true
	if !has_gun and gun_projectile != null:
		var gun = objs_map[gun_projectile]
		if is_instance_valid(gun) and gun.data and !gun.disabled:
			var dist = obj_local_center(gun)
			if gun.can_be_picked_up and fixed.lt(fixed.vec_len(str(dist.x), str(dist.y)), GUN_PICKUP_DISTANCE):
				gun.disable()
				has_gun = true
				gun_projectile = null
				play_sound("GunPickup")
	if buffer_bullet_cancelling:
		bullet_cancelling = true
		buffer_bullet_cancelling = false
#	if bullet_cancelling and !("try_shoot" in current_state().host_commands.values()):
#		bullet_cancelling = false
	if shifting:
		shifting = false
		update_facing()

func process_extra(extra):
	.process_extra(extra)
	if extra.has("gun_cancel"):
		buffer_bullet_cancelling = extra.gun_cancel
	if extra.has("detonate"):
		detonating = extra.detonate
	if extra.has("shift"):
		shifting = extra.shift
			

func can_bullet_cancel():
	return bullets_left > 0 and has_gun

func try_shoot():
#	print("here")
	if got_parried:
		return
	if !bullet_cancelling:
		return
	if !has_gun:
		return
	if bullets_left > 0:
		bullet_cancelling = false
		change_state("QuickerDraw")

func on_state_ended(state):
	.on_state_ended(state)
	bullet_cancelling = false
	pass

func on_hit_something():
	pass

func use_bullet():
	if infinite_resources:
		return
	bullets_left -= 1
	emit_signal("bullet_used")

func on_got_hit():
	if cut_projectile:
		if objs_map.has(cut_projectile):
			objs_map[cut_projectile].disable()
			cut_projectile = null
	if after_image_object:
		var obj = obj_from_name(after_image_object)
		if obj != null:
			obj.disable()
			after_image_object = null

func _draw():
	._draw()
	if lasso_projectile:
		var obj = objs_map[lasso_projectile]
		var obj_pos = obj.get_pos()
		var draw_target = to_local(Vector2(obj_pos.x, obj_pos.y))
		draw_target -= draw_target.normalized() * 8
		draw_line(Vector2(0, -16), draw_target, Color("704137"), 2.0, false)
