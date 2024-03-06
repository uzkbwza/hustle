extends SuperMove

export var end = false

const PROJECTILE_SCENE = preload("res://characters/swordandgun/projectiles/1000cuts/1000Cuts.tscn")

func _frame_0():
	if end:
		var obj = host.obj_from_name(host.cut_projectile)
		if obj:
			obj.disable()
		host.prediction_effect()

func _frame_2():
	if end:
		return
	var obj = host.spawn_object(PROJECTILE_SCENE, 0, 0)
	host.cut_projectile = obj.obj_name
	host.start_1k_cuts_buff()


func is_usable():
	return .is_usable() and (host.cut_projectile == null) if !end else (host.cut_projectile != null)
