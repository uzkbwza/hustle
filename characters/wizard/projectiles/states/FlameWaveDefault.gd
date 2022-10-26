extends DefaultFireball

onready var hitbox = $Hitbox

func _tick():
	._tick()
	if hitbox.enabled:
		spawn_particle_relative(particle_scene, Vector2())

func fizzle():
	.fizzle()
	host.creator.can_flame_wave = true
