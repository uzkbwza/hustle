extends DefaultFireball

const ROTATE_AMOUNT = 22.5
const HOMING_FORCE = "0.25"
#const ARC_FORCE = "0.15"
onready var hitbox = $Hitbox


func _frame_1():
	var fighter = host.get_fighter()
	if fighter:
		host.return_x = fighter.get_pos().x
		host.return_y = fighter.get_pos().y
	host.apply_force(host.force_x, host.force_y)

func move():
	if host.return_x != null and host.return_y != null:
		var my_pos = host.get_pos()

		var dir = fixed.normalized_vec(str(host.return_x - my_pos.x), str(host.return_y - my_pos.y))
#		if fighter.get_pos().y > host.get_pos().y:
#			if fixed.lt(dir.y, "0"):
#				dir.y = fixed.mul(dir.y, "-1")
		var force = fixed.vec_mul(dir.x, dir.y, HOMING_FORCE)
		host.apply_force(force.x, force.y)


func _tick():
	._tick()
	host.sprite.rotation += deg2rad(ROTATE_AMOUNT) * host.get_facing_int()

	var vel = host.get_vel()
	var dir = fixed.normalized_vec(vel.x, vel.y)
	if hitbox:
		hitbox.dir_x = dir.x
		hitbox.dir_y = dir.y
		hitbox.knockback = fixed.vec_len(vel.x, vel.y)
		hitbox.knockback = fixed.mul(hitbox.knockback, "0.5")
#
#	var arc_dir = fixed.rotate_vec(dir.x, dir.y, host.fixed_deg_to_rad(-45 if fixed.gt(vel.y, "0") else 45))
#	arc_dir = fixed.vec_mul(arc_dir.x, arc_dir.y, str(host.get_facing_int()))
#	var arc_force = fixed.vec_mul(arc_dir.x, arc_dir.y, ARC_FORCE)
#	host.apply_force(arc_force.x, arc_force.y)
	
	host.apply_forces_no_limit()

func fizzle():
	spawn_particle_relative(particle_scene, Vector2())
	.fizzle()
