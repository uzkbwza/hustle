extends CharacterState

const MAX_DIST = "200"
const X_MULTIPLIER = "1.5"
const Y_MULTIPLIER = "1.25"


func process_projectile(projectile):
	var dir = xy_to_dir(data.x, data.y, MAX_DIST)
	projectile.sprite.set_material(host.sprite.get_material())
	var pos = host.get_pos()
	pos.x += fixed.round(fixed.mul(dir.x, X_MULTIPLIER))
	pos.y += fixed.round(fixed.mul(dir.y, Y_MULTIPLIER))
#	print(dir)
	if pos.y > 0:
		pos.y = 0
#	print(pos)
	projectile.set_pos(pos.x, pos.y)
	host.after_image_object = projectile.obj_name

func _ready():
	pass

func is_usable():
	return .is_usable() and host.after_image_object == null
 
