extends ThrowState

const ADDED_FORCE = "2.0"
const RELEASE_DIST_FROM_WALL = 64
const MAX_TICK = 240
const COMBO_DURATION = 20

func _enter():
	host.start_fly_fx()

func _exit():
	host.stop_fly_fx()

func _tick():
	host.apply_force_relative(ADDED_FORCE, "0")
	host.apply_forces_no_limit()
	if current_tick > MAX_TICK or (host.combo_count > 0 and current_tick > COMBO_DURATION):
		return "CornerCarryRelease"

	if Utils.int_abs(host.get_pos().x - host.stage_width * host.get_facing_int()) < RELEASE_DIST_FROM_WALL:
		host.set_pos(host.stage_width * host.get_facing_int() - RELEASE_DIST_FROM_WALL * host.get_facing_int(), host.get_pos().y)
		return "CornerCarryRelease"

#	if current_tick % 15 == 0:
#		host.play_sound("CornerCarryFlySound")
	if current_tick % 5 == 0:
		host.play_sound("CornerCarryFlyClick")
		spawn_particle_relative(particle_scene, particle_position * Vector2(host.get_facing_int(), 1))
	if host.penalty > 0:
		host.penalty = 0
#	host.create_speed_after_image_from_style()
