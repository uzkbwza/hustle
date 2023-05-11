extends SuperMove

const BOULDERS = [
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder.tscn"),
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder2.tscn"), 
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder.tscn"),
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder2.tscn"), 
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder3.tscn"),
]

const SILLY_ITEM_CHANCES = {
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisPebble.tscn"): 3,
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBomb.tscn"): 3,
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisTire.tscn"): 5,
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisFruit.tscn"): 3,
}

const NON_BOULDER_CHANCE = 15

func _enter():
	projectile_scene = host.randi_choice(BOULDERS)
	if host.randi_percent(NON_BOULDER_CHANCE):
#	if host.randi_percent(100):
		projectile_scene = host.randi_weighted_choice(SILLY_ITEM_CHANCES.keys(), SILLY_ITEM_CHANCES.values())
	if host.is_ghost:
		projectile_scene = preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulderGhost.tscn")
	
func process_projectile(obj):
	host.play_sound("HitBass")
	host.boulder_projectile = obj.obj_name

func is_usable():
	return .is_usable() and host.boulder_projectile == null
