extends BaseProjectile

const DELAY_TICKS = 2

var exploded = false
var armed = false
var delay_ticks = 0

func init(pos=null):
	.init(pos)
	add_to_group("SparkBomb")

func explode(manual=false):
	if !manual:
		change_state("Explode")
	else:
		delay_ticks = DELAY_TICKS
	exploded = true


func tick():
	.tick()
