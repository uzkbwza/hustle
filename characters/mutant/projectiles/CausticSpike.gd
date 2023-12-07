extends BaseProjectile

var rotate_dir_x
var rotate_dir_y
var can_cancel = true

func set_rotation(data):
	rotate_dir_x = data.x
	rotate_dir_y = data.y

func copy_to(f):
	.copy_to(f)
#	f.set_facing(1)
