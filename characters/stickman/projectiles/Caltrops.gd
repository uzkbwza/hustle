extends BaseProjectile

const DIVEKICK_BOUNCE = true

func hit_by(hitbox):
	var host = obj_from_name(hitbox.host)
	if host and host.is_in_group("Fighter") and host.id != id:
		if "IgnoreCaltrops" in hitbox.misc_data:
			return
		if !("LaunchCaltrops" in hitbox.misc_data):
			disable()
			return
	if host and host.is_in_group("Fighter"):
		host.projectile_free_cancel()
	var force = fixed.vec_mul(hitbox.dir_x, hitbox.dir_y, hitbox.knockback)
	if host.id == id:
		force = fixed.vec_add(force.x, force.y, str(creator.current_di.x/5), str(creator.current_di.y/20))
	apply_force(force.x, force.y)
	.hit_by(hitbox)
