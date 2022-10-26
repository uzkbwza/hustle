extends BaseObj

class_name BaseProjectile

export var immunity_susceptible = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func disable():
	sprite.hide()
	disabled = true
	for hitbox in get_active_hitboxes():
		hitbox.deactivate()
	stop_particles()
