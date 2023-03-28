extends ObjectState

const PUSH_DISTANCE = "60"
const PUSH_SPEED = "10"
const SELF_DAMAGE = 31
const SUPER_METER_GAIN = 35

func _frame_1():
	var dir = host.obj_local_center(host.creator)
	if fixed.lt(fixed.vec_len(str(dir.x), str(dir.y)), PUSH_DISTANCE):
		var force = fixed.normalized_vec_times(str(dir.x), str(dir.y), PUSH_SPEED)
#		host.creator.apply_force(force.x, force.y if !host.creator.is_grounded() else "0")
		host.creator.apply_force(force.x, force.y)
		host.creator.take_damage(SELF_DAMAGE)
		host.creator.gain_super_meter(SUPER_METER_GAIN)
		host.creator.unlock_achievement("ACH_SPARK_JUMP") 
		host.creator.spark_speed_frames += host.creator.SPARK_SPEED_FRAMES

func _frame_16():
	host.disable()
