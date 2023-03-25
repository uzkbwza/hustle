extends BaseProjectile

const LIFETIME = 900
const ACTIVATE_TIME = 30
const EXPLOSION = preload("res://characters/robo/projectiles/NadeExplosion.tscn")

onready var my_hitbox = $StateMachine/Active/Hitbox
onready var active_indicator = $Flip/ActiveIndicator

var last_vel_x
var last_vel_y

var active = false

var ticks_left = LIFETIME

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func tick():
	.tick()
	ticks_left -= 1
	if ticks_left <= 0:
		explode()
	elif ticks_left <= ACTIVATE_TIME:
		activate()

func activate():
	if active:
		return
	ticks_left = Utils.int_min(ticks_left, ACTIVATE_TIME)
	play_sound("Beep")
	active = true
	my_hitbox.increment_combo = false

func _process(delta):
	if active and !disabled:
		active_indicator.visible = Utils.pulse(0.064, 0.5)

func explode():
	disable()
	spawn_object(EXPLOSION, 0, -8)

func hit_by(hitbox):
	.hit_by(hitbox)
	if hitbox:
		reset_momentum()
		var dir = fixed.normalized_vec_times(get_hitbox_x_dir(hitbox), hitbox.dir_y, fixed.mul(hitbox.knockback, "1.6"))
		if is_grounded() and fixed.gt(dir.y, "0"):
			dir.y = fixed.mul(dir.y, "-1")
		change_state("Active")
		apply_force(dir.x, dir.y)
		var host = hitbox.host
		if host:
			my_hitbox.hit_objects.append(host)
	emit_signal("got_hit")

func disable():
	.disable()
	active_indicator.hide()
	creator.grenade_object = null
