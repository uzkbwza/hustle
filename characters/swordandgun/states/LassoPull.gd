extends CharacterState

const PULL_FORCE = "-10"
const MOVE_AMOUNT = "-5"
onready var hitbox = $Hitbox

func _frame_12():
	if host.objs_map.has(host.lasso_projectile):
		host.objs_map[host.lasso_projectile].disable()
		host.lasso_projectile = null

	var dir = xy_to_dir(data.x, data.y)
	hitbox.dir_x = fixed.mul(dir.x, str(host.get_facing_int()))
	hitbox.dir_y = dir.y
	hitbox.activate()
	var opp_pos = host.obj_local_center(host.opponent)
	hitbox.x = opp_pos.x
	hitbox.y = opp_pos.y
	host.release_opponent()
	hitbox.hit(host.opponent)
	var force = fixed.vec_mul(dir.x, dir.y, PULL_FORCE)
	var move_amount = fixed.vec_mul(dir.x, dir.y, MOVE_AMOUNT)
	host.apply_force(force.x, force.y)
	host.move_directly(move_amount.x, move_amount.y)

func _tick():
	if current_tick > 10:
		host.apply_fric()
		host.apply_grav()
		host.apply_forces()

func _exit():
	host.release_opponent()
	if host.objs_map.has(host.lasso_projectile):
		host.objs_map[host.lasso_projectile].disable()
		host.lasso_projectile = null
