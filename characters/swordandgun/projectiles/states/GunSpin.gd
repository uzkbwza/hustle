extends ObjectState

var hit_someone = false
var hit_frame = 0

const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")

const SHOOT_FRAMES_AFTER_HITTING = 20
const PICKUP_TICKS_AFTER_SHOOT = 1
const PICKUP_TICKS_AFTER_THROW = 15

onready var hitbox = $Hitbox

func _ready():
	pass # Replace with function body.

func _enter():
	host.can_be_picked_up = false
	host.set_grounded(false)

func _tick():
	if !host.is_grounded():
		host.sprite.rotation += deg2rad(45)
	if host.shot:
		host.can_be_picked_up = true
	if hit_someone:
		if current_tick == hit_frame + SHOOT_FRAMES_AFTER_HITTING:
			if host.creator.bullets_left > 0:
				host.creator.use_bullet()
				host.shoot(host.creator.opponent)
		if current_tick == hit_frame + SHOOT_FRAMES_AFTER_HITTING + PICKUP_TICKS_AFTER_SHOOT and host.shot:
			host.can_be_picked_up = true
	
	if host.is_grounded():
		host.can_be_picked_up = true
		anim_name = "Idle"
		host.sprite.rotation = 0
		hitbox.deactivate()
#	host.modulate = Color.red if host.can_be_picked_up else Color.white

func _exit():
	host.sprite.rotation = 0
	host.can_be_picked_up = true

func _on_hit_something(obj, _hitbox):
	if obj.is_in_group("Fighter"):
		host.set_facing(host.get_facing_int() * -1)
		host.reset_momentum()
		host.apply_force(0, -8)
		hit_someone = true
	host.can_be_picked_up = false
