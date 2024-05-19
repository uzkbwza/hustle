extends SuperMove

const MOVE_DISTANCE = 120
const LANDING_LAG = 2
const IASA = 20
const WHIFF_LANDING_LAG = 4
const WHIFF_IASA = 20
const EXPLOSION = preload("res://characters/swordandgun/projectiles/AfterImageExplosionEffect.tscn")
const HITBOX_START_FRAME = 6

var hitboxes = []

var dist = MOVE_DISTANCE

var attack = 0

var startup_lag = 0
var landing_lag = LANDING_LAG

var got_blocked = false

func is_usable():
	return .is_usable() and host.cut_projectile != null

func setup_hitboxes():
	hitboxes = []
	var hitbox_frame = HITBOX_START_FRAME
	for child in get_children():
		if child is Hitbox:
			hitboxes.append(child)
			child.start_tick = hitbox_frame
			hitbox_frame += 1

	.setup_hitboxes()

func _enter():
	got_blocked = false
	dist = MOVE_DISTANCE
	var hitbox_frame = HITBOX_START_FRAME
	for hitbox in hitboxes:
		hitbox.x = 0
		hitbox.y = 0
	
	var move_dir
	if data:
		move_dir = xy_to_dir(data.x, data.y)

	else :
		move_dir = {"x":str(host.get_facing_int()), "y":"0"}
	var move_vec = fixed.vec_mul(move_dir.x, move_dir.y, "12")

	host.apply_force(move_vec.x, fixed.div(move_vec.y, "2"))
	host.fatal_cut_move_dir_x = move_dir.x
	host.fatal_cut_move_dir_y = move_dir.y

func _frame_0():
	host.set_grounded(false)
	var start_pos = host.get_pos().duplicate()
	host.fatal_cut_start_pos_x = start_pos.x
	host.fatal_cut_start_pos_y = start_pos.y
	if host.has_1k_cuts():
		host.obj_from_name(host.cut_projectile).disable()



func _frame_4():
	if host.initiative:
		host.start_invulnerability()

	var move_dir_x = host.fatal_cut_move_dir_x
	var move_dir_y = host.fatal_cut_move_dir_y

	var move_vec = fixed.normalized_vec_times(move_dir_x, move_dir_y, str(MOVE_DISTANCE))
	
	host.move_directly(move_vec.x, move_vec.y)
	host.update_data()
	
	var start_pos_x = host.fatal_cut_start_pos_x
	var start_pos_y = host.fatal_cut_start_pos_y
	var end_pos = host.get_pos().duplicate()
	move_vec.x = end_pos.x - start_pos_x
	move_vec.y = end_pos.y - start_pos_y
	var pos = host.get_pos_visual()
	var particle_dir = Vector2(float(move_vec.x), float(move_vec.y)).normalized()
	host.spawn_particle_effect(preload("res://characters/stickman/QuickSlashEffect.tscn"), Vector2(start_pos_x, start_pos_y - 13), particle_dir)
	host.update_data()
	host.prediction_effect()

func _frame_5():
	var start_pos_x = host.fatal_cut_start_pos_x
	var start_pos_y = host.fatal_cut_start_pos_y
	
	var end_pos = host.get_pos().duplicate()
	if start_pos_x != null and start_pos_y != null and end_pos.x != null and end_pos.y != null:
		for i in range(hitboxes.size()):
			var ratio = fixed.div(str(i), str(hitboxes.size()))
			var pos_x = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_x), str(end_pos.x), ratio), str(host.get_pos().x))) * host.get_facing_int()
			var pos_y = fixed.round(fixed.sub(fixed.lerp_string(str(start_pos_y), str(end_pos.y), ratio), str(host.get_pos().y))) - 16
#			host.spawn_particle_effect_relative(EXPLOSION, Vector2(pos_x, pos_y))
			hitboxes[i].x = pos_x
			hitboxes[i].y = pos_y
	
	var move_dir_x = host.fatal_cut_move_dir_x
	var move_dir_y = host.fatal_cut_move_dir_y
	host.end_invulnerability()


func on_got_blocked():
	.on_got_blocked()
	got_blocked = true
	pass

func _tick():
	if current_tick > 12:
		host.apply_grav()
		host.apply_fric()
	if current_tick > 35:
		if got_blocked:
			enable_interrupt()
			got_blocked = false
	host.apply_forces_no_limit()
