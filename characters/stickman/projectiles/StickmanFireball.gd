extends BaseProjectile

class_name NinjaShuriken

var dir_x = "0"
var dir_y = "0"

var can_stack = true

func _ready():
	state_variables.append_array(
		["dir_x", "dir_y"]
	)

func on_got_parried():
	.on_got_parried()
	can_stack = false

func hit_by(hitbox):
	.hit_by(hitbox)
	var host = obj_from_name(hitbox.host)
	if host:
		if host.is_in_group("Fighter"):
			disable()
