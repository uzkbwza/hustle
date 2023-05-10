extends SuperMove

const BOULDERS = [
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder.tscn"),
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder2.tscn"), 
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder.tscn"),
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder2.tscn"), 
	preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulder3.tscn"),
]

func _enter():
	projectile_scene = host.randi_choice(BOULDERS)

	if host.is_ghost:
		projectile_scene = preload("res://characters/wizard/projectiles/telekinesis/TelekinesisBoulderGhost.tscn")

func process_projectile(obj):
	host.play_sound("HitBass")
	host.boulder_projectile = obj.obj_name

func is_usable():
	return .is_usable() and host.boulder_projectile == null and host.orb_projectile == null
