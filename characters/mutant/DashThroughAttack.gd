extends BeastState

func _frame_0():
#	host.disable_collisions()
	host.colliding_with_opponent = false
	pass

func _frame_6():
	host.turn_around()
	host.set_vel(fixed.mul(host.get_vel().x, "0.5"), "0")

func _frame_10():
	host.colliding_with_opponent = true
	pass

func _on_hit_something(obj, hitbox):
	host.set_vel(fixed.mul(host.get_vel().x, "0.75"), "0")

func _got_parried():
	host.set_vel(fixed.mul(host.get_vel().x, "0.75"), "0")
