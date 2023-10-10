extends ObjectState

const GROUND_FIRE_DISTANCE = 64
var last_ground_fire = 0

func _frame_0():
	host.screen_bump(Vector2(), 20, 0.37)
	if host.creator:
		host.creator.orbital_strike_out = false
		host.creator.orbital_strike_projectile = null
		host.creator.loic_meter = 0
		host.creator.can_loic = false
		host.creator.loic_draining = false
#		print(Utils.int_abs(host.obj_local_center(host.creator).x) <= 20)
		if Utils.int_abs(host.obj_local_center(host.creator).x) <= 30:
			host.creator.add_armor_pip()
	last_ground_fire = host.get_pos().x
	host.line_drawer.z_index = 1000

func _frame_50():
	host.disable()

func _tick():
	if host.creator and host.creator.opponent:
		var target = host.creator if host.self_ else host.creator.opponent
		var dir = host.get_object_dir(target)
		var pos = host.obj_local_center(target)
		var t = fixed.mul(host.t, "0.65")
		host.set_pos(fixed.round(fixed.lerp_string(str(host.get_pos().x), str(host.get_pos().x + pos.x), t)), 0)
	if current_tick > 1 and current_tick < 9:
		if Utils.int_abs(host.get_pos().x - last_ground_fire) > GROUND_FIRE_DISTANCE:
			host.spawn_object(projectile_scene, 0, 0)
			last_ground_fire = host.get_pos().x
