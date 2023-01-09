extends "res://characters/states/Landing.gd"

onready var hitbox = $Hitbox

const SPEED_HITBOX_ACTIVATION = "5.0"
const SPEED_HITBOX_RATIO = "1.0"
const BASE_DAMAGE = 10
const BASE_HITSTUN = 30
const MIN_HITSTUN = 10
const LESS_HITSTUN_PER_PIXEL = "0.1"
const LESS_DAMAGE_PER_PIXEL = "0.25"
const GROUND_POUND_LAG = 8

var has_hitbox = false

func _frame_0():
	var prev: CharacterState = _previous_state()
	var speed = host.last_aerial_vel.y
	has_hitbox = prev.busy_interrupt_type != BusyInterrupt.Hurt and !(prev is CharacterHurtState)
	set_lag(null if !has_hitbox else GROUND_POUND_LAG)
	hitbox.hits_vs_grounded = host.can_ground_pound and fixed.gt(speed, SPEED_HITBOX_ACTIVATION) and has_hitbox
	hitbox.x = host.obj_local_pos(host.opponent).x * host.get_facing_int()
#	hitbox.start_tick = -1 if !has_hitbox else 1
	var ratio = fixed.div(speed, SPEED_HITBOX_RATIO)
	var damage = fixed.round(fixed.mul(ratio, str(BASE_DAMAGE)))
	var dist = Utils.int_abs(host.obj_local_pos(host.opponent).x)

	damage = fixed.round(fixed.sub(str(damage), fixed.mul(str(dist), LESS_DAMAGE_PER_PIXEL)))
	if damage < BASE_DAMAGE:
		damage = BASE_DAMAGE
	hitbox.damage = damage
	
	var hitstun = BASE_HITSTUN - fixed.round(fixed.mul(str(dist), LESS_HITSTUN_PER_PIXEL))
	if hitstun < MIN_HITSTUN:
		hitstun = MIN_HITSTUN
	
	hitbox.hitstun_ticks = hitstun
	hitbox.combo_hitstun_ticks = hitstun - 5
	
	
#	hitbox.hitstun_ticks = hitstun
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, fixed.round(fixed.mul(ratio, "2")), max(fixed.round(fixed.mul(ratio, "1")) / 60.0, 20 / 60.0))
