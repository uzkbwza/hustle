extends "res://characters/stickman/projectiles/fireball_states/Default.gd"

const ROTATE_AMOUNT = 22.5

func _tick():
	._tick()
	host.sprite.rotation += deg2rad(ROTATE_AMOUNT) * host.get_facing_int()
