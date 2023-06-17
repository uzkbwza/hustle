extends ObjectState

const UNLOCKED_HITLAG = 10
const LOCKED_HITLAG = 25

onready var hitbox = $Hitbox

func _enter():
	hitbox.victim_hitlag = UNLOCKED_HITLAG if !host.creator.locked else LOCKED_HITLAG

func _exit():
	host.disable()
