extends BaseProjectile

signal lasso_hit(obj)

func _ready():
	pass

func disable():
	.disable()
	creator.lasso_projectile = null

func hit(obj):
	emit_signal("lasso_hit", obj)

func on_got_parried():
	.on_got_parried()
	if creator:
		creator.state_machine._change_state("Roll", {x = creator.get_opponent_dir(), no_invuln = true})
		creator.lasso_parried = true
