extends ObjectState

const UNLOCKED_DAMAGE = 100
const LOCKED_DAMAGE = 110

onready var hitbox = $Hitbox

func _enter():
	hitbox.damage = UNLOCKED_DAMAGE if !host.creator.locked else LOCKED_DAMAGE
	hitbox.damage_in_combo = UNLOCKED_DAMAGE if !host.creator.locked else LOCKED_DAMAGE

func _exit():
	host.disable()
	host.hide()
