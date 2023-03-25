extends BaseProjectile

class_name StickyBomb

var detonating = false
var attached = false

func explode():
	detonating = true

func big_explode():
	change_state("BigExplode")
	creator.bomb_thrown = false
	creator.bomb_projectile = null
