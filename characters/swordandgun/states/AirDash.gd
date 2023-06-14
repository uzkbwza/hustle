extends CharacterState

const MAX_EXTRA_LAG_FRAMES = 3

const FORWARD_FORCE_X = "1.4"
const FORWARD_FORCE_Y = "0.5"
const FORWARD_FORCE_SPEED = "9.0"

const DOWNWARD_FORCE_X = "0.0"
const DOWNWARD_FORCE_Y = "1.0"
const DOWNWARD_FORCE_SPEED = "15.0"

export var startup_invuln = true
export var grounded = false
var starting_y = 0

func _enter():
	if host.reverse_state:
		beats_backdash = false
		backdash_iasa = true
	else:
		beats_backdash = true
		backdash_iasa = false

func _frame_0():
	starting_y = host.get_pos().y
	host.move_directly(0, -1)
	host.set_grounded(false)
	if startup_invuln and host.initiative:
		host.start_projectile_invulnerability()
	var down = data.x == 0
	var force_x = DOWNWARD_FORCE_X if down else FORWARD_FORCE_X
	var force_y = DOWNWARD_FORCE_Y if down else FORWARD_FORCE_Y
	var force_speed = DOWNWARD_FORCE_SPEED if down else FORWARD_FORCE_SPEED
	var force = fixed.normalized_vec_times(force_x, force_y, force_speed)
#	if down:
	host.reset_momentum()
	host.apply_force_relative(force.x, force.y)


func _frame_4():
	host.end_projectile_invulnerability()

func _tick():
	if host.is_grounded():
		if host.combo_count > 0:
			queue_state_change("Landing", 4)
		else:
#			var lag = 7 if starting_y > -10 else 4
			var lag = 4 + Utils.int_max(MAX_EXTRA_LAG_FRAMES - current_tick, 0)
#			print(lag)
			queue_state_change("Landing", lag)
			var vel = host.get_vel()
