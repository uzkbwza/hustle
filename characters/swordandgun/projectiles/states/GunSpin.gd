extends ObjectState

var hit_someone = false
var landed = false
var pull = false
var hit_frame = 0

const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")

const SHOOT_FRAMES_AFTER_HITTING = 18
const PICKUP_TICKS_AFTER_SHOOT = 1
const PICKUP_TICKS_AFTER_THROW = 15
const BOOMERANG_SPEED = "0.75"
const DIRECT_MOVE_DIST = "64"
const DIRECT_MOVE_PER_FRAME = "3.0"

onready var hitbox = $Hitbox

func _ready():
	pass # Replace with function body.

func _enter():
	host.can_be_picked_up = false
	host.set_grounded(false)
	apply_grav = true
	hit_someone = false

func _tick():
	if !host.is_grounded():
		host.sprite.rotation += deg2rad(45)
	if host.shot:
		host.can_be_picked_up = true
	if hit_someone and !host.shot and !host.reeled:
		if current_tick == hit_frame + SHOOT_FRAMES_AFTER_HITTING:
			if host.creator.bullets_left > 0:
				host.creator.use_bullet()
				host.shoot(host.creator.opponent)
		if current_tick == hit_frame + SHOOT_FRAMES_AFTER_HITTING + PICKUP_TICKS_AFTER_SHOOT and host.shot:
			host.can_be_picked_up = true
	
	if host.is_grounded():
		host.can_be_picked_up = true
		if !host.lassoed:
			anim_name = "Idle"
			hitbox.deactivate()
			host.sprite.rotation = 0
		pull = true

	var vel = host.get_vel()
	hitbox.dir_x = fixed.mul(str(fixed.sign(vel.x)), "-1")

	if host.shot:
		pull = true

	if pull and host.creator and host.lassoed:
		var dir = host.obj_local_center(host.creator)
		var force = fixed.normalized_vec_times(str(dir.x), str(dir.y), BOOMERANG_SPEED)
		if fixed.gt(fixed.vec_len(str(dir.x), str(dir.y)), DIRECT_MOVE_DIST):
			var movement = fixed.normalized_vec_times(str(dir.x), str(dir.y), DIRECT_MOVE_PER_FRAME)
			host.move_directly(movement.x, movement.y)
		host.apply_force(force.x, force.y)
		apply_grav = false

func _exit():
	host.sprite.rotation = 0
	host.can_be_picked_up = true
#	hitbox.start_tick = 2

func pop_up():
	host.set_facing(host.get_facing_int() * -1)
	host.reset_momentum()
	host.apply_force(0, -8)
	hit_someone = true
	host.can_be_picked_up = false

func _on_hit_something(obj, _hitbox):
	if obj.is_in_group("Fighter"):
		if !host.reeled:
			hit_frame = current_tick
			pop_up()
	._on_hit_something(obj, _hitbox)
