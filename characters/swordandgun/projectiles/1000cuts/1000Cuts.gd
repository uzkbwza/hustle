extends BaseProjectile


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var total_ticks = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if creator_name:
		creator = objs_map[creator_name]

func disable():
	creator.end_1k_cuts_buff()
	creator.cut_projectile = null
