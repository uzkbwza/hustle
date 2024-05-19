extends "res://characters/states/Landing.gd"

onready var hitbox = $Hitbox
const LANDING_SHOCKWAVE = preload("res://characters/robo/projectiles/LandingShockwave.tscn")
const SPEED_HITBOX_ACTIVATION = "5.0"
const SPEED_HITBOX_RATIO = "1.0"
const BASE_DAMAGE = 10
const BASE_HITSTUN = 30
const MIN_HITSTUN = 10
const LESS_HITSTUN_PER_PIXEL = "0.1"
const LESS_DAMAGE_PER_PIXEL = "0.25"
const DAMAGE_MODIFIER = "0.3"
const GROUND_POUND_LAG = 8

var has_hitbox = false

func _frame_0():
	set_lag(null)
	var prev = _previous_state()
	var speed = host.last_aerial_vel.y
	has_hitbox = prev.busy_interrupt_type != BusyInterrupt.Hurt and !(prev and prev.get("IS_HURT_STATE"))
	hitbox.hits_vs_grounded = host.can_ground_pound and fixed.gt(speed, SPEED_HITBOX_ACTIVATION) and has_hitbox

#	set_lag(null if !hitbox.hits_vs_grounded else GROUND_POUND_LAG)

#	hitbox.x = host.obj_local_pos(host.opponent).x * host.get_facing_int()
#	hitbox.start_tick = -1 if !has_hitbox else 1
	var ratio = fixed.div(speed, SPEED_HITBOX_RATIO)
	var damage = fixed.round(fixed.mul(ratio, str(BASE_DAMAGE)))
#	var dist = Utils.int_abs(host.obj_local_pos(host.opponent).x)

#	damage = fixed.round(fixed.sub(str(damage), fixed.mul(str(dist), LESS_DAMAGE_PER_PIXEL)))
	if damage < BASE_DAMAGE:
		damage = BASE_DAMAGE

	damage = fixed.round(fixed.mul(DAMAGE_MODIFIER, str(damage)))
		
	if hitbox.hits_vs_grounded:
		var left = host.spawn_object(LANDING_SHOCKWAVE, -16, -1)
		var right = host.spawn_object(LANDING_SHOCKWAVE, 16, -1)

		right.facing = 1
		left.facing = -1
		left.damage = damage
		right.damage = damage
		left.speed = speed
		right.speed = speed

	hitbox.damage = damage

#	var hitstun = BASE_HITSTUN - fixed.round(fixed.mul(str(dist), LESS_HITSTUN_PER_PIXEL))
#	if hitstun < MIN_HITSTUN:
#		hitstun = MIN_HITSTUN

#	hitbox.hitstun_ticks = hitstun
#	hitbox.combo_hitstun_ticks = hitstun - 5

#	if hitbox.hits_vs_grounded:
#		var nade = host.obj_from_name(host.grenade_object)
#		if nade and nade.is_grounded():
#			nade.set_vel(nade.get_vel().x, "0")
#			nade.apply_force(0, -3)
#
#		if host.opponent.get("grenade_object") != null:
#			var nade2 = host.opponent.obj_from_name(host.grenade_object)
#			if nade2 and nade2.is_grounded():
#				nade2.set_vel(nade2.get_vel().x, "0")
#				nade2.apply_force(0, -3)

#	hitbox.hitstun_ticks = hitstun
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, fixed.round(fixed.mul(ratio, "2")), max(fixed.round(fixed.mul(ratio, "1")) / 60.0, 20 / 60.0))

func _tick():
	._tick()
	if has_hitbox:
		interruptible_on_opponent_turn = false
