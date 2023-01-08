extends WizardState

const PUSH_FORCE = "5.0"

func _frame_0():
	iasa_at = -1

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	obj.apply_force(fixed.mul(str(host.get_facing_int()), PUSH_FORCE), "0")
	iasa_at = 12
	pass
