extends DefaultFireball

const ROTATE_AMOUNT = 22.5
const HOMING_FORCE = "0.25"
const BLOCK_HITS = 5
const MIN_RATIO = "0.5"
const FRAMES_PER_DAMAGE_LOSS = 5
const GRACE_PERIOD = 20
#const ARC_FORCE = "0.15"
onready var hitbox = $Hitbox
onready var hitbox_width = hitbox.width
onready var hitbox_height = hitbox.height
onready var hitbox_damage = hitbox.damage

onready var hurtbox = $"../../Hurtbox"
onready var hurtbox_width = hurtbox.width
onready var hurtbox_height = hurtbox.height

var block_hits = BLOCK_HITS

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

func on_got_blocked():
	block_hits -= 1
	if block_hits == 0:
		fizzle()
	
func _tick():
	._tick()
	host.sprite.rotation += deg2rad(ROTATE_AMOUNT) * host.get_facing_int()

	var vel = host.get_vel()
	var dir = fixed.normalized_vec(vel.x, vel.y)
	
	var tick = Utils.int_max(current_tick - GRACE_PERIOD, 0)
	
	var size_ratio = fixed.add(MIN_RATIO, fixed.mul(fixed.sub("1", fixed.div(str(tick), str(lifetime - GRACE_PERIOD))), fixed.sub("1", MIN_RATIO)))
	if fixed.lt(size_ratio, MIN_RATIO):
		size_ratio = MIN_RATIO

	host.sprite.scale.x = float(size_ratio)
	host.sprite.scale.y = float(size_ratio)

	if hitbox:
		hitbox.dir_x = dir.x
		hitbox.dir_y = dir.y
		hitbox.width = fixed.round(fixed.mul(str(hitbox_width), size_ratio))
		hitbox.height = fixed.round(fixed.mul(str(hitbox_height), size_ratio))
		hitbox.knockback = fixed.vec_len(vel.x, vel.y)
		hitbox.knockback = fixed.mul(hitbox.knockback, "0.5")
		hitbox.damage = hitbox_damage - tick / FRAMES_PER_DAMAGE_LOSS

	if hurtbox:
		hurtbox.width = fixed.round(fixed.mul(str(hurtbox_width), size_ratio))
		hurtbox.height = fixed.round(fixed.mul(str(hurtbox_height), size_ratio))

#	var arc_dir = fixed.rotate_vec(dir.x, dir.y, host.fixed_deg_to_rad(-45 if fixed.gt(vel.y, "0") else 45))
#	arc_dir = fixed.vec_mul(arc_dir.x, arc_dir.y, str(host.get_facing_int()))
#	var arc_force = fixed.vec_mul(arc_dir.x, arc_dir.y, ARC_FORCE)
#	host.apply_force(arc_force.x, arc_force.y)
	
	host.apply_forces_no_limit()

func fizzle():
	spawn_particle_relative(particle_scene, Vector2())
	.fizzle()
