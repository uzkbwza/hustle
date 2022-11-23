extends CharacterState


func _frame_4():
	host.screen_bump(Vector2.LEFT * host.get_facing_int(), 20, 20 / 60.0)
	host.screen_bump(Vector2(), 5, 20 / 60.0)
	pass
