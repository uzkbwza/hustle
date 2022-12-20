extends RobotState

const PUSH_BACK_AMOUNT = "6"

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	var force = fixed.normalized_vec("-1", "1")
	force = fixed.vec_mul(force.x, force.y, PUSH_BACK_AMOUNT)
	host.apply_force_relative(force.x, force.y)
