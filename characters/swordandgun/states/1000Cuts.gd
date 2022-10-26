extends SuperMove

const PROJECTILE_SCENE = preload("res://characters/swordandgun/projectiles/1000cuts/1000Cuts.tscn")

func _frame_2():
	var obj = host.spawn_object(PROJECTILE_SCENE, 0, 0)
	host.cut_projectile = obj.obj_name

func is_usable():
	return .is_usable() and host.cut_projectile == null
