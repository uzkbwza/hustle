extends ObjectState

#const OFFSET_X = -10
#const OFFSET_Y = -35
#const LERP_VALUE = "0.18"
const Y_FORCE = "-12.0"

#var start_x = 0
#var start_y = 0

func _enter():
#	var pos = host.get_pos()
#	start_x = pos.x
#	start_y = pos.y
	host.apply_force("0", Y_FORCE)

func _tick():
#	if host.creator:
#		var pos = host.get_pos()
#		var target_pos = {
#			x = start_x + OFFSET_X * host.creator.get_facing_int(),
#			y = start_y + OFFSET_Y
#		}
#
#		var new_p_x = fixed.round(fixed.lerp_string(str(pos.x), str(target_pos.x), LERP_VALUE))
#		var new_p_y = fixed.round(fixed.lerp_string(str(pos.y), str(target_pos.y), LERP_VALUE))
#		host.set_pos(new_p_x, new_p_y)
	pass

func drop():
	queue_state_change("Drop")

func _frame_150():
	drop()
