extends BaseProjectile

func disable():
	.disable()
	creator.shockwave_projectile = null

func on_got_blocked():
	disable()
	
