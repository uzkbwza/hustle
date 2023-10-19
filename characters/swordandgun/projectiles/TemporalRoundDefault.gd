extends ObjectState

const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")
const BULLET_SCENE = preload("res://characters/swordandgun/projectiles/NewTimeBullet.tscn")
onready var hitbox = $Hitbox

var pos

export var fast = false

func f1():
	var diff = host.obj_local_center(host.creator.opponent)
	host.distance = fixed.vec_len(str(diff.x), str(diff.y))
	hitbox.damage = host.scale_damage(hitbox.damage)
	hitbox.damage_in_combo = host.scale_damage(hitbox.damage_in_combo)
	hitbox.minimum_damage = host.scale_damage(hitbox.minimum_damage)
	hitbox.hitstun_ticks = host.scale_hitstun(hitbox.hitstun_ticks)
	var facing = Utils.int_sign(diff.x)
	if facing != 0:
		host.set_facing(facing)

func f2():
	var dir = fixed.normalized_vec(str(host.creator.current_di.x), str(host.creator.current_di.y))
	if fixed.eq(fixed.vec_len(dir.x, dir.y), "0"):
		var my_pos = host.get_pos()
		var opp_pos = host.creator.opponent.get_pos()
		dir = fixed.normalized_vec(str(opp_pos.x - my_pos.x), str(opp_pos.y - my_pos.y))
		
	pos = host.obj_local_center(host.creator.opponent)
	var my_pos = host.get_pos()

	spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(), Vector2(float(dir.x), float(dir.y)))
	var bullet = host.creator.spawn_object(BULLET_SCENE, my_pos.x, my_pos.y, true, null, false)
	bullet.dir_x = dir.x
	bullet.dir_y = dir.y
	host.play_sound("Shoot")
	host.play_sound("ShootBass")
	host.sprite.hide()
	hitbox.update_position(pos.x, pos.y)
#	hitbox.activate()

func f3():
	host.disable()
	
func _frame_17():
	if !fast:
		return
	f1()


func _frame_18():
	if !fast:
		return
	f2()


func _frame_19():
	if !fast:
		return
	f3()


func _frame_50():
	if fast:
		return
	f1()


func _frame_51():
	if fast:
		return
	f2()


func _frame_52():
	if fast:
		return
	f3()
