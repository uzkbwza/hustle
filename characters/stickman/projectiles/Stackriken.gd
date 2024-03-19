extends BaseProjectile

const REFRESH_AMOUNT = 24

var return_x
var return_y
var force_x
var force_y

var refresh_amount = REFRESH_AMOUNT

onready var hitbox = $Hitbox

func init(pos=null):
	.init(pos)
	var fighter = get_fighter()
	if fighter:
		get_fighter().stackriken_out = true
	refresh_amount = REFRESH_AMOUNT

func disable():
	get_fighter().stackriken_out = false
	.disable()

func hit_by(hitbox):
	.hit_by(hitbox)
	if hitbox.throw:
		return
	var host = obj_from_name(hitbox.host)
	if host:
		if host.is_in_group("Fighter"):
			current_state().spawn_particle_relative(current_state().particle_scene, Vector2())
#			disable()
			var force = fixed.normalized_vec_times(get_hitbox_x_dir(hitbox), hitbox.dir_y, fixed.mul(hitbox.knockback, "0.85"))
			var fighter = get_fighter()
			if fighter and id == hitbox.id:
				force = fixed.vec_add(force.x, force.y, str(fighter.current_di.x/20), str(fighter.current_di.y/20))
			set_vel(force.x, force.y)
			current_state().current_tick -= refresh_amount
			if current_state().current_tick <= 0:
				current_state().current_tick = 0
			refresh_amount -= 3
			if refresh_amount < 0:
				refresh_amount = 0

func refresh():
	current_state().current_tick -= current_state().lifetime
	if current_state().current_tick <= 0:
		current_state().current_tick = 1
	current_state().spawn_particle_relative(current_state().particle_scene, Vector2())
