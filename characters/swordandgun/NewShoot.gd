extends CharacterState

const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash2.tscn")	
const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/NewBullet.tscn")
const SCREENSHAKE_AMOUNT = 12
const REPEAT_STARTUP_LAG = 3
const POINT_BLANK_HITBOX_DISTANCE_MODIFIER = "1.5"

export var dodge = false

export var projectile = true

onready var hitbox = $Hitbox

var startup_lag = 0
var lagged = false
var bullet_obj = null

func _enter():
	lagged = false
	if data == null:
		data = {
			x = 100 * host.get_facing_int(),
			y = 0,
			holster = true,
	}

func _frame_0():
#	anim_length = 12
	startup_lag = 0
	if _previous_state_name() == "Shoot2":
		startup_lag = REPEAT_STARTUP_LAG

	interrupt_into.erase("Gun")
	interrupt_into.erase("Grounded")
	interrupt_into.erase("Aerial")
	interrupt_into.erase("SlowHolster")
	interrupt_into.erase("AerialSuper")
	interrupt_into.erase("GroundedSuper")
	interrupt_into.erase("Guntrick")
#	interrupt_into.erase("Shoot")
	interrupt_into.erase("ShootDodge")
	interrupt_into.erase("Teleport")
	
	interrupt_exceptions.erase("Hustle")
	interrupt_exceptions.erase("FastTeleport")
	interrupt_exceptions.erase("SpotDodge")
	interrupt_exceptions.erase("Shoot")
	
	if !data["holster"]:
		interrupt_into.append("Gun")
		interrupt_into.append("SlowHolster")
		interrupt_into.append("AerialSuper")
		interrupt_into.append("GroundedSuper")
		interrupt_into.append("Guntrick")
		interrupt_into.append("Shoot")
		interrupt_into.append("ShootDodge")
		interrupt_into.append("Teleport")
		interrupt_exceptions.append("Hustle")
		interrupt_exceptions.append("FastTeleport")
		interrupt_exceptions.append("SpotDodge")
	else:
		interrupt_into.append("Grounded")
		interrupt_into.append("Aerial")
		interrupt_exceptions.append("Shoot")

func _frame_3():
	host.play_sound("Shoot")
	host.play_sound("ShootBass")
	var pos = host.get_pos()
	var shot_dir_x = data.x
	var shot_dir_y = data.y
	var dir = xy_to_dir(shot_dir_x, shot_dir_y)
	var shot_angle = fixed.vec_to_angle(fixed.mul(str(shot_dir_x), str(host.get_facing_int())), str(shot_dir_y))
	host.shooting_arm.rotation = float(shot_angle)
	host.shooting_arm.show()
	host.shooting_arm.frame = 0
	var hitbox_distance = "1.0" if projectile else POINT_BLANK_HITBOX_DISTANCE_MODIFIER
	var barrel_location = host.get_barrel_location(shot_angle, hitbox_distance)
	hitbox.dir_x = "-1.0" if fixed.sign(str(shot_dir_x)) != host.get_facing_int() else "1.0"
	hitbox.x = fixed.round(barrel_location.x)
	hitbox.y = fixed.round(barrel_location.y)
	var muzzle_flash_dir = Utils.ang2vec(float(shot_angle))
	muzzle_flash_dir.x *= host.get_facing_int()
	barrel_location.x = fixed.mul(barrel_location.x, str(host.get_facing_int()))
	spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(float(barrel_location.x), float(barrel_location.y)), muzzle_flash_dir)
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2(float(dir.x), float(dir.y)), SCREENSHAKE_AMOUNT, 0.25)
	host.use_bullet()
	if dodge:
		host.start_invulnerability()
	host.shooting_arm.rotation = float(shot_angle)
	host.shooting_arm.show()
	host.shooting_arm.frame = 0

#func _frame_5():
#	var pos = host.get_pos()
#	var shot_dir_x = data.x
#	var shot_dir_y = data.y
#	var dir = xy_to_dir(shot_dir_x, shot_dir_y)
#	var shot_angle = fixed.vec_to_angle(fixed.mul(str(shot_dir_x), str(host.get_facing_int())), str(shot_dir_y))
#	var barrel_location = host.get_barrel_location(shot_angle)
#	barrel_location.x = fixed.mul(barrel_location.x, str(host.get_facing_int()))


	if projectile:
		var bullet = host.spawn_object(BULLET_SCENE, pos.x + fixed.round(barrel_location.x), pos.y + fixed.round(barrel_location.y), true, barrel_location, false)
		bullet.connect("bullet_made_contact", self, "on_bullet_made_contact")
		bullet.dir_x = dir.x
		bullet.dir_y = dir.y
	
	if data and data.has("ActivateTemporal") and data["ActivateTemporal"]:
		var temporal_round = host.obj_from_name(host.temporal_round)
		if temporal_round:
			temporal_round.shoot()

func on_bullet_made_contact():
	pass

func _frame_5():
	if dodge:
		queue_state_change("TechRoll", {"x": host.get_facing_int()})


func _frame_6():
	host.shooting_arm.frame = 2

func _tick():
	if startup_lag > 0:
		startup_lag -= 1
		current_tick = 1

func _exit():
	host.shooting_arm.hide()

func is_usable():
	return .is_usable() and (host.bullets_left > 0) and host.has_gun
