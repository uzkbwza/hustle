extends Fighter

class_name Robot

const MAX_ARMOR_PIPS = 1
const FLY_SPEED = "8"
const FLY_TICKS = 20
const GROUND_POUND_MIN_HEIGHT = -48
const LOIC_METER: int = 1000
const START_LOIC_METER: int = 500
const LOIC_GAIN = 6
const LOIC_GAIN_NO_ARMOR = 6
const MAGNET_TICKS = 8
const MAGNET_STRENGTH = "2"
const COMBO_MAGNET_STRENGTH = "0.5"
const MAGNET_MAX_STRENGTH = "1.5"
const MAGNET_MIN_STRENGTH = "0.5"
const MAGNET_CENTER_DIST = "250"
const MAGNET_RADIUS_DIST = "200"
const MAGNET_MOVEMENT_AMOUNT = "18"

var loic_draining = false
var armor_pips = 1
var landed_move = false
var flying_dir = null
var fly_ticks_left = 0
var fly_fx_started = false
var kill_process_super_level = 0
var start_fly = false
var can_ground_pound = false
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

onready var chainsaw_arm = $"%ChainsawArm"
onready var drive_jump_sprite = $"%DriveJumpSprite"
onready var chainsaw_arm_ghosts = [
]

func _ready():
	chainsaw_arm.set_material(sprite.get_material())
	drive_jump_sprite.set_material(sprite.get_material())
	for ghost in chainsaw_arm_ghosts:
		ghost.set_material(sprite.get_material())

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

func on_got_hit():
	if !armor_active:
		if orbital_strike_projectile and orbital_strike_projectile in objs_map:
			objs_map[orbital_strike_projectile].disable()
			orbital_strike_out = false
			orbital_strike_projectile = null
#		if magnet_ticks_left > 1:
#			magnet_ticks_left = 1

func copy_to(f: BaseObj):
	.copy_to(f)
	f.armor_active = armor_active
	f.magnet_ticks_left = magnet_ticks_left
	f.flying_dir = flying_dir
	if flying_dir != null:
		f.flying_dir = flying_dir.duplicate(true)
	f.flame_touching_opponent = flame_touching_opponent
	pass

func has_armor():
	return armor_active and !(current_state() is CharacterHurtState)

func incr_combo(scale=true, projectile=false, force=false, combo_scale_amount=1):
	if combo_count == 0:
		landed_move = true
	.incr_combo(scale, force, projectile, combo_scale_amount)
	if can_unlock_gratuitous and combo_moves_used.has("GroundSlam") and current_state().name != "GroundSlam":
		unlock_achievement("ACH_GRATUITOUS")
		can_unlock_gratuitous = false
		pass
	pass

func apply_grav():
	if flying_dir == null:
		.apply_grav()

func big_landing_effect():
	spawn_particle_effect_relative(preload("res://fx/LandingParticle.tscn"))
	play_sound("BigLanding")
	var camera = get_camera()
	if camera:
		camera.bump(Vector2.UP, 10, 20 / 60.0)

func magnetize():
	var my_pos_relative = opponent.obj_local_center(self)
	var dist = fixed.vec_len(str(my_pos_relative.x), str(my_pos_relative.y))
	if fixed.gt(dist, "32"):
				
#		var magnet_strength = COMBO_MAGNET_STRENGTH if combo_count > 0 else MAGNET_STRENGTH
#		if combo_count <= 0 and opponent.combo_count <= 0:
		var max_dist = fixed.add(MAGNET_CENTER_DIST, MAGNET_RADIUS_DIST)
		var min_dist = fixed.sub(MAGNET_CENTER_DIST, MAGNET_RADIUS_DIST)
		var magnet_strength = fixed_map(min_dist, max_dist, MAGNET_MIN_STRENGTH, MAGNET_MAX_STRENGTH, dist)
#			if fixed.lt(magnet_strength, MAGNET_MIN_STRENGTH):
#				magnet_strength = MAGNET_MIN_STRENGTH
#			elif fixed.gt(magnet_strength, MAGNET_MAX_STRENGTH):
#				magnet_strength = MAGNET_MAX_STRENGTH
		
		var dir = fixed.normalized_vec(str(my_pos_relative.x), str(my_pos_relative.y))
		var force = fixed.vec_mul(dir.x, dir.y, magnet_strength)
		var direct_movement = fixed.vec_mul(dir.x, dir.y, MAGNET_MOVEMENT_AMOUNT)
		if combo_count <= 0:
			force.x = force.x if !opponent.is_grounded() else fixed.mul(force.x, "0.65")

		opponent.apply_force(force.x, force.y if !opponent.is_grounded() else "0")
		if fixed.gt(dist, "90"):
			opponent.move_directly(direct_movement.x, direct_movement.y if !opponent.is_grounded() else "0")


func add_armor_pip():
	if armor_pips < MAX_ARMOR_PIPS:
		spawn_particle_effect_relative(preload("res://characters/robo/ShieldEffect.tscn"), Vector2(0, -16))
		play_sound("ArmorBeep")
	armor_pips += 1
	if armor_pips > MAX_ARMOR_PIPS:
		armor_pips = MAX_ARMOR_PIPS

func tick():
	.tick()
	if got_hit:
		armor_pips = 0
		got_hit = false
		buffer_armor = false
		armor_active = false
#	if armor_active:
#		armor_pips = 0
	if magnet_ticks_left > 0:
		start_magnet_fx()
		magnetize()
		magnet_ticks_left -= 1
	if magnet_ticks_left == 0:
		stop_magnet_fx()
	if landed_move:
		if not (current_state() is CharacterHurtState):
			add_armor_pip()
		landed_move = false
	if is_grounded():
		flying_dir = null
		if fly_fx_started:
			stop_fly_fx()
	if is_in_hurt_state():
		flying_dir = null
	if flying_dir != null and current_state().get("can_fly") != null and !current_state().can_fly:
		flying_dir = null
	if start_fly and flying_dir != null:
		fly_ticks_left = FLY_TICKS
		air_movements_left -= 1
		fly_fx_started = true
		start_fly = false
		start_fly_fx()
	if flying_dir:
		if !is_grounded():
			var fly_vel = fixed.normalized_vec_times(str(flying_dir.x), str(flying_dir.y), FLY_SPEED)
			set_vel(fly_vel.x, fixed.mul(fly_vel.y, "0.66"))
			fly_ticks_left -= 1
			if fly_ticks_left <= 0:
				flying_dir = null
				stop_fly_fx()
	if (loic_meter < LOIC_METER) and !loic_draining:
		if armor_pips > 0:
			loic_meter += LOIC_GAIN
		else:
			loic_meter += LOIC_GAIN_NO_ARMOR
		if infinite_resources:
			loic_meter = LOIC_METER
			can_loic = true
	if loic_meter >= LOIC_METER and supers_available > 0:
		if !can_loic:
			play_sound("LOICBeep")
		can_loic = true
		loic_meter = LOIC_METER
	else:
		can_loic = false
	
	if buffer_reset_ground_pound:
		buffer_reset_ground_pound = false
		can_ground_pound = false
	if is_grounded():
		buffer_reset_ground_pound = true

	if !can_ground_pound and get_pos().y < GROUND_POUND_MIN_HEIGHT and !is_in_hurt_state():
		can_ground_pound = true
		ground_pound_active_effect()

func start_magnetizing():
	magnet_ticks_left = MAGNET_TICKS
	play_sound("MagnetBeep")
	stop_hustle_fx()
	opponent.reset_momentum()
	magnet_installed = false
	pass

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

func stop_magnet_fx():
	$"%MagnetEffect".stop_emitting()

func process_extra(extra):
	.process_extra(extra)
	var can_fly = true
#	if current_state().get("can_fly") != null and current_state().can_fly == false:
#		can_fly = false
	if busy_interrupt:
		can_fly = false
	if extra.has("fly_dir") and !is_grounded() and can_fly:
		if extra.has("fly_enabled") and extra.fly_enabled and air_movements_left > 0:
			var same_dir = flying_dir == null or (flying_dir.x == extra.fly_dir.x and flying_dir.y == extra.fly_dir.y)
			if flying_dir == null or !same_dir:
				start_fly = true
#			reset_momentum()
			flying_dir = extra.fly_dir
	if extra.has("armor_enabled") and armor_pips > 0:
		buffer_armor = extra.armor_enabled
	if extra.has("nade_activated") and grenade_object != null:
		if extra.nade_activated:
			var nade = obj_from_name(grenade_object)
			if nade:
				if !nade.active:
					nade.activate()
	if extra.has("pull_enabled") and magnet_installed:
		if extra.pull_enabled:
			start_magnetizing()

func _on_state_exited(state):
	._on_state_exited(state)
	if buffer_armor:
		armor_active = true
		spawn_particle_effect_relative(preload("res://characters/robo/ShieldEffect2.tscn"), Vector2(0, -16))
		play_sound("ArmorBeep2")
		buffer_armor = false
		armor_pips = 0
	else:
		armor_active = false

func on_state_interruptable(state=null):
	.on_state_interruptable(state)
	armor_active = false
#
#func on_state_started(state):
#	.on_state_started(state)
#	flying_states_left -= 1
#	if flying_states_left == 0:
#		flying_dir = null
	


#func launched_by(hitbox):
#	if armor_pips > 0:
#		hitlag_ticks = hitbox.victim_hitlag + (COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES if hitbox.counter_hit else 0)
#		hitlag_applied = hitlag_ticks
#		if hitbox.rumble:
#			rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
#
#		emit_signal("got_hit")
#		take_damage(hitbox.damage, hitbox.minimum_damage)
#		armor_pips -= 1
#	else:
#		.launched_by(hitbox)
