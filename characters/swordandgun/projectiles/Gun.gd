extends BaseProjectile

const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/gun_throw_bullet.tscn")
const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")

export var screenshake_amount = 12

var can_be_picked_up = false
var shot = false
var lassoed = true
var reeled = false

func init(pos=null):
	.init(pos)
	can_be_picked_up = false

func shoot(fighter: Fighter):
	var bullet_location = fighter.get_hurtbox_center()
	var bullet_location_local = obj_local_center(fighter)
	var dir = fixed.normalized_vec_times(str(bullet_location_local.x), str(bullet_location_local.y), "1.0")
	var bullet = spawn_object(BULLET_SCENE, bullet_location.x, bullet_location.y, true, bullet_location, false)
	spawn_particle_effect_relative(MUZZLE_FLASH_SCENE, Vector2(), Vector2(float(dir.x), float(dir.y)))
	var recoil = fixed.normalized_vec_times(fixed.mul(dir.x, "-1"), fixed.mul(dir.y, "-1"), "5")
	reset_momentum()
	apply_force(recoil.x, recoil.y)
	play_sound("Shoot")
	play_sound("ShootBass")
	var camera = get_camera()
	if camera:
		camera.bump(Vector2(float(dir.x), float(dir.y)), screenshake_amount, 0.25)
	shot = true

func on_got_blocked():
	if current_state().name == "Spin" and !reeled:
		current_state().pop_up()

func reset_hitbox():
	change_state("Spin")
	reeled = true
	pass
