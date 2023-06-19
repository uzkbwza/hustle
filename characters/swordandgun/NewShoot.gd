extends CharacterState

const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash2.tscn")
const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/NewBullet.tscn")
const SCREENSHAKE_AMOUNT = 12
const REPEAT_STARTUP_LAG = 5

export var dodge = false

onready var hitbox = $Hitbox

var startup_lag = 0

func _enter():
	if data == null:
		data = {
			x = 100 * host.get_facing_int(),
			y = 0
	}

func _frame_0():
	startup_lag = 0
	if _previous_state_name() == "Shoot2":
		startup_lag = REPEAT_STARTUP_LAG

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
	var barrel_location = host.get_barrel_location(shot_angle)
	barrel_location.x = fixed.mul(barrel_location.x, str(host.get_facing_int()))
	var muzzle_flash_dir = Utils.ang2vec(float(shot_angle))
	muzzle_flash_dir.x *= host.get_facing_int()
	spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(float(barrel_location.x), float(barrel_location.y)), muzzle_flash_dir)
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2(float(dir.x), float(dir.y)), SCREENSHAKE_AMOUNT, 0.25)
	var bullet = host.spawn_object(BULLET_SCENE, pos.x + fixed.round(barrel_location.x), pos.y + fixed.round(barrel_location.y), true, barrel_location, false)
	hitbox.x = fixed.round(barrel_location.x)
	hitbox.y = fixed.round(barrel_location.y)
	bullet.dir_x = dir.x
	bullet.dir_y = dir.y
	if dodge:
		host.start_invulnerability()
	host.use_bullet()

func _frame_5():
	if dodge:
		queue_state_change("TechRoll", {"x": host.get_facing_int()})

func _frame_8():
	host.shooting_arm.frame = 2

func _tick():
	if startup_lag > 0:
		startup_lag -= 1
		current_tick = 1

func _exit():
	host.shooting_arm.hide()

func is_usable():
	return .is_usable() and (host.bullets_left > 0) and host.has_gun
