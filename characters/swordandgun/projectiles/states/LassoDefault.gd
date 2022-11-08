extends DefaultFireball

func _on_hit_something(obj, _hitbox):
	if obj is Fighter:
		host.hit(obj)
		queue_state_change("Holding")
	else:
		._on_hit_something(obj, _hitbox)
