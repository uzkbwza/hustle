extends "res://characters/states/Landing.gd"

onready var hitbox = $Hitbox

const SPEED_HITBOX_ACTIVATION = "5.0"
const SPEED_HITBOX_RATIO = "1.0"
const BASE_DAMAGE = "10"
const GROUND_POUND_LAG = 6

var has_hitbox = false

func _enter():
	var prev: CharacterState = _previous_state()
	if prev.busy_interrupt_type != BusyInterrupt.Hurt:
		var speed = host.last_aerial_vel.y
		hitbox.x = host.obj_local_pos(host.opponent).x
		hitbox.hits_vs_grounded = fixed.gt(speed, SPEED_HITBOX_ACTIVATION)
		has_hitbox = hitbox.hits_vs_grounded
		var ratio = fixed.div(speed, SPEED_HITBOX_RATIO)
		var damage = fixed.round(fixed.mul(ratio, BASE_DAMAGE))
		hitbox.damage = damage
		var camera = host.get_camera()
		if camera:
			camera.bump(Vector2.UP, fixed.round(fixed.mul(ratio, "2")), max(fixed.round(fixed.mul(ratio, "1")) / 60.0, 20 / 60.0))
			
func _frame_0():
	set_lag(null if !has_hitbox else GROUND_POUND_LAG)
