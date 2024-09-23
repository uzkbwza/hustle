extends Fighter

const ORB_SCENE = preload("res://characters/wizard/projectiles/orb/Orb.tscn")
const ORB_PARTICLE_SCENE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")

const HOVER_AMOUNT = 1200
const HOVER_MIN_AMOUNT = 250
const HOVER_VEL_Y_POS_MODIFIER = "0.70"
const HOVER_VEL_Y_NEG_MODIFIER = "0.94"
const HOVER_GROUND_FRIC = "0.025"
const ORB_SUPER_DRAIN = 2
const FAST_FALL_SPEED = "7"
const ORB_PUSH_SPEED = "8.5"
const TETHER_FALLOFF = "0.95"
const TETHER_SPEED = "1.5"
const TETHER_TICKS = 90
const SPARK_BOMB_PUSH_DISTANCE = "90"
const SPARK_EXPLOSION_AIR_SPEED = 25
const SPARK_EXPLOSION_GROUND_SPEED = 20
const SPARK_EXPLOSION_DASH_SPEED = 12
const SPARK_SPEED_FRAMES = 70
const SPARK_BOMB_SELF_DAMAGE = 31 
const FLAME_WAVE_COOLDOWN = 30
const ORB_DRAIN_INCREASE_FREQUENCY = 70

var hover_left = 0
var hover_drain_amount = 25
var fast_fall_drain_amount = 20
var hover_gain_amount = 12
var hover_gain_amount_depleted = 4
var hover_gain_amount_air = -1
var hovering = false
var ghost_started_hovering = false
var fast_falling = false
var fast_fall_landing = false
var gusts_in_combo = 0
var tether_ticks = 0
var geyser_charge = 0

var orb_duration = 0
var orb_accumulator = 0

var orb_projectile = null
var can_flame_wave = true
var can_vile_clutch = true
var current_orb_push = null
var detonating_bombs = false
var boulder_projectile = null
var flame_wave_cooldown = 0

var spark_bombs = []
var nearby_spark_bombs = []

var default_dash_speed = 0
var spark_speed_frames = 0

onready var liftoff_sprite = $"%LiftoffSprite"
onready var spark_speed_particle = $"%SparkSpeedParticle"

func copy_to(f):
	.copy_to(f)
	f.boulder_projectile = boulder_projectile

func init(pos=null):
	.init(pos)
	hover_left = (HOVER_AMOUNT / 4) * 3
	if infinite_resources:
		hover_left = HOVER_AMOUNT
	geyser_charge = 0
	if infinite_resources:
		geyser_charge = 3
	default_dash_speed = $StateMachine/DashForward.dash_speed


func on_blocked_melee_attack():
	.on_blocked_melee_attack()
	hovering = false
	
func on_roll_started():
	hovering = false
	fast_falling = false

func on_parried():
	add_geyser_charge()

func apply_grav():
	if fast_falling:
		apply_grav_custom(FAST_FALL_SPEED, FAST_FALL_SPEED)
	if !hovering:
		.apply_grav()

func apply_grav_fast_fall():
	move_directly("0", FAST_FALL_SPEED)

func apply_grav_custom(grav: String, fall_speed: String):
	if !hovering:
		.apply_grav_custom(grav, fall_speed)

func add_geyser_charge():
	geyser_charge += 1
	if geyser_charge > 3:
		geyser_charge = 3
	play_sound("Droplet")

func apply_fric():
	if !is_grounded():
		.apply_fric()
	else:
		if hovering:
			apply_x_fric(HOVER_GROUND_FRIC)
		else:
			.apply_fric()
	pass

func add_spark_bomb(projectile_name):
	spark_bombs.append(projectile_name)

func spawn_orb():
		var orb = spawn_object(ORB_SCENE, -10, -56)
		spawn_particle_effect_relative(ORB_PARTICLE_SCENE, Vector2(-10, -56))
		orb_projectile = orb.obj_name

func stack_move_in_combo(move_name):
	.stack_move_in_combo(move_name)
	if combo_moves_used.has("TomeSlap"):
		if combo_moves_used["TomeSlap"] >= 5:
			unlock_achievement("ACH_SUGARCOAT")

func on_state_started(state):
	.on_state_started(state)
	if state.busy_interrupt_type == CharacterState.BusyInterrupt.Hurt:
		fast_falling = false
		detonating_bombs = false
	if state is CharacterHurtState:
		hovering = false
		detonating_bombs = false

func gain_super_meter(amount,stale_amount = "1.0"):
	if orb_projectile:
		amount = fixed.round(fixed.mul(str(amount), "0.5"))
	.gain_super_meter(amount, stale_amount)
	
func on_got_hit():
	hovering = false
	fast_falling = false
	if boulder_projectile != null:
		var obj = obj_from_name(boulder_projectile)
		if obj:
			obj.drop()
		boulder_projectile = null

func on_got_parried():
	.on_got_parried()
	if spark_speed_frames > 0:
		hitlag_ticks += 6
	hovering = false

func incr_combo(scale=true, projectile=false, force=false, combo_scale_amount=1):
	if !projectile:
		if combo_count < 1:
			if not "Geyser" in current_state().name and not "Burst" in current_state().name:
				add_geyser_charge()
	.incr_combo(scale, projectile, force, combo_scale_amount)
	

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)

func tick():
	if spark_speed_frames > 0:
		chara.set_max_ground_speed(str(SPARK_EXPLOSION_GROUND_SPEED))
		chara.set_max_air_speed(str(SPARK_EXPLOSION_AIR_SPEED))
		$StateMachine/DashForward.dash_speed = SPARK_EXPLOSION_DASH_SPEED
		$StateMachine/Jump.x_modifier = "1.5"
		$StateMachine/DoubleJump.x_modifier = "1.5"
		if spark_speed_frames % 7 == 0:
			play_sound("SparkSpeed")
		spark_speed_particle.start_emitting()
		if hitlag_ticks <= 0:
			spark_speed_frames -= 1
		if spark_speed_frames <= 0:
			$StateMachine/DashForward.dash_speed = default_dash_speed
			chara.set_max_ground_speed(max_air_speed)
			chara.set_max_air_speed(max_ground_speed)
			$StateMachine/Jump.x_modifier = "1.0"
			$StateMachine/DoubleJump.x_modifier = "1.0"
			stop_sound("SparkSpeed")
	else:
		spark_speed_particle.stop_emitting()
		
	.tick()
	if hitlag_ticks <= 0:
		if is_grounded():
#			hovering = false
			if fast_falling:
				fast_fall_landing = true
			fast_falling = false
		else:
			fast_fall_landing = false
		if hovering:
			fast_falling = false
			if current_state().busy_interrupt_type != CharacterState.BusyInterrupt.Hurt:
				var vel = get_vel()
				var modifier = HOVER_VEL_Y_POS_MODIFIER
				if fixed.lt(vel.y, "0"):
					modifier = HOVER_VEL_Y_NEG_MODIFIER
				set_vel(vel.x, fixed.mul(vel.y, modifier))
				if hover_left > 0:
					if !infinite_resources:
						hover_left -= hover_drain_amount
						if hover_left <= 0:
							hovering = false
							hover_left = 0
		if fast_falling:
			hovering = false
			if !infinite_resources:
				hover_left -= fast_fall_drain_amount
				if hover_left <= 0:
					fast_falling = false
					hover_left = 0
			apply_grav_fast_fall()
#		if current_state().busy_interrupt_type != CharacterState.BusyInterrupt.Hurt and !hovering:
		hover_left += (hover_gain_amount if hover_left >= HOVER_MIN_AMOUNT else hover_gain_amount_depleted ) if is_grounded() else hover_gain_amount_air
		if hover_left > HOVER_AMOUNT:
			hover_left = HOVER_AMOUNT

	if orb_projectile:
		use_super_meter(ORB_SUPER_DRAIN + orb_accumulator)
		if super_meter == 0 and supers_available == 0:
			objs_map[orb_projectile].disable()
		orb_duration += 1
		if orb_duration > 0 and orb_duration % ORB_DRAIN_INCREASE_FREQUENCY == 0:
			orb_accumulator += 1
	else:
		orb_duration = 0
		orb_accumulator = 0

	if current_orb_push != null:
		if orb_projectile:
			if !(current_orb_push.x == 0 and current_orb_push.y == 0):
				var force = fixed.normalized_vec_times(str(current_orb_push.x), str(current_orb_push.y), ORB_PUSH_SPEED)
				objs_map[orb_projectile].push(force.x, force.y)
		current_orb_push = null

	if detonating_bombs:
		for obj_name in nearby_spark_bombs:
			var bomb = obj_from_name(obj_name)
			if bomb:
				bomb.explode(true)
				take_damage(SPARK_BOMB_SELF_DAMAGE)

	if flame_wave_cooldown > 0:
		flame_wave_cooldown -= 1

	if nearby_spark_bombs:
		nearby_spark_bombs = []
	if spark_bombs:
		var disabled_bombs = []
		for obj_name in spark_bombs:
			var bomb = obj_from_name(obj_name)
			if bomb:
				var dir = obj_local_center(bomb)
				if !bomb.exploded and bomb.armed and fixed.lt(fixed.vec_len(str(dir.x), str(dir.y)), SPARK_BOMB_PUSH_DISTANCE):
					nearby_spark_bombs.append(obj_name)
			else:
				disabled_bombs.append(obj_name)
				continue
		for disabled_obj_name in disabled_bombs:
			spark_bombs.erase(disabled_obj_name)

	if tether_ticks > 0:
		if orb_projectile and !is_grounded():
			var orb = objs_map[orb_projectile]
			if !orb.disabled:
				var dir = obj_local_center(orb)
				var falloff_power = fixed.round(fixed.div(str(TETHER_TICKS - tether_ticks), "3"))
				var force = fixed.normalized_vec_times(str(dir.x), str(dir.y), fixed.mul(TETHER_SPEED, fixed.powu(TETHER_FALLOFF, falloff_power)))
				apply_force(force.x, force.y)

		tether_ticks -= 1
		if is_grounded() or is_in_hurt_state():
			tether_ticks = 0

	if combo_count <= 0 and !opponent.current_state().endless:
		gusts_in_combo = 0

	if hover_left <= 0:
		hover_left = 0

#	if geyser_particles:
#		var my_pos = get_pos() 
#		for particle in geyser_particles:
#			if is_instance_valid(particle):
#				particle.position = geyser_particles[particle]
#			else:
#				geyser_particles.erase(particle)

func start_moisture_effect():
	$"%DrawMoistureParticle".start_emitting()

func stop_moisture_effect():
	$"%DrawMoistureParticle".stop_emitting()

func process_extra(extra):
	.process_extra(extra)
#	if current_state() is CharacterHurtState:
#		return
	if can_hover():
		if extra.has("hover"):
			if is_ghost and ghost_started_hovering:
				hovering = true
			else:
				if !hovering and extra["hover"]:
					play_sound("FastFall")
				hovering = extra["hover"]
				if hovering and is_ghost:
					ghost_started_hovering = true
	else:
		hovering = false
	if can_fast_fall():
		if extra.has("fast_fall"):
			if extra["fast_fall"]:
				if extra["fast_fall"] and !fast_falling:
					play_sound("FastFall")
					set_vel(get_vel().x, FAST_FALL_SPEED)
				fast_falling = extra["fast_fall"]
		else:
			fast_falling = false
	else:
		fast_falling = false
	if extra.has("orb_push") and orb_projectile:
		current_orb_push = extra.orb_push
	if extra.has("detonate"):
		detonating_bombs = extra.detonate
	if extra.has("lock_orb"):
		if orb_projectile:
			var orb = obj_from_name(orb_projectile)
			if orb:
				if !orb.locked and extra.lock_orb:
					orb.lock()
				elif orb.locked and !extra.lock_orb:
					orb.unlock()
#	if boulder_projectile != null and extra.has("launch_dir") and extra.has("launch"):
#		if extra.launch:
#			var obj: TelekinesisProjectile = obj_from_name(boulder_projectile)
#			if obj:
#				var dir = xy_to_dir(extra.launch_dir.x, extra.launch_dir.y)
#				obj.launch(dir)
#				play_sound("Telekinesis")

func can_fast_fall():
	return !is_grounded() and  can_hover()

func can_hover():
#	return !is_grounded() and hover_left > HOVER_MIN_AMOUNT
	return hover_left > HOVER_MIN_AMOUNT
