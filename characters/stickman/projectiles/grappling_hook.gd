extends BaseProjectile

const MAX_HEIGHT = 300

class_name GrapplingHook

var attached_to = null
var is_locked = false
var start_y = 0

func _ready():
	pass # Replace with function body.

func disable():
	.disable()
	play_sound("DetachSound")
	creator.grappling_hook_projectile = null

func tick():
	.tick()
	if get_pos().y < start_y - MAX_HEIGHT:
		disable()

func update_rotation():
	var pos = creator.get_center_position_float()
	sprite.rotation = to_local(pos).angle()
	
func on_got_parried():
	.on_got_parried()
	disable()

func unlock():
	if is_locked:
		change_state("Default")
		is_locked = false
		attached_to = null
