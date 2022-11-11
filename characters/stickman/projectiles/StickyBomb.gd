extends BaseProjectile

func explode():
	change_state("Explode")
	creator.bomb_thrown = false
	creator.bomb_projectile = null
