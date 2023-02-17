extends ObjectState

func _frame_0():
	host.screen_bump(Vector2(), 20, 0.37)
	if host.creator:
		host.creator.orbital_strike_out = false
		host.creator.orbital_strike_projectile = null
		host.creator.loic_meter = 0
		host.creator.can_loic = false
		host.creator.loic_draining = false
		print(Utils.int_abs(host.obj_local_center(host.creator).x) <= 20)
		if Utils.int_abs(host.obj_local_center(host.creator).x) <= 20:
			host.creator.add_armor_pip()
			
	host.line_drawer.z_index = 1000

func _frame_50():
	host.disable()
#
#func process_projectile(obj):
#	obj.from_loic = true
