extends ObjectState

const PUSH_DISTANCE = "60"
const PUSH_SPEED = "10"
const SUPER_METER_GAIN = 35

var landed = true

func _frame_1():
	var dir = host.obj_local_center(host.creator)
	if fixed.lt(fixed.vec_len(str(dir.x), str(dir.y)), PUSH_DISTANCE):
		var force = fixed.normalized_vec_times(str(dir.x), str(dir.y), PUSH_SPEED)
#		host.creator.apply_force(force.x, force.y if !host.creator.is_grounded() else "0")
		host.creator.apply_force(force.x, force.y)
#		host.creator.gain_super_meter(SUPER_METER_GAIN)
		host.creator.unlock_achievement("ACH_SPARK_JUMP")

func _frame_2():
	var fighter = host.get_fighter()
	if fighter:
		if landed or host.obj_name in fighter.nearby_bombs:
			fighter.spark_speed_frames += fighter.SPARK_SPEED_FRAMES

func _frame_16():
	host.disable()

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	landed = true
