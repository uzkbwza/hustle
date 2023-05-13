extends BaseProjectile

var total_ticks = 0

func _ready():
	if creator_name:
		creator = objs_map[creator_name]

func disable():
	creator.cut_projectile = null
	creator.end_1k_cuts_buff()
	.disable()
