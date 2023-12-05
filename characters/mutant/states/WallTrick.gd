extends BeastState

const MOVE_X = "-1"
const MOVE_Y = "-0.5"
const MOVE_SPEED = "30"

const AIR_ADVANTAGE = 4

var air_advantage = 0

func _enter():
	host.reset_momentum()
	air_advantage = AIR_ADVANTAGE if host.touching_which_wall() != 0 and host.get_facing_int() !=  host.touching_which_wall() else 0
func _tick():

	if current_tick == 5 - air_advantage:
		spawn_particle_relative(particle_scene, Vector2(16 * host.get_facing_int(), 0), Vector2(host.get_facing_int() * float(MOVE_X), float(MOVE_Y)))
	if current_tick > 4 - air_advantage:
		var move = fixed.normalized_vec_times(MOVE_X, MOVE_Y, MOVE_SPEED)
		host.set_vel(fixed.mul(move.x, str(host.get_facing_int())), move.y)
		if current_tick > 5 - air_advantage:
			if host.touching_which_wall() != 0 and !host.is_grounded() or current_tick >= anim_length - 1:
				return "WallTrickFollowup"

func _exit():
	host.reset_momentum()
