extends DefaultFireball

const PROJECTILE = preload("res://characters/swordandgun/projectiles/AfterImageExplosion.tscn")

const LIFETIME = 100

var rift_frames = 5

func _tick():
	if current_tick > LIFETIME:
		host.disable()
	if host.detonating:
		rift_frames -= 1
		if rift_frames == 0:
			explode()

func explode():
	var pos = host.get_pos()
	var explosion = host.spawn_object(PROJECTILE, 0, 0)
	explosion.set_pos(pos.x, pos.y - 18)
	host.disable()
