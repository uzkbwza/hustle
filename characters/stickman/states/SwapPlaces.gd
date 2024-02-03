extends CharacterState

const MAX_X_DIST = 300
const MAX_Y_DIST = 300
const NEUTRAL_LAG = 0
const BACKWARD_PENALTY_AMOUNT_PER_PX = "0.25"
const BACKWARD_PENALTY_MAX_AMOUNT = 15
const BACKWARD_PENALTY_MIN_AMOUNT = 5
const CROSS_THROUGH_PENALTY = 5

var obj_name
var neutral_lag = 0

func _frame_0():
	neutral_lag = 0
	if host.combo_count <= 0:
		neutral_lag = NEUTRAL_LAG
		anim_length = 13
		iasa_at = 12
	else:
		anim_length = 8
		iasa_at = 7
	interruptible_on_opponent_turn = false

func _frame_6():
	var projectiles = get_usable_projectiles()
	var crossed_sides = false
	var start_dir = host.get_opponent_dir()
	if projectiles:
		var obj = projectiles[-1]
		var obj_pos = obj.get_pos()
		var my_pos = host.get_hurtbox_center()
		if host.combo_count <= 0:
			var opponent_pos = host.opponent.get_hurtbox_center()
			var obj_dist = Utils.int_abs(obj_pos.x - my_pos.x)
			if Utils.int_sign(obj_pos.x - my_pos.x) != host.get_opponent_dir():
				var penalty_amount = Utils.int_clamp(fixed.round(fixed.mul(BACKWARD_PENALTY_AMOUNT_PER_PX, str(obj_dist))), BACKWARD_PENALTY_MIN_AMOUNT, BACKWARD_PENALTY_MAX_AMOUNT)
				host.add_penalty(penalty_amount, true)
		obj_pos.y = obj_pos.y + 18
		if obj_pos.y > -16:
			obj_pos.y = 0
		host.set_pos(obj_pos.x, obj_pos.y)
		obj.set_pos(my_pos.x, my_pos.y)
		obj.set_facing(host.get_facing_int())
		if host.reverse_state:
			var vel = obj.get_vel()
			obj.set_vel(fixed.mul(vel.x, "-1"), vel.y)
		obj_name = obj.obj_name
		host.substituted_objects[obj_name] = true
		host.spawn_particle_effect(preload("res://characters/stickman/projectiles/SummonParticle.tscn"), obj.get_center_position_float())
		host.spawn_particle_effect(preload("res://characters/stickman/projectiles/SummonParticle.tscn"), host.get_center_position_float())
		host.detach()
		host.update_data()
		if start_dir != host.get_opponent_dir():
			host.add_penalty(CROSS_THROUGH_PENALTY, true)
	if host.combo_count == 0:
		host.hitlag_ticks += 2

	interruptible_on_opponent_turn = true

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
			if host.substituted_objects.has(obj_name):
				continue
			var obj_pos = obj.get_pos()
			var my_pos = host.opponent.get_hurtbox_center()
			if Utils.int_abs(obj_pos.x - my_pos.x) > MAX_X_DIST or Utils.int_abs(obj_pos.y - my_pos.y) > MAX_Y_DIST:
				continue
			usable.append(obj)
	return usable

func is_usable():
	return .is_usable() and get_usable_projectiles().size() > 0
