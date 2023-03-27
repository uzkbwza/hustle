extends CharacterState

const MAX_X_DIST = 600
const MAX_Y_DIST = 300
const NEUTRAL_LAG = 2

var obj_name
var neutral_lag = 0

func _frame_0():
	neutral_lag = 0
	if host.combo_count <= 0:
		neutral_lag = NEUTRAL_LAG

func _frame_6():
	var projectiles = get_usable_projectiles()
	if projectiles:
		var obj = projectiles[-1]
		var obj_pos = obj.get_pos()
		var my_pos = host.get_hurtbox_center()
		host.set_pos(obj_pos.x, obj_pos.y)
		obj.set_pos(my_pos.x, my_pos.y)
		obj.set_facing(host.get_facing_int())
		if host.reverse_state:
			var vel = obj.get_vel()
			obj.set_vel(fixed.mul(vel.x, "-1"), vel.y)
		obj_name = obj.obj_name
		host.spawn_particle_effect(preload("res://characters/stickman/projectiles/SummonParticle.tscn"), obj.get_center_position_float())
		host.spawn_particle_effect(preload("res://characters/stickman/projectiles/SummonParticle.tscn"), host.get_center_position_float())
		host.detach()
	if host.combo_count == 0:
		host.hitlag_ticks += 2

func _frame_7():
	if host.objs_map.has(obj_name):
		var obj = host.objs_map[obj_name]
		if obj != null:
			obj.refresh_hitboxes()
			if obj is GrapplingHook:
				obj.unlock()

func _tick():
	if current_tick > 6:
		if neutral_lag > 0:
			neutral_lag -= 1
			current_tick = 6

func get_usable_projectiles():
	var usable = []
	for obj_name in host.objs_map:
		var obj = host.objs_map[obj_name]
		if obj is BaseObj and !(obj is Fighter) and obj.id == host.id and !obj.disabled:
			if obj is StickyBomb:
				if obj.attached:
					continue
			if obj is GrapplingHook:
				if obj.attached_to != null:
					continue
			var obj_pos = obj.get_pos()
			var my_pos = host.get_hurtbox_center()
			if Utils.int_abs(obj_pos.x - my_pos.x) > MAX_X_DIST or Utils.int_abs(obj_pos.y - my_pos.y) > MAX_Y_DIST:
				continue
			usable.append(obj)
	return usable

func is_usable():
	return .is_usable() and get_usable_projectiles().size() > 0
