extends Fighter
var can_summon_kunai = true
var can_summon_kick = true
var bomb_thrown = false
var bomb_projectile = null
var storing_momentum = false
var stored_momentum_x = ""
var stored_momentum_y = ""
var sticky_bombs_left = 3
var quick_slash_start_pos_x = 0
var quick_slash_start_pos_y = 0
var quick_slash_move_dir_x = "0"
var quick_slash_move_dir_y = "0"
var grappling_hook_projectile = null
var pulling = false
var used_grappling_hook = false
var whip_beam_charged = false
var substituted_objects = {}
var skull_shaker_bleed_ticks = 0
var stored_speed = "0"
var released_this_turn = false
var will_release_momentum = false

#var hook_dir = Vector2()

const RELEASE_MODIFIER = "1.35"
const HOOK_DISABLE_DIST = "32"
const HOOK_PULL_SPEED = "3"
const MAX_PULL_SPEED = "15"
const MAX_PULL_UPWARD_SPEED = "-10"
const BACKWARD_PULL_PENALTY = 2
const SKULL_SHAKER_BLEED_TICKS = 70
const SKULL_SHAKER_BLEED_DAMAGE = 10

func explode_sticky_bomb():
	if bomb_thrown and obj_from_name(bomb_projectile):
		objs_map[bomb_projectile].explode()

func process_extra(extra):
	.process_extra(extra)
	if extra.has("explode"):
		if extra["explode"]:
			explode_sticky_bomb()
	if extra.has("pull"):
		pulling = extra.pull
	if extra.has("detach"):
		if extra.detach:
			detach()
	
	will_release_momentum = false
	if extra.has("release"):
		if extra.release:
			if extra.has("release_dir"):
				will_release_momentum = true
				var dir = extra.release_dir
				var impulse = xy_to_dir(dir.x, dir.y, fixed.mul(RELEASE_MODIFIER, stored_speed))
				stored_momentum_x = impulse.x
				stored_momentum_y = impulse.y
				if fixed.lt(stored_momentum_y, "0"):
					var vel = get_vel()
					set_vel(vel.x, "0")
					stored_momentum_y = fixed.mul(stored_momentum_y, "0.5")

func apply_forces():
	if released_this_turn:
		apply_forces_no_limit()
	else:
		.apply_forces()
	pass

func release_momentum():
#		reset_momentum()
		apply_force(stored_momentum_x, stored_momentum_y)
		storing_momentum = false
		released_this_turn = true
		will_release_momentum = false
		play_sound("Swish2")
		spawn_particle_effect_relative(preload("res://characters/stickman/ReleaseMomentumEffect.tscn"), Vector2(0, -16))

func detach():
	var hook = obj_from_name(grappling_hook_projectile)
	if hook:
		hook.disable()

func tick():
	.tick()
	if turn_frames == 1:
		released_this_turn = false
	var hook = obj_from_name(grappling_hook_projectile)
	if is_in_hurt_state():
		pulling = false
	if hook:
		if is_in_hurt_state(false):
			hook.disable()
		var attached_to = obj_from_name(hook.attached_to)
		var hook_pos = obj_local_center(hook) if attached_to == null else obj_local_center(attached_to)
		if hook.is_locked and hook.current_state().current_tick > 5 and fixed.lt(fixed.vec_len(str(hook_pos.x), str(hook_pos.y)), HOOK_DISABLE_DIST):
			hook.disable()
		if pulling:
			var dir = fixed.normalized_vec_times(str(hook_pos.x), str(hook_pos.y), HOOK_PULL_SPEED)
#			hook_dir = Vector2(float(dir.x), float(dir.y))
			apply_force(dir.x, dir.y)
			limit_speed(MAX_PULL_SPEED)
			var vel = get_vel()
			if fixed.lt(vel.y, MAX_PULL_UPWARD_SPEED):
				set_vel(vel.x, MAX_PULL_UPWARD_SPEED)
			if fixed.sign(dir.x) != get_opponent_dir() and combo_count <= 0:
				add_penalty(BACKWARD_PULL_PENALTY)
	else:
		pulling = false
	
	if skull_shaker_bleed_ticks > 0:
		skull_shaker_bleed_ticks -= 1
		if skull_shaker_bleed_ticks % 10 == 0:
			opponent.take_damage(SKULL_SHAKER_BLEED_DAMAGE, 0, "0.25")
	
	if will_release_momentum and current_state().current_tick == 1:
		release_momentum()

	if released_this_turn:
#	if released_this_turn and turn_frames % 1 == 0:
		create_speed_after_image(Color("99ff333d"))

	if is_grounded():
		used_grappling_hook = false

func on_got_hit():
	if bomb_projectile or bomb_thrown:
		bomb_thrown = false
		var bomb_object = obj_from_name(bomb_projectile)
		if bomb_object:
			bomb_object.disable()
		bomb_projectile = null

func stack_move_in_combo(move_name):
	.stack_move_in_combo(move_name)
	if combo_moves_used.has("PalmStrike") and combo_moves_used["PalmStrike"] >= 3:
		unlock_achievement("ACH_STERNUM_EXPLODER")

func _draw():
	var hook = obj_from_name(grappling_hook_projectile)
	if hook:
		draw_line(to_local(get_center_position_float()), to_local(hook.get_center_position_float()), Color("#ffffff"), 2.0)
#	if hook_dir:
#		draw_line(to_local(get_center_position_float()), hook_dir * 32, Color.purple)
