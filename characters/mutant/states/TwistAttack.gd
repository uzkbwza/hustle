extends BeastState

const MOVE_SPEED = "11"
const HITBOX_X = "34"
const HITBOX_Y = "-15"
const HURTBOX_X = "19"
const HURTBOX_Y = "-15"

var moving = false
var move_x = "0"
var move_y = "0"
var dir_x = "0"
var dir_y = "0"


onready var hitbox = $Hitbox
onready var hurtbox = $LimbHurtbox
onready var hitbox_2 = $Hitbox2

func _enter():
	moving = false
	var move = xy_to_dir(data.x, data.y, MOVE_SPEED)
	host.twist_attack_sprite.rotation = Vector2(float(move.x) * host.get_facing_int(), float(move.y)).angle()
	move_x = move.x
	move_y = move.y
	dir_x = fixed.div(move_x, MOVE_SPEED)
	dir_y = fixed.div(move_y, MOVE_SPEED)
	var pivot_x = 0
	var pivot_y = -15
	var angle = fixed.vec_to_angle(dir_x, dir_y)
	var hurtbox_vec = fixed.rotate_vec(HURTBOX_X, "0", angle)
	var hitbox_vec = fixed.rotate_vec(HITBOX_X, "0", angle)
	hurtbox.x = (fixed.round(hurtbox_vec.x) + pivot_x) * host.get_facing_int()
	hurtbox.y = fixed.round(hurtbox_vec.y) + pivot_y
	hitbox.x = (fixed.round(hitbox_vec.x) + pivot_x) * host.get_facing_int()
	hitbox.y = fixed.round(hitbox_vec.y) + pivot_y
	hitbox.dir_x = fixed.mul(dir_x, str(host.get_facing_int()))
	hitbox.dir_y = dir_y
	if fixed.gt(dir_y, "0"):
		hitbox.dir_y = "0"
	hitbox_2.dir_x = hitbox.dir_x
	hitbox_2.dir_y = hitbox.dir_y
	hitbox.vacuum = false
	hitbox_2.vacuum = false

func _frame_0():
	allow_framecheat = true
	next_state_on_hold_on_opponent_turn = false
	next_state_on_hold = false

func _frame_25():
	allow_framecheat = false
	next_state_on_hold_on_opponent_turn = true
	next_state_on_hold = true

func _frame_6():
	moving = true

func _frame_10():
	host.sprite.hide()
	host.twist_attack_sprite.show()
	host.twist_attack_sprite.frame = 0
	host.reset_momentum()
	
func _tick():
	if !moving:
		apply_custom_grav = true
		host.apply_fric()
		host.apply_forces()
	else:
		apply_custom_grav = false
		host.move_directly(move_x, move_y)
		if current_tick > 14:
			if host.is_grounded() and fixed.gt(move_y, "0"):
				return "Landing"
		host.apply_fric()
		host.apply_forces()

func _exit():
	if moving:
		host.set_vel(move_x, move_y)
	host.sprite.show()
	host.twist_attack_sprite.hide()
