extends RobotState

const MISSILES = 3
var missiles_left = MISSILES

func _enter():
	missiles_left = MISSILES

func process_projectile(obj):
	.process_projectile(obj)
#	var vel = host.get_vel()
#	obj.set_vel(fixed.mul(vel.x, "1.0"), "0")
	host.drain_air_option_bar((host.air_option_bar_max / 12))
	spawn_particle_relative(timed_particle_scene, timed_particle_position)
	obj.z_index = host.z_index + 1
	missiles_left -= 1
	if missiles_left > 0:
		current_tick = 1

func is_usable():
	return (host.air_option_bar >= (host.air_option_bar_max / 4)) and .is_usable()
