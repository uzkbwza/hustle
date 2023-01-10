extends CharacterState

const MIN_AIRDASH_HEIGHT = 10
const BACKDASH_LAG_FRAMES = 4
const Y_MODIFIER = "0.60"

export var dir_x = "3.0"
export var dir_y = "-5.0"
export var speed = "2.0"
export var fric = "0.05"
var startup_lag_frames = 0

func _frame_1():
	spawn_particle_relative(preload("res://fx/DashParticle.tscn"), host.hurtbox_pos_relative_float(), Vector2(data.x, data.y))

func _frame_0():
	var force = xy_to_dir(data.x, data.y, speed)
	var back = false
	if "-" in force.x:
		if host.get_facing() == "Right" and data.x != 0:
			anim_name = "DashBackward"
			back = true
		else:
			anim_name = "DashForward"
	else:
		if host.get_facing() == "Left" and data.x != 0:
			anim_name = "DashBackward"
			back = true
		else:
			anim_name = "DashForward"
	if back and host.combo_count <= 0:
		interruptible_on_opponent_turn = false
		host.hitlag_ticks += BACKDASH_LAG_FRAMES
		host.add_penalty(8)
	else:
		interruptible_on_opponent_turn = true

	host.apply_force(force.x, fixed.mul(force.y, Y_MODIFIER) if "-" in force.y else force.y)

func _tick():
#	host.apply_grav()
	host.apply_x_fric(fric)
	host.apply_forces_no_limit()
	if host.is_grounded():
		return "Landing"
#
#func is_usable():
#	return .is_usable() and host.get_pos().y <= -MIN_AIRDASH_HEIGHT
