extends BaseProjectile

func hit_by(hitbox):
	var host = obj_from_name(hitbox.host)
	if host and host.is_in_group("Fighter"):
		disable()
	.hit_by(hitbox)
