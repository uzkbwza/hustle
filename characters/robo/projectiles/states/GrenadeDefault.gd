extends ObjectState

const BOUNCE_THRESHOLD = "2.0"
const BOUNCE_MULTIPLIER = "-0.7"

onready var hitbox = $Hitbox

var t = 0


func _frame_1():
	if !host.hitbox_out:
		hitbox.activate()
		host.hitbox_out = true
		hitbox.hit_objects.append(host.get_fighter().obj_name)

func _tick():
	var vel = host.get_vel()
	if host.is_grounded() and fixed.gt(host.last_vel_y, BOUNCE_THRESHOLD):
		host.set_vel(vel.x, fixed.mul(host.last_vel_y, BOUNCE_MULTIPLIER))
		host.play_sound("Bounce")
	var speed = (fixed.vec_len(vel.x, vel.y))
	if current_tick > 10 and fixed.lt(speed, "5"):
		if state_name != "Default":
			return "Default"
	var pos = host.get_pos()
	if Utils.int_abs(pos.x) >= host.stage_width:
		host.set_vel(fixed.mul(fixed.abs(vel.x), str(Utils.int_sign(pos.x) * -1)), vel.y)
		host.play_sound("Bounce")
	host.last_vel_x = vel.x
	host.last_vel_y = vel.y
	host.set_facing(fixed.sign(vel.x) if fixed.sign(vel.x) != 0 else host.get_facing_int())
	hitbox.dir_x = fixed.mul(vel.x, str(host.get_facing_int()))
	hitbox.dir_y = vel.y

func update_sprite_frame():
	if !host.sprite.frames.has_animation(anim_name):
		return
	if host.sprite.animation != anim_name:
		host.sprite.animation = anim_name
		host.sprite.frame = 0
	var vel = host.get_vel()
	var speed = fixed.round(fixed.vec_len(vel.x, vel.y))
	t += speed
	if t > 8:
		t -= 8
		host.sprite.frame = (host.sprite.frame + 1) % sprite_anim_length

func _on_hit_something(obj, hitbox):
	if host.active:
		host.explode()
