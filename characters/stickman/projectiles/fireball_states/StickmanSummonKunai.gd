extends ObjectState

const Y_MODIFIER = "5.0"

const ENTER_DIR_X = "-0.45"
const ENTER_DIR_Y = "-1.0"
const ENTER_FORCE = "6.0"

const KICKBACK = "-2.0"

const SPREAD_DEGREES = 20

var stopped = false

func create_particle():
	spawn_particle_relative(preload("res://characters/stickman/projectiles/SummonParticle.tscn"))

func _frame_1():
	create_particle()

func _frame_0():
	host.stopped = false
	
	var y = fixed.mul(fixed.mul(str(data.y), Y_MODIFIER), "-1")
	var force = fixed.normalized_vec_times(ENTER_DIR_X, ENTER_DIR_Y, ENTER_FORCE)
	force.y = fixed.add(force.y, y)
	host.apply_force_relative(force.x, force.y)

func _frame_2():
	host.stopped = true

func _tick():
	var pos = host.get_pos()
	if(pos.x>=host.creator.stage_width-5 or pos.x<=5-host.creator.stage_width):
		host.set_pos((host.creator.stage_width-6)*sign(pos.x),pos.y)
	if host.stopped:
		host.apply_grav() 
		host.update_data()
		if fixed.ge(host.get_vel().y, "0"):
			host.set_vel(host.get_vel().x, "0")
	host.apply_fric()
	host.apply_forces()


func _frame_23():
	data.x = abs(data.x) * host.get_facing_int()
	host.stopped = false
	var kickback = fixed.normalized_vec_times(str(data.x), str(data.y), KICKBACK)
	host.apply_force_relative(kickback.x, kickback.y)
	for i in range(-2, 1):
		var dir = fixed.rotate_vec(str(data.x), str(data.y), fixed.deg2rad(str((i * host.get_facing_int()) * SPREAD_DEGREES)))
		dir.x = fixed.abs(dir.x)
		var kunai_data = { "dir": dir }
		host.spawn_object(preload("res://characters/stickman/projectiles/Kunai.tscn"), 0, 0, true, kunai_data)
	pass

func _frame_45():
	create_particle()
	terminate_hitboxes()
	host.sprite.hide()
	host.stop_particles()
	host.disabled = true
	if host.creator:
		host.creator.can_summon_kunai = true
