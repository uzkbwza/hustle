extends ObjectState

#func _enter():
#	var pos = host.creator.opponent.get_hurtbox_center()
#	host.set_pos(pos.x, pos.y)

func _frame_1():
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2(), 10, 10/60.0)

func _tick():
	if current_tick == 15:
		host.disable()
