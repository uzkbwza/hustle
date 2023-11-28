extends BaseProjectile

class_name NinjaShuriken

var dir_x = "0"
var dir_y = "0"

func _ready():
	state_variables.append_array(
		["dir_x", "dir_y"]
	)
