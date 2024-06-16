extends BaseProjectile

const ACCEL_SPEED = "0.30"
const FRIC = "0.04"
const DIRECT_MOVE_SPEED = "3.0"
const PUSH_SPEED_LIMIT = "8"
const LIGHTNING_Y = 132
const LIGHTNING_PUSH_FORCE = "-5"
const ATTACK_SUPER_DRAIN = 0
const LIGHTNING_DRAIN = 0
const HIT_FORCE_MODIFIER = "2.0"
const PUSH_BACK_FORCE = "10"
const PUSH_BLOCK_LOCK_COOLDOWN = 20

const ORB_DART_SCENE = preload("res://characters/wizard/projectiles/OrbDart.tscn")
const LOCKED_DART_SCENE = preload("res://characters/wizard/projectiles/OrbDartLocked.tscn")
const LIGHTNING_SCENE = preload("res://characters/wizard/projectiles/orb/OrbLightning.tscn")
const LOCK_PARTICLE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")
const DISABLE_PARTICLE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")
const PUSH_PARTICLE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")
const PUSH_TICKS = 30

var triggered_attacks = {}

var frozen = false
var locked = false

var lock_cooldown = 0

var push_ticks = 0

var strikes_left = 0
var strike_ticks_left = 0

var push_dir = null

func _ready():
	pass

func get_target_pos():
	var local_pos = obj_local_center(creator)
	return {
		"x": local_pos.x - creator.get_facing_int() * 30,
		"y": local_pos.y - 12
	}

func lock():
	reset_momentum()
	locked = true
	push_ticks = 0
	spawn_particle_effect_relative(LOCK_PARTICLE)
	play_sound("Lock")

func unlock():
	locked = false
	spawn_particle_effect_relative(LOCK_PARTICLE)
	play_sound("Unlock")

func get_travel_dir():
	if creator:
		var local_pos = get_target_pos()
		return fixed.normalized_vec(str(local_pos.x), str(local_pos.y))

func on_got_push_blocked():
	unlock()
	reset_momentum()
	lock_cooldown = PUSH_BLOCK_LOCK_COOLDOWN
	var dir_sign = get_fighter().opponent.get_opponent_dir()
	apply_force(fixed.mul(str(dir_sign), PUSH_BACK_FORCE), "0")

func travel_towards_creator():
	var travel_dir = get_travel_dir()
	if travel_dir:
		var force = fixed.vec_mul(travel_dir.x, travel_dir.y, ACCEL_SPEED)
		if get_pos().y == 0:
			var vel = get_vel()
			set_vel(vel.x, fixed.mul(vel.y, "-1"))
			if push_dir:
				push_dir.y = "0"
		apply_x_fric(FRIC)
		apply_y_fric(FRIC)
		apply_force(force.x, force.y)
		if push_ticks > 0:
			if push_dir != null:
				apply_force(fixed.div(push_dir.x, "10"), fixed.div(push_dir.y, "10"))
			limit_speed(PUSH_SPEED_LIMIT)
			apply_forces_no_limit()
		else:
			apply_forces()
		if get_pos().y > -5:
			apply_force("0", "-" + ACCEL_SPEED)
		var direct_movement = fixed.vec_mul(travel_dir.x, travel_dir.y, DIRECT_MOVE_SPEED)
		var local_pos = get_target_pos()
		if fixed.lt(fixed.vec_len(str(local_pos.x), str(local_pos.y)), "1.5"):
			move_directly(local_pos.x, local_pos.y)
		set_facing(get_object_dir(creator.opponent))
#		print(current_tick, get_vel())

func attempt_triggered_attack():
	if triggered_attacks.has(current_tick):
		attack(triggered_attacks[current_tick])
		triggered_attacks.erase(current_tick)

func trigger_attack(attack_type, attack_delay):
	if attack_type == "Lightning":
		if strikes_left > 0 or strike_ticks_left > 0:
			return
		for attack in triggered_attacks.values():
			if attack == "Lightning":
				return
	if attack_type == "Sword":
		if current_state().state_name == "Sword":
			return
	triggered_attacks[current_tick + attack_delay] = attack_type

func drain_super():
	if creator:
		creator.use_super_meter(ATTACK_SUPER_DRAIN)

func attack(attack_type):
	match attack_type:
		"OrbDart":
			spawn_orb_dart()
			drain_super()
		"Sword":
			state_machine.queue_state("Sword")
			drain_super()
		"Lightning":
			strikes_left += 2
			spawn_lightning()

func tick():
	.tick()
	if strike_ticks_left > 0:
		strike_ticks_left -= 1
		if strike_ticks_left == 0:
			spawn_lightning()
	if lock_cooldown > 0:
		lock_cooldown -= 1

func push(fx, fy):
	if fixed.eq(fx,"0") and fixed.eq(fy,"0"):
		return
	play_sound("Push")
#	reset_momentum()
	push_ticks = PUSH_TICKS
	push_dir = {
		"x": fx,
		"y": fy,
	}
#	apply_force(fx, fy)
	spawn_particle_effect_relative(PUSH_PARTICLE)

func disable():
	.disable()
	creator.orb_projectile = null
	spawn_particle_effect_relative(DISABLE_PARTICLE)

func spawn_lightning():
	var pos = get_pos()
	var lightning_y = pos.y
	if pos.y > -LIGHTNING_Y:
		set_pos(pos.x, -LIGHTNING_Y)
		var vel = get_vel()
		set_vel(vel.x, LIGHTNING_PUSH_FORCE)
		lightning_y = -LIGHTNING_Y
		spawn_particle_effect_relative(PUSH_PARTICLE)
	spawn_object(LIGHTNING_SCENE, pos.x, lightning_y, false, null, false)
	play_sound("Lightning")
	if strikes_left > 0:
		strikes_left -= 1
		strike_ticks_left = 15
	if creator:
		creator.use_super_meter(LIGHTNING_DRAIN)

func spawn_orb_dart():
	var local_pos = obj_local_center(creator.opponent)
	var dir = fixed.normalized_vec(str(local_pos.x), str(local_pos.y))
	spawn_object(ORB_DART_SCENE if !locked else LOCKED_DART_SCENE, 0, 0, true, {"dir": dir})
	play_sound("Shoot")

func hit_by(hitbox):
	if hitbox:
		if hitbox.throw:
			return
		locked = false
		var force = get_knockback_force(hitbox)
		force = fixed.vec_mul(force.x, force.y, HIT_FORCE_MODIFIER)
		apply_force(force.x, force.y)
