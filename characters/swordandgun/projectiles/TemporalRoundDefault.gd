extends ObjectState

const MUZZLE_FLASH_SCENE = preload("res://characters/swordandgun/projectiles/MuzzleFlash.tscn")
onready var hitbox = $Hitbox

var pos

func _frame_30():
	pos = host.obj_local_center(host.creator.opponent)
	var dir = fixed.normalized_vec(str(pos.x), str(pos.y))
	spawn_particle_relative(MUZZLE_FLASH_SCENE, Vector2(), Vector2(float(dir.x), float(dir.y)))
	host.play_sound("Shoot")
	host.play_sound("ShootBass")
	host.sprite.hide()
	hitbox.update_position(pos.x, pos.y)
	hitbox.activate()
	

func _frame_31():
	host.disable()
