extends DefaultFireball


func _frame_0():
	for obj_name in host.objs_map:
		var obj = host.obj_from_name(obj_name)
		if obj is NewBullet:
			if obj.id == host.id:
				var pos = host.get_pos()
				obj.set_pos(pos.x, pos.y)
				obj.reset_line()
				obj.reset_speed()
				obj.current_state().bounce_full_control(true)
				obj.no_draw_ticks = 1
