extends CharacterState

const MAX_DIST = "200"


func process_projectile(projectile):
	var dir = xy_to_dir(data.x, data.y, MAX_DIST)
	projectile.sprite.set_material(host.sprite.get_material())
	var pos = host.get_pos()
	pos.x += fixed.round(dir.x)
	pos.y += fixed.round(dir.y)
	if pos.y > 0:
		pos.y = 0
	projectile.set_pos(pos.x, pos.y)
	host.after_image_object = projectile.obj_name

func _ready():
	pass

func is_usable():
	return .is_usable() and host.after_image_object == null
