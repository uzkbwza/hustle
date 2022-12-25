extends CharacterState

const GUN_SCENE = preload("res://characters/swordandgun/projectiles/Gun.tscn")
const THROW_SPEED = "13"

func is_usable():
	return .is_usable() and host.has_gun

func _frame_7():
	var pos = get_projectile_pos()
	var gun_obj = host.spawn_object(GUN_SCENE, pos.x, pos.y)
	host.gun_projectile = gun_obj.obj_name
	host.has_gun = false
	if host.is_grounded():
		host.apply_force_relative(7, 0)

func _frame_8():
	if host.objs_map.has(host.gun_projectile):
		var gun_obj = host.objs_map[host.gun_projectile]
		if gun_obj:
			var dir = fixed.normalized_vec_times("1", fixed.sub(str(data.y), "0.15"), THROW_SPEED)
			gun_obj.apply_force_relative(dir.x, dir.y)
