extends BaseProjectile

const IS_ROBOT_MISSILE = true

var detected_friends = []

func hit_by(hitbox):
	if hitbox.id == id:
		return
	.hit_by(hitbox)
	if hitbox and hitbox.throw:
		return
	if objs_map.has(hitbox.host):
		var host = objs_map[hitbox.host]
		if host.is_in_group("Fighter"):
			disable()

func disable():
	spawn_particle_effect_relative(preload("res://fx/SmallExplosion.tscn"))
	screen_bump(Vector2(), 5.0, 0.4)
	.disable()
