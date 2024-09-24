extends SuperMove

const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/bullet.tscn")
const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")
const TEMPORAL_BULLET_SCENE = preload("res://characters/swordandgun/projectiles/frozen_bullet.tscn")
const FAST_TEMPORAL_BULLET_SCENE = preload("res://characters/swordandgun/projectiles/frozen_bullet_fast.tscn")
#const BULLET_LENGTH = "1024"
const KICKBACK_FORCE = "-1.0"
const AUTO_AIM_DIST = "0.2"

export var screenshake_amount = 12
export var temporal = false
export var dodge = false

var bullet_location
var dir
var angle
var parried = false
var fast = false

func _frame_0():
	parried = false
#	fallback_state = "Holster"
	if !temporal:
		if data and data.has("Shots") and data["Shots"].has("count"):
			host.consecutive_shots = data["Shots"].count
			if dodge:
				host.consecutive_shots = 1
		if data and data.has("Direction"):
			host.shot_dir_x = data["Direction"].x
			host.shot_dir_y = data["Direction"].y

		iasa_at = 9
		if host.consecutive_shots > 0:
			iasa_at = -1
			host.consecutive_shots -= 1
	else:
		fast = data

func on_got_parried():
	parried = true
#	queue_state_change("SlowHolster")

func get_bullet_distance():
	var diff = host.obj_local_center(host.opponent)
	return fixed.vec_len(str(diff.x), str(diff.y))

func _frame_4():
	if temporal:
#		host.play_sound("Shoot")
#		host.play_sound("ShootBass")
		dir = host.obj_local_center(host.opponent)
		dir = fixed.normalized_vec(str(dir.x), str(dir.y))
		angle = fixed.vec_to_angle(fixed.mul(str(dir.x), str(host.get_facing_int())), str(dir.y))
		var bullet_location_local = host.get_barrel_location(angle)
		host.shooting_arm.rotation = float(angle)
		host.shooting_arm.show()
		host.shooting_arm.frame = 0
		var force = fixed.vec_mul(str(dir.x), str(dir.y), KICKBACK_FORCE)
		if host.is_grounded():
			force.y = "0"
		host.apply_force(force.x, force.y)
#		host.use_bullet()
		var camera = host.get_camera()
		if camera:
			camera.bump(Vector2(float(dir.x), float(dir.y)), screenshake_amount, 0.25)
		var pos = host.get_pos()
		bullet_location = fixed.vec_add(str(pos.x), str(pos.y), fixed.mul(bullet_location_local.x, str(host.get_facing_int())), bullet_location_local.y)
#		var opp_vel = host.opponent.get_vel()
#		bullet_location.x = fixed.round(fixed.add(str(bullet_location.x), opp_vel.x))
#		bullet_location.y = fixed.round(fixed.add(str(bullet_location.y), opp_vel.y))
		
		var bullet = host.spawn_object(TEMPORAL_BULLET_SCENE if !fast else FAST_TEMPORAL_BULLET_SCENE, fixed.round(bullet_location.x), fixed.round(bullet_location.y), true, bullet_location, false)
		
		bullet.set_facing(Utils.int_sign(host.opponent.get_pos().x - pos.x))
		var barrel_location = host.get_barrel_location(angle)
		host.temporal_round = bullet.obj_name

func is_accurate(dir, angle):
#	print(fixed.angle_dist(fixed.vec_to_angle(dir.x, dir.y), angle))
	return fixed.lt(fixed.abs(fixed.angle_dist(fixed.vec_to_angle(fixed.mul(dir.x, str(host.get_facing_int())), dir.y), angle)), AUTO_AIM_DIST)

func _frame_3():
	if !temporal:
		var clash = false
		host.play_sound("Shoot")
		host.play_sound("ShootBass")
		var bullet_location_local = host.obj_local_center(host.opponent)
		dir = fixed.normalized_vec_times(str(bullet_location_local.x), str(bullet_location_local.y), "1.0")
		angle = fixed.vec_to_angle(fixed.mul(dir.x, str(host.get_facing_int())), dir.y)
		var auto = _previous_state_name() == "Shoot" and host.combo_count > 0
		if auto:
			host.shot_dir_x = bullet_location_local.x
			host.shot_dir_y = bullet_location_local.y
		var shot_angle = fixed.vec_to_angle(fixed.mul(str(host.shot_dir_x), str(host.get_facing_int())), str(host.shot_dir_y)) if !auto else angle
		host.shooting_arm.rotation = float(shot_angle)
		host.shooting_arm.show()
		host.shooting_arm.frame = 0
		var force = fixed.vec_mul(dir.x, dir.y, KICKBACK_FORCE)
		if host.is_grounded():
			force.y = "0"
		host.apply_force(force.x, force.y)
		host.use_bullet()
		var camera = host.get_camera()
		if camera:
			camera.bump(Vector2(float(dir.x), float(dir.y)), screenshake_amount, 0.25)

		bullet_location = host.opponent.get_hurtbox_center()
		var opp_vel = host.opponent.get_vel()
		bullet_location.x = fixed.round(fixed.add(str(bullet_location.x), opp_vel.x))
		bullet_location.y = fixed.round(fixed.add(str(bullet_location.y), opp_vel.y))
		var pos = host.get_pos()
		var shot_hits = is_accurate(dir, shot_angle)
		if host.opponent.is_in_group("Cowboy"):
			var opponent_state = host.opponent.current_state()
			if opponent_state.name == "Shoot" and !opponent_state.temporal and opponent_state.start_tick == start_tick:
				var enemy_bullet_location_local = host.opponent.obj_local_center(host)
				var enemy_dir = fixed.normalized_vec_times(str(enemy_bullet_location_local.x), str(enemy_bullet_location_local.y), "1.0")
				var enemy_shot_angle = fixed.vec_to_angle(fixed.mul(str(host.opponent.shot_dir_x), str(host.get_facing_int())), str(host.opponent.shot_dir_y))
				var enemy_shot_hits = is_accurate(enemy_dir, enemy_shot_angle)
				if shot_hits and enemy_shot_hits:
					clash = true
		if !clash:
			if shot_hits:
				var bullet = host.spawn_object(BULLET_SCENE, bullet_location.x, bullet_location.y, true, bullet_location, false)
				bullet.connect("got_parried", self, "on_got_parried")
				
				bullet.set_facing(Utils.int_sign(host.opponent.get_pos().x - pos.x))
				bullet.distance = get_bullet_distance()
		else:
			if host.id == 1:
				host.parry_effect((host.opponent.get_center_position_float() + host.get_center_position_float()) / 2 + Vector2(0, -16), true)
#			queue_state_change("Holster")
		var barrel_location = host.get_barrel_location(shot_angle)
		spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(float(barrel_location.x) * host.get_facing_int(), float(barrel_location.y)), Vector2(float(host.shot_dir_x), float(host.shot_dir_y)))
		if dodge:
			host.start_invulnerability()

func _frame_8():
	if !temporal:
		host.shooting_arm.frame = 2

func _frame_5():
	if dodge:
		queue_state_change("ShootDodgeRoll", {"x": host.get_facing_int()})
	if !temporal:
		host.shooting_arm.frame = 1

func _frame_6():
	if temporal:
		host.shooting_arm.frame = 1

func _frame_9():
	if temporal:
		host.shooting_arm.frame = 2

func _exit():
	host.shooting_arm.hide()

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()
#	if host.opponent.current_state().get("parried"):
#		return "SlowHolster"
	if air_type == AirType.Aerial:
		if current_tick > 2 and host.is_grounded():
			return "Landing"
	if current_tick == 7 and !temporal:
		if host.consecutive_shots > 0:
			if host.bullets_left > 0:
				return "Shoot"
	if parried and !dodge:
		queue_state_change("SlowHolster")

func is_usable():
	return .is_usable() and (host.bullets_left > 0 or temporal) and host.has_gun
