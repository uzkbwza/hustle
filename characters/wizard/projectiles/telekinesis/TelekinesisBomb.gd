extends TelekinesisProjectile

export var explode_tick = 60

func tick():
	.tick()
	if current_tick > explode_tick:
		disable()
