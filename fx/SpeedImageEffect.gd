extends ParticleEffect

onready var sprite = $Sprite

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var alpha = 1.0

func set_texture(tex):
	sprite.texture = tex

func tick():
	.tick()
	modulate.a = alpha * clamp((1.0 - ((tick / 60.0) / lifetime)), 0.0, 1.0)

func set_color(color: Color):
	modulate.r = color.r
	modulate.g = color.g
	modulate.b = color.b
	alpha = color.a
