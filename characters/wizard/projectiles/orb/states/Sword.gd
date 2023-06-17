extends "res://characters/wizard/projectiles/orb/states/Default.gd"

const LOCKED_DAMAGE = 85
const UNLOCKED_DAMAGE = 60

onready var hitbox_3 = $Hitbox3

func _enter():
	var damage = LOCKED_DAMAGE if host.locked else UNLOCKED_DAMAGE
	hitbox_3.damage = damage
	hitbox_3.damage_in_combo = damage


func _tick():
	._tick()
	if !host.locked:
		hitbox_3.damage = UNLOCKED_DAMAGE
		hitbox_3.damage_in_combo = UNLOCKED_DAMAGE
