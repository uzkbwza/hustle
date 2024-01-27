extends SuperMove

const SUPERS_CONSUMED = 1
const MAX_DIST_H = 640
const MAX_DIST_V = 200

func _frame_1():
	host.start_invulnerability()
	if host.orb_projectile:
		host.objs_map[host.orb_projectile].frozen = true
		var orb = host.objs_map[host.orb_projectile]
		var pos = orb.get_pos()
		host.set_pos(pos.x, pos.y + 16)
		orb.disable()
	else:
		queue_state_change("Wait")
	for i in range(SUPERS_CONSUMED):
		host.use_super_bar()

func _frame_2():
	host.end_invulnerability()
	spawn_particle_relative(particle_scene, Vector2(0, -16))

func is_usable():
	if host.orb_projectile:
		var obj = host.obj_from_name(host.orb_projectile)
		if obj:
			var offs = host.obj_local_center(obj)
			if Utils.int_abs(offs.x) > MAX_DIST_H or offs.y < -MAX_DIST_V:
				return false
	return .is_usable() and host.orb_projectile
