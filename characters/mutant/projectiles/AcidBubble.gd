extends BaseProjectile

const KNOCKBACK_MULTIPLIER = "2.0"
const MAX_SPEED = "10.0"

func hit_by(hitbox):
	.hit_by(hitbox)
	if objs_map.has(hitbox.host):
		var host = objs_map[hitbox.host]
		if host:
			if host.id == id:
				var f = fixed.normalized_vec_times(fixed.mul(hitbox.dir_x, str(host.get_facing_int())), hitbox.dir_y, fixed.mul(hitbox.knockback, KNOCKBACK_MULTIPLIER))
				apply_force(f.x, f.y)
				if host.is_in_group("Fighter"):
					host.projectile_free_cancel()
			else:
				change_state("Pop")

func tick():
	.tick()
	limit_speed(MAX_SPEED)

func on_got_blocked():
	change_state("Pop")
