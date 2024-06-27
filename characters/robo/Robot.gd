extends Fighter

class_name Robot

const MAX_ARMOR_PIPS = 1
const FLY_SPEED = "8.5"
const FLY_FORCE = "1.65"
const FORWARD_FLY_SPEED_MODIFIER = "1.0"
const MAX_FORWARD_FLIGHT_SPEED = "9"
const MAX_BACKWARD_FLIGHT_SPEED = "5"
const MAGNET_MIN_BOMB_DIST = 64
const MAGNET_MIN_TICKS = 10
const FLY_TICKS = 25
const MAX_FLY_UP_SPEED = "-6"
const MIN_FLY_UP_SPEED = "-4"
const GROUND_POUND_MIN_HEIGHT = -48
const LOIC_METER: int = 1000
const START_LOIC_METER: int = 500
const LOIC_GAIN = 5
const LOIC_GAIN_NO_ARMOR = 5
const MAGNET_TICKS = 100
const MAGNET_STRENGTH = "1.6"
const MAGNET_BOMB_STRENGTH = "1.0"
const COMBO_MAGNET_STRENGTH = "1.0"
const MAGNET_MAX_STRENGTH = "2.0"
const MAGNET_MIN_STRENGTH = "0.0"
const MAGNET_CENTER_DIST = "160"
const BOUNCE_SPEED = "10"
const MAGNET_RADIUS_DIST = "20"
const MAGNET_SAFE_DIST = MAGNET_CENTER_DIST
const MAGNET_MOVEMENT_AMOUNT = "14"
const NO_COMBO_MAGNET_MOVEMENT_AMOUNT = "9"
const NEUTRAL_MAGNET_LONG_DISTANCE_EXTRA_STRENGTH = "1"
const NEUTRAL_MAGNET_EXTRA_STRENGTH_DISTANCE = "175"
const NEUTRAL_MAGNET_MODIFIER = "0.25"
const NEUTRAL_MAGNET_MODIFIER_MAX = "2.75"
const MAGNET_VISUAL_ARC_SIZE = 20000
const ARMOR_STARTUP_TICKS = 3
const WC_EXTRA_ARMOR_STARTUP_TICKS = 2
const MAGNETIZE_OPPONENT_BLOCKED_MOD = "0.75"
const MAGNETIZE_BOMB_STRENGTH_INCREASE = "0.1"

const DRAIN_AIR_OPTION_BAR_AMOUNT = 20
const GAIN_AIR_OPTION_BAR_AMOUNT = 3
const GAIN_AIR_OPTION_BAR_ON_HIT = 300
const MIN_AIR_OPTION_BAR_AMOUNT = 80

const FLY_GRAV = "0.05"
const FLY_MAX_FALL_SPEED = "100.0"

var loic_draining = false
var armor_pips = 1
var landed_move = false
var flying_dir = null
var fly_ticks_left = 0
var fly_fx_started = false
var kill_process_super_level = 0
var start_fly = false
var can_ground_pound = false
var can_gain_ground_pound = true
var buffer_reset_ground_pound = false
var orbital_strike_out = false
var orbital_strike_projectile = null
var can_loic = false
var loic_meter = 0
var got_hit = false
var armor_active = false
var buffer_armor = false
var can_unlock_gratuitous = true
var can_flamethrower = true
var magnet_ticks_left = 0
var grenade_object = null
var flame_touching_opponent = null
var magnet_installed = false
var armor_startup_ticks = 0
#var magnet_scale = false
var used_earthquake_grab = false
var started_magnet_in_initiative = false
var force_fly = false
var magnetize_opponent = false
var magnetize_opponent_blocked = false
var magnetize_bomb_strength = "0"
var loic_dir = 0

var drive_cancel = false
var buffer_drive_cancel = false
var super_armor_installed = false
var propel_friction_ticks = 0

onready var chainsaw_arm = $"%ChainsawArm"
onready var drive_jump_sprite = $"%DriveJumpSprite"
onready var magnet_polygon = $"%MagnetPolygon"
onready var magnet_polygon2 = $"%MagnetPolygon2"

onready var chainsaw_arm_ghosts = [
]

func _ready():
	chainsaw_arm.set_material(sprite.get_material())
	drive_jump_sprite.set_material(sprite.get_material())
	for ghost in chainsaw_arm_ghosts:
		ghost.set_material(sprite.get_material())

#	setup_magnet_circle()

#func setup_magnet_circle():
#	if is_ghost:
#		return
#	var magnet_poly_size = 2000
#	magnet_polygon.polygon = PoolVector2Array()
#	magnet_polygon2.polygon = PoolVector2Array()
#	for mp in [magnet_polygon, magnet_polygon2]:
#		var outer = []
#		var hole = []
#		for i in range(65):
#			var t = ((PI / 64.0) * i)
#			var vec1 = Utils.ang2vec(t) * float(MAGNET_CENTER_DIST)
#			var vec2 = Utils.ang2vec(t) * float(magnet_poly_size)
#			if mp == magnet_polygon2:
#				vec1 *= -1
#				vec2 *= -1
#			outer.append(vec1)
#			hole.append(vec2)
#
#		var clipped = Geometry.clip_polygons_2d(PoolVector2Array(hole), PoolVector2Array(outer))
#		mp.polygon = clipped[0]

func init(pos=null):
	.init(pos)
	armor_pips = 1
	loic_meter = START_LOIC_METER
	if infinite_resources:
		can_loic = true
		loic_meter = LOIC_METER

func on_got_hit_by_fighter():
	if armor_active:
		got_hit = true

func on_got_parried():
	.on_got_parried()
	flying_dir = null
	can_ground_pound = false

func on_got_hit():
	gain_air_option_bar(GAIN_AIR_OPTION_BAR_ON_HIT / Utils.int_max(combo_count, 1))
	
func on_launched():
	if orbital_strike_projectile and orbital_strike_projectile in objs_map:
		objs_map[orbital_strike_projectile].deactivate()
		orbital_strike_out = false
		orbital_strike_projectile = null

func on_grabbed():
	on_launched()

func are_missiles_active():
	for object in get_active_projectiles():
		if object and object.get("IS_ROBOT_MISSILE"):
			return true
	return false

func copy_to(f: BaseObj):
	.copy_to(f)
	f.armor_active = armor_active
	f.magnet_ticks_left = magnet_ticks_left
	f.flying_dir = flying_dir
	if flying_dir != null:
		f.flying_dir = flying_dir.duplicate(true)
	f.flame_touching_opponent = flame_touching_opponent
	f.magnet_polygon.polygon = magnet_polygon.polygon
	f.magnet_polygon2.polygon = magnet_polygon2.polygon
	f.drive_cancel = drive_cancel
	f.buffer_drive_cancel = buffer_drive_cancel
	pass

func has_armor():
	return (armor_active and super_armor_installed and !(current_state() is CharacterHurtState))

func has_autoblock_armor():
	return (armor_active and !(current_state() is CharacterHurtState))


func incr_combo(scale=true, projectile=false, force=false, combo_scale_amount=1):
#	if magnet_scale:
#		if !scale:
#			combo_scale_amount = 0
#		combo_scale_amount += 1
#		scale = true
#		magnet_scale = false
	if combo_count == 0:
		landed_move = true
	.incr_combo(scale, force, projectile, combo_scale_amount)
	if can_unlock_gratuitous and combo_moves_used.has("GroundSlam") and current_state().name != "GroundSlam":
		unlock_achievement("ACH_GRATUITOUS")
		can_unlock_gratuitous = false
		pass
	pass

func apply_grav():
	if flying_dir == null or (fixed.lt(get_vel().y, "0") and flying_dir.x != 0 and flying_dir.y >= 0):
		.apply_grav()
	else:
		.apply_grav_custom(FLY_GRAV, FLY_MAX_FALL_SPEED)

func big_landing_effect():
	spawn_particle_effect_relative(preload("res://fx/LandingParticle.tscn"))
	play_sound("BigLanding")
	var camera = get_camera()
	if camera:
		camera.bump(Vector2.UP, 10, 20 / 60.0)

func magnetize():
	if magnetize_opponent:
		var dir = get_opponent_dir_vec()
		var strength = MAGNET_STRENGTH
		if magnetize_opponent_blocked:
			strength = fixed.mul(strength, MAGNETIZE_OPPONENT_BLOCKED_MOD)
		var force = fixed.vec_mul(dir.x, dir.y, fixed.mul(strength, "-1"))
		if fixed.round(distance_to(opponent)) < MAGNET_MIN_BOMB_DIST:
			if (MAGNET_TICKS - magnet_ticks_left) > MAGNET_MIN_TICKS:
				magnet_ticks_left = 1
		opponent.apply_force(force.x, force.y if opponent.is_grounded() else "0")
	var obj = obj_from_name(grenade_object)
	if obj:
		var dir = get_object_dir_vec(obj)
		var force = fixed.vec_mul(dir.x, dir.y, fixed.mul(fixed.mul(MAGNET_BOMB_STRENGTH, magnetize_bomb_strength), "-1"))
		if fixed.round(distance_to(obj)) < MAGNET_MIN_BOMB_DIST:
			if (MAGNET_TICKS - magnet_ticks_left) > MAGNET_MIN_TICKS:
				magnet_ticks_left = 1
		obj.apply_force(force.x, force.y)
	else:
		magnet_ticks_left = 1
	magnetize_bomb_strength = fixed.add(magnetize_bomb_strength, MAGNETIZE_BOMB_STRENGTH_INCREASE)
	if fixed.gt(magnetize_bomb_strength, "1.0") or magnetize_opponent:
		magnetize_bomb_strength = "1.0"


func add_armor_pip():
	if armor_pips < MAX_ARMOR_PIPS:
		spawn_particle_effect_relative(preload("res://characters/robo/ShieldEffect.tscn"), Vector2(0, -16))
		play_sound("ArmorBeep")
	armor_pips += 1
	if armor_pips > MAX_ARMOR_PIPS:
		armor_pips = MAX_ARMOR_PIPS

func can_perfect_parry():
	return flying_dir == null

func tick():
	.tick()
	if propel_friction_ticks > 0:
		propel_friction_ticks -= 1
		if propel_friction_ticks == 0:
			chara.set_ground_friction(ground_friction)
	if got_hit:
		armor_pips = 0
		got_hit = false
		buffer_armor = false
		if armor_active:
			super_armor_installed = false
		armor_active = false
		if armor_startup_ticks > 0:
			armor_startup_ticks = 0

	elif armor_startup_ticks > 0:
		armor_startup_ticks -= 1
		if armor_startup_ticks == 0:
			armor_active = true
			spawn_particle_effect_relative(preload("res://characters/robo/ShieldEffect2.tscn"), Vector2(0, -1
			))
			play_sound("ArmorBeep2")
			buffer_armor = false
	if current_state().is_grab and feinting and armor_active:
		feinting = false

	if magnet_ticks_left > 0:
#		start_magnet_fx()
		magnetize()
		magnet_ticks_left -= 1
	else:
		stop_magnet_fx()
		magnetize_opponent = false
		magnetize_opponent_blocked = false
		pass
	if landed_move:
		if not (current_state() is CharacterHurtState):
			add_armor_pip()
		landed_move = false
	if is_grounded() and !force_fly:
		flying_dir = null
		if fly_fx_started:
			stop_fly_fx()
		if air_option_bar < MIN_AIR_OPTION_BAR_AMOUNT:
			air_option_bar = MIN_AIR_OPTION_BAR_AMOUNT
		gain_air_option_bar(GAIN_AIR_OPTION_BAR_AMOUNT)

	if is_in_hurt_state():
		flying_dir = null
		stop_fly_fx()
#	if current_state() is GroundedParryState:
#		flying_dir = null
#		stop_fly_fx()
	if flying_dir != null and current_state().get("can_fly") != null and !current_state().can_fly:
		flying_dir = null
	if start_fly and flying_dir != null:
		fly_ticks_left = FLY_TICKS
#		use_air_movement()
		fly_fx_started = true
		start_fly = false
		start_fly_fx()

	if flying_dir:
		if current_tick % 5 == 0:
#			play_sound("FlySound")
			play_sound("CornerCarryFlyClick")
		if (!is_grounded() or force_fly):
#			var fly_vel = fixed.normalized_vec_times(str(flying_dir.x), str(flying_dir.y), FLY_SPEED)
			var vel = get_vel()
			var fly_force = fixed.normalized_vec_times(str(flying_dir.x), str(flying_dir.y), FLY_FORCE)
			if flying_dir.x == get_opponent_dir():
				fly_force.x = fixed.mul(fly_force.x, FORWARD_FLY_SPEED_MODIFIER)
			if force_fly:
				if fixed.ge(fly_force.y, "0"):
					fly_force.y = "0"
			
			var upward_speed = fly_force.y
			var upward_speed_mod = "1.0"
			var air_options_ratio = fixed.div(str(air_option_bar), str(air_option_bar_max))
			if fixed.lt(fly_force.y, "0"):
				upward_speed_mod = "1.0"
				upward_speed_mod = fixed.mul(upward_speed_mod, air_options_ratio)
				if fixed.lt(upward_speed_mod, "0.3"):
					upward_speed_mod = "0.3"

			if flying_dir.y < 0 and fixed.gt(vel.y, "0"):
				update_data()
				vel = get_vel()
				set_vel(vel.x, "0")

			if flying_dir.y > 0 and fixed.lt(vel.y, "0"):
				update_data()
				vel = get_vel()
				set_vel(vel.x, fixed.mul(vel.y, "0.75"))

			apply_force(fly_force.x, fixed.mul(upward_speed, fixed.mul(upward_speed_mod, "0.4")))
			
			var max_horiz_speed = MAX_BACKWARD_FLIGHT_SPEED if fixed.sign(vel.x) != get_opponent_dir() else MAX_FORWARD_FLIGHT_SPEED

			if fixed.lt(vel.y, MAX_FLY_UP_SPEED):
				update_data()
				vel = get_vel()
				set_vel(vel.x, MAX_FLY_UP_SPEED)

			if fixed.abs(vel.x) > max_horiz_speed and fixed.sign(vel.x) == flying_dir.x:
				update_data()
				vel = get_vel()
				set_vel(fixed.mul(max_horiz_speed, str(fixed.sign(vel.x))), vel.y)

			if fixed.eq(fixed.vec_len(fly_force.x, fly_force.y), "0"):
				var new_vel = fixed.vec_mul(vel.x, vel.y, "0.90")
				set_vel(new_vel.x, new_vel.y)
			
			drain_air_option_bar(DRAIN_AIR_OPTION_BAR_AMOUNT)
			

			fly_ticks_left -= 1
			if fly_ticks_left <= 0: 
				flying_dir = null
				stop_fly_fx()
			elif current_tick % 2 == 0:
				if flying_dir.x != 0:
					if flying_dir.x != get_opponent_dir():
						add_penalty(1)
				elif flying_dir.y == -1:
					add_penalty(1)

	if (loic_meter < LOIC_METER) and !loic_draining:
		var obj = obj_from_name(orbital_strike_projectile)
		var can_gain_loic = true
		if obj and obj.active:
			can_gain_loic = false
		if can_gain_loic:
			if armor_pips > 0:
				loic_meter += LOIC_GAIN
			else:
				loic_meter += LOIC_GAIN_NO_ARMOR
		if infinite_resources:
			loic_meter = LOIC_METER
			can_loic = true
	if loic_meter >= LOIC_METER and supers_available > 1:
		if !can_loic:
			play_sound("LOICBeep")
		can_loic = true
		loic_meter = LOIC_METER
	else:
		can_loic = false

	if buffer_reset_ground_pound:
		buffer_reset_ground_pound = false
		can_ground_pound = false
		
	if is_grounded() and !current_state().started_in_air:
		buffer_reset_ground_pound = true
		can_gain_ground_pound = true

	if !can_ground_pound and can_gain_ground_pound and get_pos().y < GROUND_POUND_MIN_HEIGHT and !is_in_hurt_state():
		can_ground_pound = true
		can_gain_ground_pound = false
		ground_pound_active_effect()
	if buffer_drive_cancel:
		buffer_drive_cancel = false
		drive_cancel = true

	if air_option_bar == 0 and flying_dir:
		flying_dir = null
		stop_fly_fx()

func start_magnetizing():
	magnet_ticks_left = MAGNET_TICKS
	magnetize_bomb_strength = "0"
	var obj = obj_from_name(grenade_object)
	if obj:
		obj.refresh()
#	if combo_count > 0:
#		magnet_scale = true
	play_sound("MagnetBeep")
	stop_hustle_fx()
	start_magnet_fx()
	magnet_installed = false


func stop_flying():
	flying_dir = null
	stop_fly_fx()

#func on_state_initiative_start():
#	started_magnet_in_initiative = true
#	if magnet_ticks_left > 0:
#		current_state().initiative_effect()
#	pass

func reset_combo():
	.reset_combo()
#	magnet_scale = false
	used_earthquake_grab = false

func ground_pound_active_effect():
	spawn_particle_effect_relative(preload("res://characters/robo/GroundPoundActiveEffect.tscn"), Vector2(0, -16))
	play_sound("GroundPoundBeep")
	pass
	
func start_fly_fx():
	$"%FlyFx1".start_emitting()
	$"%FlyFx2".start_emitting()

func stop_fly_fx():
	fly_fx_started = false
	$"%FlyFx1".stop_emitting()
	$"%FlyFx2".stop_emitting()

func start_hustle_fx():
	$"%HustleEffect".start_emitting()

func stop_hustle_fx():
	$"%HustleEffect".stop_emitting()
	
func start_magnet_fx():
	$"%MagnetEffect".start_emitting()
#	magnet_polygon.show()
#	magnet_polygon2.show()

func stop_magnet_fx():
	$"%MagnetEffect".stop_emitting()
#	magnet_polygon.hide()
#	magnet_polygon2.hide()
	
func process_extra(extra):
	.process_extra(extra)
	var can_fly = true
	force_fly = false
#	if current_state().get("can_fly") != null and current_state().can_fly == false:
#		can_fly = false
	if busy_interrupt:
		can_fly = false
#	if fly_blocked:
#		can_fly = false
	if extra.has("fly_dir") and (!is_grounded() or extra.get("force_fly")) and can_fly:
		if extra.has("fly_enabled") and extra.fly_enabled and air_option_bar > 0:
			var same_dir = flying_dir == null or (flying_dir.x == extra.fly_dir.x and flying_dir.y == extra.fly_dir.y)
			if flying_dir == null or !same_dir:
				start_fly = true
#			reset_momentum()
			flying_dir = extra.fly_dir
			if extra.has("force_fly"):
				force_fly = extra.force_fly
		elif extra.has("fly_enabled") and !extra.fly_enabled:
			flying_dir = null
	
	if extra.has("loic_dir"):
#		var obj = obj_from_name(orbital_strike_projectile)
#		var can_change = true
#		if obj:
#			if obj.active && obj.current_state().current_tick > 0:
#				can_change = false
#		if can_change:
		loic_dir = extra.loic_dir.x

	if extra.has("armor_enabled") and armor_pips > 0:
		buffer_armor = extra.armor_enabled
		if extra.armor_enabled:
			if current_state().state_name == "WhiffInstantCancel":
				armor_startup_ticks += WC_EXTRA_ARMOR_STARTUP_TICKS
#				print("hello")
				
	if extra.has("nade_activated") and grenade_object != null:
		if extra.nade_activated:
			var nade = obj_from_name(grenade_object)
			if nade:
				if !nade.active:
					nade.activate()
					if extra.has("bounce"):
						if extra.bounce.x != 0 or extra.bounce.y != 0:
							var speed = BOUNCE_SPEED
							var force = xy_to_dir(extra.bounce.x, extra.bounce.y, speed)
							nade.play_sound("Bounce")
							nade.reset_momentum()
							nade.apply_force(force.x, force.y)

					
	if extra.has("pull_enabled") and magnet_installed and !buffer_armor:
		if extra.pull_enabled:
			start_magnetizing()

	if extra.has("drive_cancel"):
		buffer_drive_cancel = extra.drive_cancel

func on_attack_blocked():
	if current_state().get_host_command("try_drive_cancel"):
		if drive_cancel:
			drive_cancel = false
			buffer_drive_cancel = false
			if stance == "Drive":
				change_state("UnDriveCancel")
			else:
				change_state("DriveCancel")
	gain_air_option_bar(GAIN_AIR_OPTION_BAR_ON_HIT / 4)
	can_ground_pound = false

func on_blocked_melee_attack():
	.on_blocked_melee_attack()
	flying_dir = null
	stop_fly_fx()
	pass

func use_burst():
	.use_burst()
	air_option_bar = air_option_bar_max

func try_drive_cancel(fast=false):
#	print("here")
	if got_parried:
		return
	if !drive_cancel:
		return
	drive_cancel = false
	if stance == "Drive":
		change_state("UnDriveCancel")
	else:
		change_state("DriveCancel" if !fast else "FastDriveCancel")

func on_state_ended(state):
	drive_cancel = false

func debug_text():
	.debug_text()
	debug_info(
		{
			"flying_dir": flying_dir
		}
	)

func _on_state_exited(state):
	._on_state_exited(state)
	if buffer_armor:
		armor_startup_ticks += ARMOR_STARTUP_TICKS
		armor_pips = 0
	else:
		if armor_active:
			super_armor_installed = false
		armor_active = false

func on_state_interruptable(state=null):
	.on_state_interruptable(state)
	if armor_active:
		super_armor_installed = false
	armor_active = false

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		gain_air_option_bar(GAIN_AIR_OPTION_BAR_ON_HIT / Utils.int_max(combo_count, 1))
		
