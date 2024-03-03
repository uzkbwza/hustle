extends CharacterState

const MAX_EXTRA_LAG_FRAMES = 5
const MIN_IASA = 7
const IASA_BACK = 11
const MIN_NEUTRAL_IASA = 9
const BACK_STARTUP_LAG = 4

export var FORWARD_FORCE_X = "1.4"
export var FORWARD_FORCE_Y = "0.5"
export var FORWARD_FORCE_SPEED = "9.0"

export var DOWNWARD_FORCE_X = "0.0"
export var DOWNWARD_FORCE_Y = "1.0"
export var DOWNWARD_FORCE_SPEED = "15.0"

export var startup_invuln = true
export var grounded = false
export var back = false
export var cuts = false

var starting_y = 0

func _enter():
	if data == null:
		data = { "x": -host.get_facing_int() if back else host.get_facing_int(), "y": 0 }
	var go_back = !back and (data.x == -host.get_facing_int())
	if go_back and !back:
#		host.air_movements_left += 1
		return "AirDash2Back" if !cuts else "AirDash1kBack"
	if back:
		beats_backdash = false
		backdash_iasa = true

	else:
		beats_backdash = true
		backdash_iasa = false

func _frame_0():
	var min_iasa = MIN_IASA if host.combo_count > 0 else MIN_NEUTRAL_IASA
	starting_iasa_at = min_iasa
	iasa_at = min_iasa
	var down = data.x == 0
	if host.combo_count <= 0 and (back or down):
		iasa_at = IASA_BACK
	starting_y = host.get_pos().y
	host.move_directly(0, -1)
	host.set_grounded(false)
	if startup_invuln and host.initiative:
		host.start_projectile_invulnerability()
	var force_x = DOWNWARD_FORCE_X if down else fixed.mul(FORWARD_FORCE_X, str(data.x * host.get_facing_int()))
	var force_y = DOWNWARD_FORCE_Y if down else FORWARD_FORCE_Y  
	var force_speed = DOWNWARD_FORCE_SPEED if down else FORWARD_FORCE_SPEED
	var force = fixed.normalized_vec_times(force_x, force_y, force_speed)
#	if down:
	if back:
		host.hitlag_ticks += BACK_STARTUP_LAG

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
