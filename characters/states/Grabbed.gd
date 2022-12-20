extends CharacterState

func _ready():
	is_hurt_state = true

func _enter():
	host.has_hyper_armor = false
	host.colliding_with_opponent = false
	host.opponent.colliding_with_opponent = false
	host.start_invulnerability()

func _tick():
	pass
