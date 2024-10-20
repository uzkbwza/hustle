tool
extends Hitbox

class_name ThrowBox, "res://addons/collision_box/throw_box.png"

export var _c_Throw_Data = 0
export var throw_state = ""

func activate():
	.activate()
	priority = 9999
	spawn_particle_effect = false
	throw = true
