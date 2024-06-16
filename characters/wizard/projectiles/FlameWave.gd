extends BaseProjectile


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func disable():
	.disable()
	if creator:
		creator.flame_wave_cooldown = creator.FLAME_WAVE_COOLDOWN
