extends RobotState

const ADDED_FORCE = "1.5"
const RELEASE_DIST_FROM_WALL = 64
const MAX_TICK = 15
const COMBO_DURATION = 20

func _enter():
	host.start_fly_fx()
	can_fly = false

func _frame_4():
	can_fly = false
	host.has_projectile_armor = true

func _frame_15():
	host.has_projectile_armor = false

func _frame_16():
	host.stop_fly_fx()

func _exit():
	host.stop_fly_fx()

func _tick():
	host.apply_forces_no_limit()
	if current_tick < MAX_TICK:
		host.apply_force_relative(ADDED_FORCE, "0")

		if current_tick % 5 == 0:
			host.play_sound("CornerCarryFlyClick")
			spawn_particle_relative(particle_scene, particle_position * Vector2(host.get_facing_int(), 1))
