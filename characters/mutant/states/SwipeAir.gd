extends BeastState

export var grounded = false

func _enter():
	land_cancel_state = "Landing"

func _tick():
	if (current_tick < (2 if !grounded else 5)) and host.combo_count <= 0:
		land_cancel_state = "Landing"
	else:
		land_cancel_state = "ShredLandCancel"

#const JUKE_MOMENTUM = "6"
#
#var juking = false
#
#func _enter():
#	juking = false
#	if host.juke_ticks > 0 or host.up_juke_ticks > 0:
#		juking = true
#

func _frame_4():
	if grounded:
		host.start_projectile_invulnerability()

#func apply_timed_force():
#	if !juking:
#		.apply_timed_force()
#	else:
#		if force_speed != "0.0":
#			var force = xy_to_dir(force_dir_x, force_dir_y, force_speed, "1.0")
#	#		force.y = host.fixed.mul(force.y, "2.0")
#			host.apply_force_relative("0", force.y)
#
#func _tick():
#	if juking and host.juke_ticks == 0 and host.up_juke_ticks == 0:
#
#		var move = fixed.normalized_vec_times(host.juke_dir_x, fixed.mul(host.juke_dir_y, "0.35"), JUKE_MOMENTUM)
#		host.move_directly(move.x, move.y)
