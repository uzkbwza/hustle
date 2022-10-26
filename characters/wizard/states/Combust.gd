extends WizardState

onready var hitbox = $Hitbox

const KICKBACK_X = "-3.0"
const KICKBACK_Y = "-2.0"

func _frame_8():
	spawn_particle_relative(particle_scene, Vector2(hitbox.x * host.get_facing_int(), hitbox.y))
	host.apply_force_relative(KICKBACK_X, KICKBACK_Y)
