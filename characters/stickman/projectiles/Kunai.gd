extends BaseProjectile

const DIVEKICK_BOUNCE = true

func hit_by(hitbox):
	.hit_by(hitbox)
	var host = obj_from_name(hitbox.host)
	if host:
		if host.is_in_group("Fighter"):
			disable()
