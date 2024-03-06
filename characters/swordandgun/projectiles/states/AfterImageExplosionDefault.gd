extends DefaultFireball


func _frame_0():
	var bullets = []
	for obj_name in host.objs_map:
		var obj = host.obj_from_name(obj_name)
		if obj and obj.disabled:
			return
		if obj is NewBullet:
			if obj.id == host.id:
				bullets.append(obj)
	bullets.sort_custom(self, "sort_bullets")
	
	if bullets:
		var obj = bullets[0]
		var pos = host.get_pos()
		obj.set_pos(pos.x, pos.y)
		obj.last_hit_by = host.get_fighter().obj_name
		obj.reset_line()
		obj.reset_speed()
		obj.current_state().bounce_full_control(true)
		obj.no_draw_ticks = 1

func sort_bullets(a, b):
	if a.current_state().bounces_left == b.current_state().bounces_left:
		return a.current_tick < b.current_tick
	return a.current_state().bounces_left > b.current_state().bounces_left
