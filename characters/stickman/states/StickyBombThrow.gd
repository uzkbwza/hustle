extends ThrowState

func _enter():
	host.z_index = 2

func _frame_30():
	var obj = host.spawn_object(preload("res://characters/stickman/projectiles/StickyBomb.tscn"), 0, -16)
	host.bomb_thrown = true
	host.bomb_projectile = obj.obj_name
	obj.attached = true


func _tick():
	if current_tick > 29:
		interruptible_on_opponent_turn = true
		host.apply_grav()
		host.apply_fric()
		host.apply_forces()
	else:
		interruptible_on_opponent_turn = false
