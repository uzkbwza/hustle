extends ObjectState

const PUSH_DISTANCE = "60"
const PUSH_SPEED = "10"


func _frame_1():
	var dir = host.obj_local_center(host.creator)
	if fixed.lt(fixed.vec_len(str(dir.x), str(dir.y)), PUSH_DISTANCE):
		var force = fixed.normalized_vec_times(str(dir.x), str(dir.y), PUSH_SPEED)
		host.creator.apply_force(force.x, force.y)

func _frame_16():
	host.disable()
