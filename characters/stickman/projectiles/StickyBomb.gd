extends BaseProjectile

class_name StickyBomb

var attached = false

func explode():
	change_state("Explode")
	creator.bomb_thrown = false
	creator.bomb_projectile = null

func big_explode():
	change_state("BigExplode")
	creator.bomb_thrown = false
	creator.bomb_projectile = null
