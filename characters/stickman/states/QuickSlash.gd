extends SuperMove

const MOVE_DISTANCE = 120
const NEUTRAL_STARTUP_LAG = 3
const LANDING_LAG = 2
const IASA = 20
const WHIFF_LANDING_LAG = 4
const WHIFF_IASA = 20
const BUFFER_ATTACK_GROUND_SNAP_DISTANCE = 4

var hitboxes = []

var dist = MOVE_DISTANCE

var attack = 0

var startup_lag = 0
var landing_lag = LANDING_LAG

var started_in_neutral = false

func _enter():
	dist = MOVE_DISTANCE
	hitboxes = []
	attack = data.Attack.id
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			child.x = 0
			child.y = 0
			if attack == 0:
				child.damage_in_combo = 90
			else:
				child.damage_in_combo = 40
	var move_dir
		
	if data:
		move_dir = xy_to_dir(data.Direction.x, data.Direction.y)
#		move_dir = fixed.normalized_vec_times(move_dir.x, move_dir.y, "1.0")
	else:
		move_dir = { "x": str(host.get_facing_int()), "y": "0" }
	var move_vec = fixed.vec_mul(move_dir.x, move_dir.y, "20")

	host.apply_force(move_vec.x,  fixed.div(move_vec.y, "2"))
	host.quick_slash_move_dir_x = move_dir.x
	host.quick_slash_move_dir_y = move_dir.y

#	move_vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, str(MOVE_DISTANCE))
#	var pos = host.get_pos()
#	var dest = {
#		"x": fixed.add(str(pos.x), move_vec.x), 
#		"y": fixed.add(str(pos.y), move_vec.y),
#	}
#
#	if !fixed.eq(dest.y, str(pos.y)):
#		var x_intercept = fixed.get_x_intercept(str(pos.x), str(pos.y), dest.x, dest.y)
#		var len_ = fixed.vec_len(move_vec.x, move_vec.y)
#		var sub = fixed.vec_sub(x_intercept, "0", str(pos.x), str(pos.y))
#		var dest_len = fixed.vec_len(sub.x, sub.y)
#		if fixed.lt(dest_len, len_):
#			dist = dest_len
#		else:
#			dist = str(MOVE_DISTANCE)
#	else:
#		dist = str(MOVE_DISTANCE)
#	for i in range(hitboxes.size()):
#		var vec
#		if i > 0:
#			var ratio = fixed.div(str(i), str(hitboxes.size()))
#			var length = fixed.mul(fixed.mul(dist, "-2"), ratio)
#			vec = fixed.normalized_vec_times(move_dir.x, move_dir.y, length)
#		else:
#			vec = {"x": "0", "y": "0"}
##		vec = fixed.vec_mul(vec.x, vec.y, str(-MOVE_DISTANCE))
#		hitboxes[i].x = fixed.round(fixed.mul(vec.x, str(host.get_facing_int())))
#		hitboxes[i].y = fixed.round(fixed.sub(vec.y, "16"))

func _frame_0():
	started_in_neutral = host.combo_count <= 0
	host.set_grounded(false)
	var start_pos = host.get_pos().duplicate()
	host.quick_slash_start_pos_x = start_pos.x
	host.quick_slash_start_pos_y = start_pos.y
	if get_next_attack() and started_in_neutral:
		current_tick += 1
#	iasa_at = WHIFF_IASA
#	landing_lag = WHIFF_LANDING_LAG
#	host.hitlag_ticks += NEUTRAL_STARTUP_LAG if host.combo_count <= 0 else 0


func _frame_4():
	if host.initiative:
		host.start_invulnerability()

func _frame_5():
#	host.move_directly(0, - 0)

	var move_dir_x = host.quick_slash_move_dir_x
	var move_dir_y = host.quick_slash_move_dir_y

	var move_vec = fixed.normalized_vec_times(move_dir_x, move_dir_y, str(MOVE_DISTANCE))
	
	host.move_directly(move_vec.x, move_vec.y)
	host.update_data()
	
	var start_pos_x = host.quick_slash_start_pos_x
	var start_pos_y = host.quick_slash_start_pos_y
	
	var end_pos = host.get_pos().duplicate()
	
	move_vec.x = end_pos.x - start_pos_x
	move_vec.y = end_pos.y - start_pos_y
	var pos = host.get_pos_visual()
	var particle_dir = Vector2(float(move_vec.x), float(move_vec.y)).normalized()
	host.spawn_particle_effect(preload("res://characters/stickman/QuickSlashEffect.tscn"), Vector2(start_pos_x, start_pos_y - 13), particle_dir)
	host.update_data()


func _frame_6():
	var start_pos_x = host.quick_slash_start_pos_x
	var start_pos_y = host.quick_slash_start_pos_y
	
	var end_pos = host.get_pos().duplicate()
	if start_pos_x != null and start_pos_y != null and end_pos.x != null and end_pos.y != null:
		for i in range(hitboxes.size()):
			var ratio = fixed.div(str(i), str(hitboxes.size()))
			hitboxes[i].x = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_x), str(end_pos.x), ratio), str(host.get_pos().x))) * host.get_facing_int()
			hitboxes[i].y = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_y), str(end_pos.y), ratio), str(host.get_pos().y))) - 16
	
	var move_dir_x = host.quick_slash_move_dir_x
	var move_dir_y = host.quick_slash_move_dir_y


	var next_attack = get_next_attack()

	if next_attack == null:
		host.reset_momentum()
		var move_vec = fixed.normalized_vec_times(move_dir_x, move_dir_y, "10")
		host.apply_force(move_dir_x, fixed.mul(move_dir_y, "1.0"))
		host.apply_force("0", "-1")
#	var move_vec = fixed.normalized_vec_times(move_dir_x, move_dir_y, "10")
#	if fixed.le(move_dir_y, "0"):
#		host.reset_momentum()
#		host.apply_force("0", "-1")
#	if host.is_grounded():
##		queue_state_change("Landing", 2)
#		var vel = host.get_vel()
#		host.set_vel(fixed.mul(vel.x, "0.5"), vel.y)
#	host.apply_force(move_dir_x, fixed.mul(move_dir_y, "1.0"))
	else:
		if started_in_neutral:
#			host.update_grounded()
#			if host.is_grounded():
				switch_to_followup()
				pass
	host.end_invulnerability()

#func _frame_7():
#	if started_in_neutral:
#		if !host.is_grounded():
#			if get_next_attack():
#				switch_to_followup()

#func _frame_8():
#	if started_in_neutral:
#		if !host.is_grounded():
#			switch_to_followup()

func switch_to_followup():
	var vel = host.get_vel()
	host.set_vel(fixed.mul(vel.x, "0.25"), fixed.mul(vel.y, "0.5"))
	queue_state_change(get_next_attack())
	if host.get_pos().y > -BUFFER_ATTACK_GROUND_SNAP_DISTANCE:
		host.set_vel(vel.x, "0")
		host.move_directly(0, BUFFER_ATTACK_GROUND_SNAP_DISTANCE)
		host.set_grounded(true)
		host.set_vel(fixed.mul(vel.x, "0.35"), "0")

func get_next_attack():
	if !started_in_neutral:
		if !hit_anything:
			return null
	var grounded = host.get_pos().y > -BUFFER_ATTACK_GROUND_SNAP_DISTANCE
	match attack:
		0: return null
		1: return "GroundedPunchQS" if grounded else "AirUpwardPunchQS"
		2: return "GroundedSweepQS" if grounded else "AirAttackQS"
		3: return "NunChukHeavyQS" if grounded else "NunChukSpinQS"

func can_hit_cancel():
	return (host.combo_count > 1 or !host.opponent.is_grounded()) and attack == 0

func _got_parried():
	return
#	host.hitlag_ticks += 15
#	host.reset_momentum()
#	pass

func _on_hit_something(obj, hitbox):
#	iasa_at = IASA
#	landing_lag = LANDING_LAG
	._on_hit_something(obj, hitbox)
	if get_next_attack() != null and !started_in_neutral:
		switch_to_followup()

func _tick():
#	if startup_lag > 0:
##		if startup_lag == 0:
##			host.reset_momentum()
#		startup_lag -= 1
#		current_tick = 0
	if get_next_attack() != null:
		if current_tick == 2:
			current_tick = 3
		
	if current_tick > 6:
		if host.is_grounded():
			if get_next_attack() == null:
				queue_state_change("Landing", landing_lag)
	host.apply_grav()
#	host.apply_fric()
	host.apply_forces_no_limit()
