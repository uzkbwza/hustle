extends SuperMove

const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/bullet.tscn")
const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")
const TEMPORAL_BULLET_SCENE = preload("res://characters/swordandgun/projectiles/frozen_bullet.tscn")
#const BULLET_LENGTH = "1024"
const KICKBACK_FORCE = "-1.0"

export var screenshake_amount = 12
export var temporal = false

var bullet_location
var dir
var angle

func _frame_0():
#	fallback_state = "Holster"
	if !temporal:
		if data and data.has("count"):
			host.consecutive_shots = data.count
		iasa_at = 7
		if host.consecutive_shots > 0:
			iasa_at = -1
			host.consecutive_shots -= 1

func on_got_parried():
	queue_state_change("SlowHolster")

func _frame_1():
	if !temporal:
		var clash = false
		if host.opponent.is_in_group("Cowboy"):
			var opponent_state = host.opponent.current_state()
			if opponent_state.name == "Shoot" and !opponent_state.temporal and opponent_state.start_tick == start_tick:
				clash = true
		host.play_sound("Shoot")
		host.play_sound("ShootBass")
		var bullet_location_local = host.obj_local_center(host.opponent)
		dir = fixed.normalized_vec_times(str(bullet_location_local.x), str(bullet_location_local.y), "1.0")
		angle = fixed.vec_to_angle(fixed.mul(dir.x, str(host.get_facing_int())), dir.y)
		host.shooting_arm.rotation = float(angle)
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
		if !clash:
			var bullet = host.spawn_object(BULLET_SCENE, bullet_location.x, bullet_location.y, true, bullet_location, false)
			bullet.connect("got_parried", self, "on_got_parried")
			bullet.set_facing(Utils.int_sign(host.opponent.get_pos().x - pos.x))
		else:
			if host.id == 1:
				host.parry_effect((host.opponent.get_center_position_float() + host.get_center_position_float()) / 2 + Vector2(0, -16), true)
			queue_state_change("Holster")
		var barrel_location = host.get_barrel_location(angle)
		spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(float(barrel_location.x) * host.get_facing_int(), float(barrel_location.y)), Vector2(float(dir.x), float(dir.y)))

func _frame_4():
	if temporal:
#		host.play_sound("Shoot")
#		host.play_sound("ShootBass")
		var camera = host.get_camera()
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
		if camera:
			camera.bump(Vector2(float(dir.x), float(dir.y)), screenshake_amount, 0.25)
		var pos = host.get_pos()
		bullet_location = fixed.vec_add(str(pos.x), str(pos.y), fixed.mul(bullet_location_local.x, str(host.get_facing_int())), bullet_location_local.y)
#		var opp_vel = host.opponent.get_vel()
#		bullet_location.x = fixed.round(fixed.add(str(bullet_location.x), opp_vel.x))
#		bullet_location.y = fixed.round(fixed.add(str(bullet_location.y), opp_vel.y))

		var bullet = host.spawn_object(TEMPORAL_BULLET_SCENE, fixed.round(bullet_location.x), fixed.round(bullet_location.y), true, bullet_location, false)
		bullet.set_facing(Utils.int_sign(host.opponent.get_pos().x - pos.x))
		var barrel_location = host.get_barrel_location(angle)

func _frame_8():
	if !temporal:
		host.shooting_arm.frame = 2

func _frame_5():
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

func is_usable():
	return .is_usable() and (host.bullets_left > 0 or (temporal)) and host.has_gun
