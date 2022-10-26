extends CharacterState

const MIN_AIRDASH_HEIGHT = 10
const Y_MODIFIER = "0.60"

export var dir_x = "3.0"
export var dir_y = "-5.0"
export var speed = "2.0"
export var fric = "0.05"

func _frame_1():
	spawn_particle_relative(preload("res://fx/DashParticle.tscn"), Vector2(0, -16), Vector2(data.x, data.y))

func _enter():
	var force = xy_to_dir(data.x, data.y, speed)
	if "-" in force.x:
		if host.get_facing() == "Right":
			anim_name = "DashBackward"
		else:
			anim_name = "DashForward"
	else:
		if host.get_facing() == "Left":
			anim_name = "DashBackward"
		else:
			anim_name = "DashForward"

	host.apply_force(force.x, fixed.mul(force.y, Y_MODIFIER) if "-" in force.y else force.y)

func _tick():
#	host.apply_grav()
	host.apply_full_fric(fric)
	host.apply_forces_no_limit()
	if host.is_grounded():
		return "Landing"
#
#func is_usable():
#	return .is_usable() and host.get_pos().y <= -MIN_AIRDASH_HEIGHT
