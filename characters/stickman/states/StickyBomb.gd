extends CharacterState

const THROW_SPEED = "15"
const THROW_DIR_X = "0.0"
const THROW_DIR_Y = "1.15"
const GRAV = "0.35"
const FALL_SPEED = "5"


func _frame_0():
	host.colliding_with_opponent = false
	var vel = host.get_vel()
#	host.set_vel(vel.x, "0")
	pass

func apply_enter_force():
	if data:
		.apply_enter_force()

func _tick():
	if current_tick == 15:
		var obj = host.spawn_object(preload("res://characters/stickman/projectiles/StickyBomb.tscn"), 20, 0)
		host.bomb_thrown = true
		host.bomb_projectile = obj.obj_name
		var force = fixed.normalized_vec_times(fixed.mul(THROW_DIR_X, str(host.get_facing_int())), THROW_DIR_Y, THROW_SPEED)
		obj.apply_force(force.x, force.y)
	if current_tick > 10 and host.is_grounded():
		return "Landing"
	if data:
		host.apply_grav_custom(GRAV, FALL_SPEED)
	else:
		host.apply_grav()

func is_usable():
	return .is_usable() and !host.bomb_thrown and host.sticky_bombs_left > 0

