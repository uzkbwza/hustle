extends TelekinesisProjectile

export var explode_tick = 30

func tick():
	.tick()
	if current_tick	> explode_tick:
		disable()
