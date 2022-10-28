extends CharacterState

const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/bullet.tscn")
const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")
#const BULLET_LENGTH = "1024"
const KICKBACK_FORCE = "-1.0"

export var screenshake_amount = 12

var bullet_location
var dir
var angle


func _frame_1():
	host.play_sound("Shoot")
	host.play_sound("ShootBass")
	var camera = host.get_camera()
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
	if camera:
		camera.bump(Vector2(float(dir.x), float(dir.y)), screenshake_amount, 0.25)
	bullet_location = host.opponent.get_hurtbox_center()
	var opp_vel = host.opponent.get_vel()
	bullet_location.x = fixed.round(fixed.add(str(bullet_location.x), opp_vel.x))
	bullet_location.y = fixed.round(fixed.add(str(bullet_location.y), opp_vel.y))

	var pos = host.get_pos()
	var bullet = host.spawn_object(BULLET_SCENE, bullet_location.x, bullet_location.y, true, bullet_location, false)
	bullet.set_facing(Utils.int_sign(host.opponent.get_pos().x - pos.x))
	var barrel_location = host.get_barrel_location(angle)
	spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(float(barrel_location.x) * host.get_facing_int(), float(barrel_location.y)), Vector2(float(dir.x), float(dir.y)))

func _frame_5():
	host.shooting_arm.frame = 1

func _frame_8():
	host.shooting_arm.frame = 2


func _exit():
	host.shooting_arm.hide()

func _tick():
	host.apply_fric()
	host.apply_forces()
	host.apply_grav()
	if air_type == AirType.Aerial:
		if current_tick > 2 and host.is_grounded():
			return "Landing"

func is_usable():
	return .is_usable() and host.bullets_left > 0
