extends Fighter

class_name Cowboy

signal bullet_used()

export(Texture) var epic_horse_moment

onready var shooting_arm = $"%ShootingArm"
const FORESIGHT = preload("res://characters/swordandgun/projectiles/AfterImage.tscn")
const BARREL_LOCATION_X = "26"
const BARREL_LOCATION_Y = "-5"
const GUN_PICKUP_DISTANCE = "26"
const GUN_PICKUP_DISTANCE_BOOMERANG = "32"
const IS_COWBOY = true # lol
const RIFT_PROJECTILE = preload("res://characters/swordandgun/projectiles/AfterImageExplosion.tscn")
const AFTER_IMAGE_MAX_DIST = "410"
const MAX_AIR_SPEED_1KCUTS = "12"
const CUTS_METER_DRAIN_1 = 2
const DRIFT_JUMP_TIMER = 4
const CUTS_METER_DRAIN_2 = 3
const DRIFT_SUPERS = 1
const GROUNDED_DRIFT_JUMP_SPEED = "-3"
const CUTS_EFFECT = preload("res://characters/swordandgun/projectiles/1000CutsEffect.tscn")
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
var temporal_round = null
var drift_effect = false
var fatal_cut_move_dir_x = 0
var fatal_cut_move_dir_y = 0
var fatal_cut_start_pos_x = 0
var fatal_cut_start_pos_y = 0
var drift_jump_timer = 0

var shifted_this_frame = false
var shifted_last_frame = false
var stance_teleport_y = 0
var ticks_until_time_shift = 0
var lasso_parried = false
var default_max_air_speed = "9"
var milk_toggled = false
var milk_toggle_tick = 0

var shifted_this_turn = false

func _ready():
	shooting_arm.set_material(sprite.get_material())
	material = null

func init(pos=null):
	.init(pos)
	bullets_left = 6
	HOLD_FORCE_STATES["QuickerDraw"] = "SlowHolster"
	HOLD_RESTARTS.append("DashForward1k")

func copy_to(f):
	.copy_to(f)
	f.bullet_cancelling = bullet_cancelling

func get_barrel_location(angle, modifier="1.0"):
	var vec = fixed.rotate_vec(BARREL_LOCATION_X, BARREL_LOCATION_Y, angle)
	var barrel_location = fixed.vec_mul(vec.x, vec.y, modifier)
	barrel_location.y = fixed.sub(barrel_location.y, "24")
	return barrel_location

func shift():
	if opponent.combo_count > 0:
		return
	var obj = obj_from_name(after_image_object)
	
	if obj:
		set_pos(obj.get_pos().x, obj.get_pos().y)

		obj.disable()
		after_image_object = null
		shifted_this_frame = true
		if obj.get_pos().y >= 0:
			set_vel(get_vel().x, "0")
		if combo_count <= 0:
			add_penalty(15)

func start_1k_cuts_buff():
	max_air_speed = MAX_AIR_SPEED_1KCUTS
	chara.set_max_air_speed(MAX_AIR_SPEED_1KCUTS)

func end_1k_cuts_buff():
	max_air_speed = default_max_air_speed
	spawn_particle_effect_relative(CUTS_EFFECT, Vector2(0, -16))
	chara.set_max_air_speed(default_max_air_speed)

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
			if shifting and current_state().state_name != "Shift":
				set_grounded(obj.is_grounded())
				if !obj.is_grounded():
					move_directly(0, -1)
				shifted_this_turn = true
				change_state("Shift")
			elif current_state().state_name == "Shift":
				shifting = false

	.tick()

	if drift_effect:
		spawn_particle_effect_relative(preload("res://characters/swordandgun/freshmilkparticle.tscn"), Vector2(0, 0))

	if drift_jump_timer > 0:
		drift_jump_timer -= 1
		if drift_jump_timer == 0:
			apply_force("0", GROUNDED_DRIFT_JUMP_SPEED)
			move_directly(0, -1)
			set_grounded(false)

#	if id == 1:
#		print(current_state().entered_in_air)

#	if ((current_state().air_type == CharacterState.AirType.Grounded and !is_grounded() and current_state().entered_in_air) or (current_state().air_type == CharacterState.AirType.Aerial and is_grounded() and !current_state().entered_in_air)) and !is_in_hurt_state():
#		drift()


	if shifted_last_frame:
		if current_state().current_tick == 1 and current_state().has_hitboxes and not "Grab" in current_state().state_name:
			state_tick()
			state_tick()
		
		shifted_last_frame = false

	if shifted_this_frame:
		update_facing()
		shifted_this_frame = false
		shifted_last_frame = true

	if objs_map.has(cut_projectile):
		var proj = objs_map[cut_projectile]
		if proj == null or proj.disabled:
			cut_projectile = null
#		else:
#			if current_tick % 2 == 0:
#				use_super_meter(CUTS_METER_DRAIN_1)
#			else:
#				use_super_meter(CUTS_METER_DRAIN_2)
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
			var pickup_dist = GUN_PICKUP_DISTANCE_BOOMERANG if gun.shot else GUN_PICKUP_DISTANCE
			if gun.can_be_picked_up and fixed.lt(fixed.vec_len(str(dist.x), str(dist.y)), pickup_dist):
				gun.disable()
				has_gun = true
				gun_projectile = null
				play_sound("GunPickup")
			if opponent.combo_count > 0:
				gun.deactivate_current_hitbox()
	if buffer_bullet_cancelling:
		bullet_cancelling = true
		buffer_bullet_cancelling = false
#	if bullet_cancelling and !("try_shoot" in current_state().host_commands.values()):
#		bullet_cancelling = false

func drift():
	var obj = obj_from_name(after_image_object)
	if supers_available >= DRIFT_SUPERS:
		if obj:
			detonating = false
			obj.detonating = true
			if !milk_toggled:
				if is_grounded():
					current_state().entered_in_air = true
					current_state().started_in_air = true
					drift_jump_timer = DRIFT_JUMP_TIMER
#						hitlag_ticks += 2
					
				milk_toggled = true
				milk_toggle_tick = current_tick
				prediction_effect(10)
#				use_air_movement()
				for i in range(DRIFT_SUPERS):
					use_super_bar()
				combo_supers += 1

				set_vel(get_vel().x, "0")
				drift_effect = true

func process_extra(extra):
	.process_extra(extra)
	if extra.has("gun_cancel"):
		buffer_bullet_cancelling = extra.gun_cancel
	if extra.has("detonate"):
		detonating = extra.detonate
	if extra.has("shift"):
		shifting = extra.shift
		if shifting:
			shifted_this_turn = true
			if current_state().get("IS_NEW_PARRY"):
				change_state("Wait")
	if extra.has("drift") and extra.drift:
		drift()

	if extra.has("hindsight") and supers_available > 0:
		if extra.hindsight:
			ex_effect(0)
#			drain_super_meter(MAX_SUPER_METER / 2)
			use_super_bar()
#			super_effect(1)
			var obj = obj_from_name(after_image_object) 
			if obj:
				obj.detonating = true
			var foresight = spawn_object(FORESIGHT, 0, 0)
			setup_foresight(foresight)

func setup_foresight(projectile):
	projectile.sprite.set_material(sprite.get_material())
	after_image_object = projectile.obj_name

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
		can_update_sprite = false
		change_state("QuickerDraw")

func on_state_ended(state):
	.on_state_ended(state)
	if state.state_name == "Roll":
		lasso_parried = false
	bullet_cancelling = false

	if milk_toggle_tick < current_tick:
		drift_effect = false
	milk_toggled = false

func use_bullet():
	if infinite_resources:
		return
	bullets_left -= 1
	emit_signal("bullet_used")

func has_1k_cuts():
	return cut_projectile != null

func on_attack_blocked():
	if !bullet_cancelling:
		return
	if !has_gun:
		return
	if bullets_left > 0:
		bullet_cancelling = false
		can_update_sprite = false
		change_state("Brandish")

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

func can_block_cancel():
	if current_state().name == "Brandish" or current_state().name == "QuickerDraw":
		return false
	return .can_block_cancel()

func on_state_started(state):
	.on_state_started(state)
#
#func can_guard_break():
#	return .can_guard_break() and !milk_toggled

func should_free_cancel_allow_grounded_and_aerial_states():
	return current_state().state_name != "QuickerDraw" and .should_free_cancel_allow_grounded_and_aerial_states()

func _draw():
	._draw()
	var draw_target = Vector2()
	var draw_lasso = false
	if lasso_projectile:
		draw_lasso = true
		var obj = objs_map[lasso_projectile]
		var obj_pos = obj.get_pos()
		draw_target = to_local(Vector2(obj_pos.x, obj_pos.y))
	elif lasso_parried:
		draw_lasso = true
		draw_target = to_local(opponent.get_center_position_float())
	elif gun_projectile:
		var gun = obj_from_name(gun_projectile)
		if gun and gun.lassoed:
			draw_lasso = true
			draw_target = to_local(gun.get_center_position_float())
		
	draw_target -= draw_target.normalized() * 8
	if draw_lasso:
		draw_line(Vector2(0, -16), draw_target, Color("704137"), 2.0, false)
