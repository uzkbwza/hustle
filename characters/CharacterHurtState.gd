extends CharacterState

class_name CharacterHurtState

const SMOKE_SPEED = "6.5"
const SMOKE_FREQUENCY = 1
const COUNTER_HIT_ADDITIONAL_HITSTUN_FRAMES = 5
const HITSTUN_DECAY_PER_HIT = 1

var counter = false

var hitbox

func _enter_tree():
	is_hurt_state = true

func init():
	.init()
	busy_interrupt_into.append("Nudge")

func _enter_shared():
	host.release_opponent()
	hitbox = data["hitbox"]
	host.z_index = -1
	if hitbox.disable_collision:
		host.colliding_with_opponent = false
#	host.chara.set_gravity(HIT_GRAV)
#	host.chara.set_max_fall_speed(HIT_FALL_SPEED)
	host.refresh_air_movements()
	host.state_interruptable = true
	host.busy_interrupt = true
	._enter_shared()

func _tick_shared():
	._tick_shared()
	if current_tick % SMOKE_FREQUENCY == 0:
		var vel = host.get_vel()
		if fixed.gt(fixed.vec_len(vel.x, vel.y), SMOKE_SPEED):
			spawn_particle_relative(preload("res://fx/KnockbackSmoke.tscn"), host.hurtbox_pos_relative_float())

func hitstun_modifier(hitbox):
	return (COUNTER_HIT_ADDITIONAL_HITSTUN_FRAMES if hitbox.counter_hit else 0) - ((HITSTUN_DECAY_PER_HIT * (host.opponent.combo_count) / 2) - 1)

func get_x_dir(hitbox):
	var x = fixed.mul(hitbox.dir_x, "-1" if hitbox.facing == "Left" else "1")
	if hitbox.reversible:
		var dir = Utils.int_sign(hitbox.pos_x - host.get_pos().x)
		var modifier = "1"
		if dir == -1 and hitbox.facing == "Left":
			modifier = "-1"
		if dir == 1 and hitbox.facing == "Right":
			modifier = "-1"
		x = fixed.mul(x, modifier)
	return x

func _on_hit_something(_obj, _hitbox):
	pass

func _exit_shared():
	host.z_index = 0
	._exit_shared()

func can_interrupt():
	return false
