tool

extends Hitbox

class_name ThrowBox

export var _c_Throw_Data = 0
export var throw_state = ""
export var hits_aerial = false
export var hits_grounded = true

func activate():
	.activate()
	priority = 9999
	spawn_particle_effect = false
	throw = true
