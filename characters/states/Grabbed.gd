extends CharacterState

func _ready():
	is_hurt_state = true

func _enter():
	host.set_snap_to_ground(false)
	host.has_hyper_armor = false
	host.colliding_with_opponent = false
	host.opponent.colliding_with_opponent = false
	host.start_invulnerability()


func _exit():
	host.set_snap_to_ground(true)

func _tick():
	pass
