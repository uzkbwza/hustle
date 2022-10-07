extends CharacterState

func _tick():
	host.set_pos(host.opponent.get_global_throw_pos())
	pass
