extends ObjectState

func _frame_0():
	host.screen_bump(Vector2(), 20, 0.37)
	if host.creator:
		host.creator.orbital_strike_out = false
		host.creator.orbital_strike_projectile = null


func _frame_50():
	host.disable()
