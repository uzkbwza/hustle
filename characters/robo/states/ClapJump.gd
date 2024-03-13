extends RobotState

const GRAV = "0.58"
const STARTED_IN_AIR_GRAV = "0.80"
const MAX_FALL_SPEED = "3.0"
const STARTED_IN_AIR_MAX_FALL_SPEED = "8.0"
const EXTRA_VICTIM_HITLAG = 15
const AUTO_LAG = 4
const BASE_HITLAG = 12

onready var hitbox = $Hitbox

var jumping = false
var grav = GRAV
var max_fall_speed = MAX_FALL_SPEED
var auto_lag = AUTO_LAG

func _enter():
	pass

func _frame_0():
	auto_lag = AUTO_LAG
	grav = GRAV if host.is_grounded() else STARTED_IN_AIR_GRAV
	max_fall_speed = MAX_FALL_SPEED if host.is_grounded() else STARTED_IN_AIR_MAX_FALL_SPEED
	host.set_grounded(false)
	jumping = true
	if !(state_name in host.combo_moves_used):
		hitbox.victim_hitlag = hitbox.hitlag_ticks + EXTRA_VICTIM_HITLAG
		hitbox.ground_bounce = false
		hitbox.grounded_hit_state = "HurtAerial"
	else:
		hitbox.victim_hitlag = hitbox.hitlag_ticks
		hitbox.ground_bounce = true
		hitbox.grounded_hit_state = "HurtAerial"
	hitbox.combo_victim_hitlag = hitbox.victim_hitlag
	if data.Auto:
		hitbox.combo_scaling_amount = 2
	else:
		hitbox.combo_scaling_amount = 1

func _frame_1():
	host.move_directly_relative(-10, 0)

	
func _frame_2():
	host.move_directly_relative(1, -3)
	host.start_throw_invulnerability()
	
func _frame_3():
	var force = fixed.normalized_vec_times("1.0", "-0.25", "8.0")
	if data.Direction.x * host.get_facing_int() == -1:
		force.x = fixed.mul(force.x, "-0.55")
	host.apply_force_relative(force.x, force.y)

func _frame_7():
	host.end_throw_invulnerability()

func _tick():
#	host.apply_force(0, 1)
	
	host.apply_grav_custom(grav, max_fall_speed)
	if jumping and current_tick >= 10 and auto_lag > 0:
		current_tick = 9
		if data.Auto:
			auto_lag -= 1


	if jumping and current_tick > 1 and (host.is_grounded()):
		jumping = false
		host.big_landing_effect()
