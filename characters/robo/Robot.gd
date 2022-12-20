extends Fighter

const MAX_ARMOR_PIPS = 1
const FLY_SPEED = "8"
const FLY_TICKS = 20

var armor_pips = 0
var landed_move = false
var flying_dir = null
var fly_ticks_left = 0
var kill_process_super_level = 0

onready var chainsaw_arm = $"%ChainsawArm"

onready var chainsaw_arm_ghosts = [

]

func _ready():
	chainsaw_arm.set_material(sprite.get_material())
	for ghost in chainsaw_arm_ghosts:
		ghost.set_material(sprite.get_material())

func init(pos=null):
	.init(pos)
	armor_pips = 0

func on_got_hit():
	if armor_pips > 0:
		armor_pips -= 1

func has_armor():
	return armor_pips > 0

func incr_combo():
	if combo_count == 0:
		landed_move = true
	.incr_combo()
	pass

func apply_grav():
	if flying_dir == null:
		.apply_grav()

func big_landing_effect():
	spawn_particle_effect_relative(preload("res://fx/LandingParticle.tscn"))
	play_sound("BigLanding")
	var camera = get_camera()
	if camera:
		camera.bump(Vector2.UP, 10, 20 / 60.0)

func tick():
	.tick()
	if landed_move:
		if not (current_state() is CharacterHurtState):
			armor_pips += 1
			if armor_pips > MAX_ARMOR_PIPS:
				armor_pips = MAX_ARMOR_PIPS
		landed_move = false
	if is_grounded():
		flying_dir = null
		stop_fly_fx()
	if flying_dir:
		if !is_grounded():
			var fly_vel = fixed.normalized_vec_times(str(flying_dir.x), str(flying_dir.y), FLY_SPEED)
			set_vel(fly_vel.x, fixed.mul(fly_vel.y, "0.66"))
			fly_ticks_left -= 1
			if fly_ticks_left <= 0:
				flying_dir = null
				stop_fly_fx()


func start_fly_fx():
	$"%FlyFx1".start_emitting()
	$"%FlyFx2".start_emitting()

func stop_fly_fx():
	$"%FlyFx1".stop_emitting()
	$"%FlyFx2".stop_emitting()

func process_extra(extra):
	.process_extra(extra)
	if extra.has("fly_dir") and !is_grounded():
		if extra.has("fly_enabled") and extra.fly_enabled and air_movements_left > 0:
			var same_dir = flying_dir == null or (flying_dir.x == extra.fly_dir.x and flying_dir.y == extra.fly_dir.y)
			if flying_dir == null or !same_dir:
				fly_ticks_left = FLY_TICKS
				air_movements_left -= 1
				start_fly_fx()
#			reset_momentum()
			flying_dir = extra.fly_dir
#		else:
#
#func on_state_started(state):
#	.on_state_started(state)
#	flying_states_left -= 1
#	if flying_states_left == 0:
#		flying_dir = null
	


#func launched_by(hitbox):
#	if armor_pips > 0:
#		hitlag_ticks = hitbox.victim_hitlag + (COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES if hitbox.counter_hit else 0)
#		hitlag_applied = hitlag_ticks
#		if hitbox.rumble:
#			rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
#
#		emit_signal("got_hit")
#		take_damage(hitbox.damage, hitbox.minimum_damage)
#		armor_pips -= 1
#	else:
#		.launched_by(hitbox)
