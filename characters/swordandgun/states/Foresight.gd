extends CharacterState

const MAX_DIST = "200"
const X_MULTIPLIER = "1.5"
const Y_MULTIPLIER = "1.25"

func _frame_0():
	anim_length = 14
	if host.combo_count > 0:
		anim_length = 10

func process_projectile(projectile):
	var dir = xy_to_dir(data.x, data.y, MAX_DIST)
	host.setup_foresight(projectile)
	var pos = host.get_pos()
	pos.x += fixed.round(fixed.mul(dir.x, X_MULTIPLIER))
	pos.y += fixed.round(fixed.mul(dir.y, Y_MULTIPLIER))
	if pos.y > 0:
		pos.y = 0
	projectile.set_pos(pos.x, pos.y)

func _ready():
	pass

func is_usable():
	return .is_usable() and host.after_image_object == null
 
