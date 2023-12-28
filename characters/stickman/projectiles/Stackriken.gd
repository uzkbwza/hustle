extends BaseProjectile

var return_x
var return_y
var force_x
var force_y

func init(pos=null):
	.init(pos)
	get_fighter().stackriken_out = true

func disable():
	get_fighter().stackriken_out = false
	.disable()
