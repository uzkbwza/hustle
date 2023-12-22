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
