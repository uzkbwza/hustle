extends CharacterState

const PULL_SPEED = "15"

func is_usable():
	return .is_usable() and !host.has_gun

func _frame_2():
	var obj = host.obj_from_name(host.gun_projectile)
	if obj:
		obj.reset_momentum()
		var dir = obj.get_object_dir_vec(host)
		var force = fixed.vec_mul(dir.x, dir.y, PULL_SPEED)
		obj.apply_force(force.x, force.y)
		obj.reset_hitbox()
