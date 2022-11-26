extends CharacterState

func _frame_0():
	host.flip.hide()
	host.screen_bump(Vector2(), 20, 10 / 60.0)
	host.take_damage(10000000)
