extends WizardState

onready var hitbox = $Hitbox

const MAX_DISTANCE = "120"
const MIN_DISTANCE = "30"

var hitbox_x

# control where the strike goes
# if it hits behind enemy, it sends them toward you
#
#func _frame_3():
#	var dir = xy_to_dir(data["x"], 0, "1.0")
#	dir.x = fixed.add(dir.x, "1.0")
#	dir.x = fixed.div(dir.x, "2.0")
##	dir.x = fixed.mul(dir.x, str(host.get_facing_int()))
#	hitbox_x = fixed.round(fixed.add(fixed.mul(dir.x, fixed.sub(MAX_DISTANCE, MIN_DISTANCE)), MIN_DISTANCE)) * host.get_facing_int()
#	hitbox.x = Utils.int_abs(hitbox_x)

func _tick():
	if current_tick == 5:
		host.update_data()
		var dir = xy_to_dir(data["x"], 0, "1.0")
		dir.x = fixed.add(dir.x, "1.0")
		dir.x = fixed.div(dir.x, "2.0")
	#	dir.x = fixed.mul(dir.x, str(host.get_facing_int()))
		hitbox_x = fixed.round(fixed.add(fixed.mul(dir.x, fixed.sub(MAX_DISTANCE, MIN_DISTANCE)), MIN_DISTANCE)) * host.get_facing_int()
		hitbox.x = Utils.int_abs(hitbox_x)
	if current_tick == 5:
		spawn_particle_relative(particle_scene, Vector2(hitbox_x, hitbox.y))
#
#func _frame_5():
#	pass
