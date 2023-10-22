extends BaseProjectile

func disable():
	.disable()
	creator.shockwave_projectile = null
