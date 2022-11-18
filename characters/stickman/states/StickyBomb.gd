extends CharacterState

const THROW_SPEED = "15"
const THROW_DIR_X = "1"
const THROW_DIR_Y = "-0.15"

func _tick():
	if current_tick == 9:
		var obj = host.spawn_object(preload("res://characters/stickman/projectiles/StickyBomb.tscn"), 20, -16)
		host.bomb_thrown = true
		host.bomb_projectile = obj.obj_name
		var force = fixed.normalized_vec_times(fixed.mul(THROW_DIR_X, str(host.get_facing_int())), THROW_DIR_Y, THROW_SPEED)
		obj.apply_force(force.x, force.y)
		
func is_usable():
	return .is_usable() and !host.bomb_thrown and host.sticky_bombs_left > 0
