extends BeastState

const GO_FRAME = 16
const MOVE_X_1 = "2"
const MOVE_Y_1 = "0.5"
const MOVE_X_2 = "1.5"
const MOVE_Y_2 = "1"
const MOVE_SPEED = "37"

export var downward = false

var move_x
var move_y

func _enter():
	var move = fixed.normalized_vec_times(MOVE_X_2 if downward else MOVE_X_1, MOVE_Y_2 if downward else MOVE_Y_1, MOVE_SPEED)
	move_x = fixed.mul(move.x, str(host.get_facing_int()))
	move_y = move.y


func _frame_0():
	var wall = host.touching_which_wall()
	if wall != 0:
		host.set_facing(-wall)
		if host.reverse_state:
			host.set_facing(wall)

func _tick():
	if current_tick > 3:
		host.set_vel(move_x, move_y)
		if host.is_grounded() or host.get_pos().y > -2:
			host.set_pos(host.get_pos().x, 0)
			return "Landing"

#func _on_hit_something(obj, hitbox):
#	._on_hit_something(obj, hitbox)
#	var move = fixed.normalized_vec_times(MOVE_X, MOVE_Y, MOVE_SPEED)
#	host.set_vel(move.x, move.y)
	

func _exit():
	host.set_vel(move_x, move_y)
	if host.is_grounded():
		var vel = host.get_vel()
		host.set_vel(fixed.mul(vel.x, "0.33"), vel.y)
