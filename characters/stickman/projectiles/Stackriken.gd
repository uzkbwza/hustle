extends BaseProjectile

var return_x
var return_y
var force_x
var force_y

func init(pos=null):
	.init(pos)
	get_fighter().stackriken_out = true

func disable():
	get_fighter().stackriken_out = false
	.disable()

func hit_by(hitbox):
	.hit_by(hitbox)
	var host = obj_from_name(hitbox.host)
	if host:
		if host.is_in_group("Fighter"):
			current_state().spawn_particle_relative(current_state().particle_scene, Vector2())
			disable()
