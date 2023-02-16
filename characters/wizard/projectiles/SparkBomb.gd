extends BaseProjectile

func init(pos=null):
	.init(pos)
	add_to_group("SparkBomb")

func explode():
	change_state("Explode")
