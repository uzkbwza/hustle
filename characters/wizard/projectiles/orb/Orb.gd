extends BaseProjectile

const ACCEL_SPEED = "0.30"
const FRIC = "0.04"
const DIRECT_MOVE_SPEED = "3.0"

const ORB_DART_SCENE = preload("res://characters/wizard/projectiles/OrbDart.tscn")
const LOCK_PARTICLE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")
const DISABLE_PARTICLE = preload("res://characters/wizard/projectiles/orb/OrbSpawnParticle.tscn")

var triggered_attacks = {}

var locked = false

func _ready():
	pass

func get_target_pos():
	var local_pos = obj_local_center(creator)
	return {
		"x": local_pos.x - creator.get_facing_int() * 30,
		"y": local_pos.y - 12
	}

func lock():
	locked = true
	spawn_particle_effect_relative(LOCK_PARTICLE)
	

func unlock():
	locked = false
	spawn_particle_effect_relative(LOCK_PARTICLE)

func get_travel_dir():
	if creator:
		var local_pos = get_target_pos()
		return fixed.normalized_vec(str(local_pos.x), str(local_pos.y))

func travel_towards_creator():
	var travel_dir = get_travel_dir()
	if travel_dir:
		var force = fixed.vec_mul(travel_dir.x, travel_dir.y, ACCEL_SPEED)
		apply_force(force.x, force.y)
		apply_full_fric(FRIC)
		apply_y_fric(FRIC)
		apply_forces()
		if get_pos().y > -5:
			apply_force("0", "-" + ACCEL_SPEED)
		var direct_movement = fixed.vec_mul(travel_dir.x, travel_dir.y, DIRECT_MOVE_SPEED)
		var local_pos = get_target_pos()
		if fixed.lt(fixed.vec_len(str(local_pos.x), str(local_pos.y)), "1.5"):
			move_directly(local_pos.x, local_pos.y)
		set_facing(get_object_dir(creator.opponent))

func attempt_triggered_attack():
	if triggered_attacks.has(current_tick):
		attack(triggered_attacks[current_tick])
		triggered_attacks.erase(current_tick)

func trigger_attack(attack_type, attack_delay):
	triggered_attacks[current_tick + attack_delay] = attack_type

func attack(attack_type):
	match attack_type:
		"OrbDart":
			spawn_orb_dart()

func disable():
	.disable()
	creator.orb_projectile = null
	spawn_particle_effect_relative(DISABLE_PARTICLE)

func spawn_orb_dart():
	var local_pos = obj_local_center(creator.opponent)
	var dir = fixed.normalized_vec(str(local_pos.x), str(local_pos.y))
	spawn_object(ORB_DART_SCENE, 0, 0, true, {"dir": dir})
