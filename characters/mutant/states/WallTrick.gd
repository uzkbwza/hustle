extends BeastState

const MOVE_X_1 = "-3"
const MOVE_Y_1 = "-1"
const MOVE_X_2 = "-1"
const MOVE_Y_2 = "-1"
const MOVE_SPEED_1 = "25"
const MOVE_SPEED_2 = "19"
const MOVE_SPEED_3 = "19"

const JUMP_TICK = 4
const AIR_ADVANTAGE = JUMP_TICK - 1
const DOWN_TICK = 7

var air_advantage = 0
var down = false

func _enter():
	host.reset_momentum()
	air_advantage = AIR_ADVANTAGE if host.touching_which_wall() != 0 and host.get_facing_int() !=  host.touching_which_wall() else 0
	if data == null:
		data = {
			"x": 1,
			"y": 0,
		}
	fallback_state = "WallTrickFollowup" if data.y == 0 else "WallTrickFollowup2" if Utils.int_abs(data.x) == 1 else "WallTrickFollowup3"
	down = data.y == 1 and data.x == 0
#	if host.combo_count > 0:
#		host.feinting = true
#
#func can_feint():
#	return .can_feint() and host.combo_count == 0

func _tick():
	if current_tick == JUMP_TICK - air_advantage:
		spawn_particle_relative(particle_scene, Vector2(16 * host.get_facing_int(), 0), Vector2(host.get_facing_int() * float(MOVE_X_1 if data.y == 0 else MOVE_X_2), float(MOVE_Y_1 if data.y == 0 else MOVE_Y_2)))
	if current_tick > (JUMP_TICK - 1) - air_advantage:
		var move = fixed.normalized_vec_times(MOVE_X_1 if data.y == 0 else MOVE_X_2, MOVE_Y_1 if data.y == 0 else MOVE_Y_2, MOVE_SPEED_1 if data.y == 0 else MOVE_SPEED_2)
		host.set_vel(fixed.mul(move.x, str(host.get_facing_int())), move.y)
		if current_tick > JUMP_TICK - air_advantage:
			if host.touching_which_wall() != 0 and !host.is_grounded() or current_tick >= anim_length - 1 or (down and current_tick >= DOWN_TICK):
				return fallback_state
func _frame_0():
	host.start_throw_invulnerability()
	if host.is_neutral_juke():
		host.juke_ticks += 2
	
func _frame_1():
	host.start_projectile_invulnerability()

func _frame_8():
	host.end_projectile_invulnerability()
	host.end_throw_invulnerability()

func _exit():
	host.reset_momentum()
#
#func flip_allowed():
#	return host.combo_count > 0
