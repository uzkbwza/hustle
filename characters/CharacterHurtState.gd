extends CharacterState

class_name CharacterHurtState

const SMOKE_SPEED = "6.5"
const SMOKE_FREQUENCY = 1
const COUNTER_HIT_ADDITIONAL_HITSTUN_FRAMES = 0
const HITSTUN_DECAY_PER_HIT = 1
const DI_BRACE_RATIO = "-0.25"
const IS_HURT_STATE = true

var brace = false
var guard_broken = false

enum BOUNCE {
	LEFT_WALL,
	RIGHT_WALL,
	NO_BOUNCE
}

var counter = false

var hitbox

func _enter_tree():
	is_hurt_state = true

func init():
	.init()
#	busy_interrupt_into.append("Nudge")

func _enter_shared():
	host.blocked_hitbox_plus_frames = 0
	brace = false
	host.feinting = false
	host.release_opponent()
	hitbox = data["hitbox"]
	host.z_index = -1
	if hitbox.disable_collision:
		host.colliding_with_opponent = false
#	host.chara.set_gravity(HIT_GRAV)
#	host.chara.set_max_fall_speed(HIT_FALL_SPEED)
	if host.penalty_ticks <= 0:
		host.refresh_air_movements()
	host.state_interruptable = true
	host.busy_interrupt = true
	host.clear_buffer()
	._enter_shared()

	host.brace_effect_applied_yet = true

func _tick_shared():
	._tick_shared()

	if current_tick < 5:
		host.release_opponent()
	if current_tick % SMOKE_FREQUENCY == 0:
		var vel = host.get_vel()
		if fixed.gt(fixed.vec_len(vel.x, vel.y), SMOKE_SPEED):
			spawn_particle_relative(preload("res://fx/KnockbackSmoke.tscn"), host.hurtbox_pos_relative_float())

func hitstun_modifier(hitbox):
	return (COUNTER_HIT_ADDITIONAL_HITSTUN_FRAMES if hitbox.counter_hit else 0)
#	return (COUNTER_HIT_ADDITIONAL_HITSTUN_FRAMES if hitbox.counter_hit else 0) - ((HITSTUN_DECAY_PER_HIT * (host.opponent.hitstun_decay_combo_count + Utils.int_max(host.combo_proration, 0)) / 2) - 1)

func global_hitstun_modifier(ticks):
	return fixed.round(fixed.mul(str(ticks), host.global_hitstun_modifier))

func brace_shave_hitstun(hitstun):
	return fixed.round(fixed.mul(str(hitstun), host.SUCCESSFUL_BRACE_HITSTUN_MODIFIER))

func di_shave_hitstun(hitstun, hitbox_dir_x, hitbox_dir_y):
#	var dir = xy_to_dir(host.current_di.x, host.current_di.y)
#	var hitbox_dir = fixed.normalized_vec(hitbox_dir_x, hitbox_dir_y)
#	var di_shave_amount = host.fixed_dot(dir.x, dir.y, hitbox_dir.x, hitbox_dir.y)
#	if fixed.ge(di_shave_amount, "0"):
#		di_shave_amount = "0"
#	else:
#		brace = true
#	hitstun -= fixed.round(fixed.mul(str(hitstun), fixed.mul(DI_BRACE_RATIO, di_shave_amount)))
	return hitstun

func get_vacuum_dir(hitbox):
	var pos_x = "0"
	var pos_y = "0"
	var hitbox_host = host.obj_from_name(hitbox.host)

	if hitbox_host:
		var my_pos = host.get_hurtbox_center()
		var diff = {x = hitbox.pos_x - my_pos.x, y = hitbox.pos_y - my_pos.y}
		var dir = fixed.normalized_vec(str(diff.x), str(diff.y))
		pos_x = dir.x
		pos_y = dir.y
#	pos_x = fixed.mul(pos_x, str(host.get_facing_int()))
	return {x = pos_x, y = pos_y}

func get_x_dir(hitbox):
	return host.get_hitbox_x_dir(hitbox)
#
#func _on_hit_something(_obj, _hitbox):
#	pass

func _exit_shared():
	host.z_index = 0
	brace = false
	host.hit_out_of_brace = false
	guard_broken = false
	host.start_sadness_immunity()
	._exit_shared()

func can_interrupt():
	return false
