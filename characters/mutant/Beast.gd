extends Fighter

class_name Mutant

const INSTALL_TICKS = 120

onready var twist_attack_sprite = $"%TwistAttackSprite"

var install_ticks = 0
var shockwave_projectile = null
var spike_projectile = null

func process_extra(extra):
	.process_extra(extra)
	if extra.has("spike_enabled"):
		var obj = obj_from_name(spike_projectile)
		if obj:
			if !extra.spike_enabled:
				obj.disable()

func init(pos=null):
	.init(pos)
	twist_attack_sprite.material = sprite.get_material()

func tick():
	.tick()
	if twist_attack_sprite.visible: 
		twist_attack_sprite.frame = (twist_attack_sprite.frame + 1) % twist_attack_sprite.frames.get_frame_count("default")
