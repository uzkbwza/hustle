extends CharacterState

const GUN_SCENE = preload("res://characters/swordandgun/projectiles/Gun.tscn")

func is_usable():
	return .is_usable() and host.has_gun

func _frame_9():
	var pos = get_projectile_pos()
	var gun_obj = host.spawn_object(GUN_SCENE, pos.x, pos.y)
	host.gun_projectile = gun_obj.obj_name
	host.has_gun = false
	if host.is_grounded():
		host.apply_force_relative(7, 0)
