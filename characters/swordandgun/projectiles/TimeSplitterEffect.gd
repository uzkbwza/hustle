extends ParticleEffect
onready var animated_sprite = $AnimatedSprite

func _ready():
	var rng = BetterRng.new()
	rng.randomize()
	animated_sprite.rotation = rng.random_angle()

func tick():
	.tick()
	if is_instance_valid(animated_sprite):
		if animated_sprite.scale.x > 0:
			animated_sprite.scale -= Vector2.ONE * 0.045
		else:
			animated_sprite.scale *= 0
