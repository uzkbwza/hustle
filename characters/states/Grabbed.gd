extends CharacterState

func _enter():
	host.colliding_with_opponent = false
	host.opponent.colliding_with_opponent = false
	host.start_invulnerability()

func _tick():
#	var throw_pos = host.opponent.get_global_throw_pos()
#	host.set_pos()
	pass
