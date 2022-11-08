extends BaseProjectile

signal lasso_hit(obj)

func _ready():
	pass

func disable():
	.disable()
	creator.lasso_projectile = null

func hit(obj):
	emit_signal("lasso_hit", obj)
