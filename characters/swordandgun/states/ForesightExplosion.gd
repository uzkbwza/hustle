extends CharacterState

const PROJECTILE = preload("res://characters/swordandgun/projectiles/AfterImageExplosion.tscn")

func is_usable():
	return .is_usable() and host.after_image_object != null

func _frame_3():
	if host.after_image_object:
		var obj = host.obj_from_name(host.after_image_object)
		var pos = obj.get_pos()
		var explosion = host.spawn_object(PROJECTILE, 0, 0)
		explosion.set_pos(pos.x, pos.y - 18)
		if obj:
			obj.disable()
