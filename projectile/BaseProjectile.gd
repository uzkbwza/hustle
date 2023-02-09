extends BaseObj

signal got_parried()

class_name BaseProjectile

export var immunity_susceptible = true
export var deletes_other_projectiles = true
export var fizzle_on_ceiling = false
export var movable = true
export var can_be_hit_by_melee = false
#export var can_be_hit_by_projectiles = false
export var projectile_immune = false

var got_parried = false

var stopped = false

func _ready():
	state_variables.append_array(
		["got_parried", ]
	)

func get_opponent():
	if creator:
		return creator.get_opponent()

func disable():
	sprite.hide()
	disabled = true
	for hitbox in get_active_hitboxes():
		hitbox.deactivate()
	stop_particles()

func on_got_parried():
	emit_signal("got_parried")

func on_hit_ceiling():
	if fizzle_on_ceiling:
		disable()
