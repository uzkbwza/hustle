extends ThrowState

const ADDED_FORCE = "6.0"
const RELEASE_DIST_FROM_WALL = 100
const MAX_TICK = 240
const COMBO_DURATION = 20

func _enter():
	host.start_fly_fx()
	host.move_directly_relative("12", "0")

func _exit():
	host.stop_fly_fx()

func _tick():
	host.apply_force_relative(ADDED_FORCE, "0")
	host.apply_forces_no_limit()
	if current_tick > MAX_TICK or (host.combo_count > 0 and current_tick > COMBO_DURATION):
		return "CornerCarryRelease"
		

	if Utils.int_abs(host.get_pos().x - host.stage_width * host.get_facing_int()) < RELEASE_DIST_FROM_WALL:
#		var target_x = host.stage_width * host.get_facing_int() - RELEASE_DIST_FROM_WALL * host.get_facing_int()
#		var new_x = fixed.round(fixed.lerp_string(str(host.get_pos().x), str(target_x), "0.0"))
#		host.set_pos(new_x, host.get_pos().y)
		return "CornerCarryRelease"
		
#	if current_tick % 15 == 0:
#		host.play_sound("CornerCarryFlySound")
	if current_tick % 5 == 0:
		host.play_sound("CornerCarryFlyClick")
		spawn_particle_relative(particle_scene, particle_position * Vector2(host.get_facing_int(), 1))
	if host.penalty > 0:
		host.penalty = 0
