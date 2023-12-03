extends Fighter

class_name Mutant

const INSTALL_TICKS = 120
const JUKE_PIPS = 10
const JUKE_PIPS_PER_USE = 2
const JUKE_TICKS = 3
const UP_JUKE_TICKS = 15
const NEUTRAL_JUKE_TICKS = 6
const SIDE_JUKE_TICKS = 4
const UP_JUKE_DOWN_FORCE = "5"
const UP_JUKE_GRAVITY = "-0.65"
const JUKE_SPEED = "12"
const BACK_JUKE_SPEED = "2"
const MAX_BACK_SPEED_FOR_JUKE = "6"

onready var twist_attack_sprite = $"%TwistAttackSprite"
onready var rebirth_particle_effect = $"%RebirthParticleEffect"

var install_ticks = 0
var shockwave_projectile = null
var spike_projectile = null

var juke_pips = JUKE_PIPS / 4
var juke_dir_x = "0"
var juke_dir_y = "0"
var juke_ticks = 0
var juke_dir_type = ""

func apply_grav():
	if juke_ticks > 0:
		pass
	else:
		.apply_grav()

func apply_grav_custom(grav, fall_speed):
	if juke_ticks > 0:
		pass
	else:
		.apply_grav_custom(grav, fall_speed)

func start_rebirth_fx():
	rebirth_particle_effect.start()
	rebirth_particle_effect.show()

func stop_rebirth_fx():
	rebirth_particle_effect.stop_emitting()
	rebirth_particle_effect.hide()

func process_extra(extra):
	.process_extra(extra)
	if extra.has("spike_enabled"):
		var obj = obj_from_name(spike_projectile)
		if obj:
			if !extra.spike_enabled:
				obj.disable()
	var juke_dir = extra.get("juke_dir")
	var invalid_juke_states = ["DashBackward"]
	if !(queued_action in invalid_juke_states):
		if juke_dir != null:
			juke_dir_x = str(juke_dir.x)
			juke_dir_y = str(juke_dir.y)
#			move_directly(juke_dir_x, juke_dir_y)
			juke_ticks = JUKE_TICKS
			create_speed_after_image_from_style()
			if fixed.eq(juke_dir_x, "0"):
				if fixed.eq(juke_dir_y, "1"):
					juke_dir_type = "Down"
				if fixed.eq(juke_dir_y, "-1"):
					juke_dir_type = "Up"
					set_vel(fixed.mul(get_vel().x, "0.75"), "0")
					juke_ticks = UP_JUKE_TICKS
					use_air_movement()
					apply_force("0", UP_JUKE_DOWN_FORCE)
				if fixed.eq(juke_dir_y, "0"):
					juke_dir_type = "Neutral"
					juke_ticks = NEUTRAL_JUKE_TICKS
			elif fixed.eq(juke_dir_x, "1"):
					juke_dir_type = "Forward" if get_opponent_dir() == 1 else "Back"
					juke_ticks = SIDE_JUKE_TICKS
			elif fixed.eq(juke_dir_x, "-1"):
					juke_dir_type = "Back" if get_opponent_dir() == 1 else "Forward"
					juke_ticks = SIDE_JUKE_TICKS
			add_juke_pips(-JUKE_PIPS_PER_USE)
#			create_speed_after_image_from_style()
			play_sound("Juke")
			play_sound("Juke2")


func init(pos=null):
	.init(pos)
	twist_attack_sprite.material = sprite.get_material()

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	add_juke_pips(1)

func on_got_blocked():
	.on_got_blocked()
	add_juke_pips(1)
	

func add_juke_pips(amount: int):
	juke_pips += amount
	juke_pips = Utils.int_clamp(juke_pips, 0, JUKE_PIPS)

func copy_to(f):
	.copy_to(f)
	f.juke_dir_type = juke_dir_type
	f.juke_ticks = juke_ticks

func tick():

	if twist_attack_sprite.visible: 
		twist_attack_sprite.frame = (twist_attack_sprite.frame + 1) % twist_attack_sprite.frames.get_frame_count("default")
	if juke_ticks > 0 and hitlag_ticks <= 0 and blockstun_ticks <= 0:
		spawn_particle_effect_relative(preload("res://characters/mutant/JukeEffect.tscn"), Vector2(0, -16))
		juke_ticks -= 1
		if juke_dir_type == "Forward" or juke_dir_type == "Back":
#			if juke_dir_type == "Back" and fixed.sign(get_vel().x) != get_opponent_dir() and fixed.ge(fixed.abs(get_vel().x), MAX_BACK_SPEED_FOR_JUKE):
#				move_directly(fixed.mul(juke_dir_x, BACK_JUKE_SPEED), "0")
			if juke_ticks <= JUKE_TICKS:
				move_directly(fixed.mul(juke_dir_x, JUKE_SPEED), "0")
			elif juke_ticks == JUKE_TICKS + 1:
				create_speed_after_image_from_style()
		if juke_dir_type == "Down":
			move_directly("0", fixed.mul(juke_dir_y, JUKE_SPEED))
		if juke_dir_type == "Neutral":
			reset_momentum()
		if juke_dir_type == "Up" and current_state().get("IS_JUMP") == null and !(current_state() is ThrowState):
#			if "Landing" in current_state().state_name:
#				juke_ticks = 0
#				set_vel(get_vel().x, "0")
#				if get_pos().y > -2:
#					set_pos(get_pos().x, 0)
#			else:
				apply_force("0", UP_JUKE_GRAVITY)
	if infinite_resources:
		juke_pips = JUKE_PIPS
	.tick()
