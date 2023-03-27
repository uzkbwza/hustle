extends BaseProjectile

var exploded = false
var armed = false

func init(pos=null):
	.init(pos)
	add_to_group("SparkBomb")

func explode():
	change_state("Explode")
	exploded = true
