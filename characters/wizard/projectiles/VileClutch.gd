extends BaseProjectile

func disable():
	.disable()
	creator.can_vile_clutch = true
