extends CharacterState

const MAX_X_DIST = 600
const MAX_Y_DIST = 300

func _frame_4():
	var projectiles = get_usable_projectiles()
	if projectiles:
		var obj = projectiles[-1]
		var obj_pos = obj.get_pos()
		var my_pos = host.get_hurtbox_center()
		host.set_pos(obj_pos.x, obj_pos.y)
		obj.set_pos(my_pos.x, my_pos.y)
		host.spawn_particle_effect(preload("res://characters/stickman/projectiles/SummonParticle.tscn"), obj.get_center_position_float())
		host.spawn_particle_effect(preload("res://characters/stickman/projectiles/SummonParticle.tscn"), host.get_center_position_float())

func get_usable_projectiles():
	var usable = []
	for obj_name in host.objs_map:
		var obj = host.objs_map[obj_name]
		if obj is BaseObj and !(obj is Fighter) and obj.id == host.id and !obj.disabled:
			if obj is StickyBomb:
				if obj.attached:
					continue
			var obj_pos = obj.get_pos()
			var my_pos = host.get_hurtbox_center()
			if Utils.int_abs(obj_pos.x - my_pos.x) > MAX_X_DIST or Utils.int_abs(obj_pos.y - my_pos.y) > MAX_Y_DIST:
				continue
			usable.append(obj)
	return usable

func is_usable():
	return .is_usable() and get_usable_projectiles().size() > 0
