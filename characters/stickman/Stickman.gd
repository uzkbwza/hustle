extends Fighter
var can_summon_kunai = true
var can_summon_kick = true
var bomb_thrown = false
var bomb_projectile = null
var momentum_stores = 0
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
var stored_speed_1 = "1"
var stored_speed_2 = "1"
var stored_speed_3 = "1"
var released_this_turn = false
var will_release_momentum = false
var will_store_momentum = false
var boosted_during_combo = false
var current_momentum = "0"
var boost_frames_left = 0

const RELEASE_MODIFIER = "1.175"
const HOOK_DISABLE_DIST = "32"
const HOOK_PULL_SPEED = "3"
const MAX_PULL_SPEED = "15"
const MAX_PULL_UPWARD_SPEED = "-10"
const MAX_MOMENTUM_UPWARD_SPEED = "-10"
const BACKWARD_PULL_PENALTY = 2
const SKULL_SHAKER_BLEED_TICKS = 80
const SKULL_SHAKER_BLEED_DAMAGE = 2
const BOOST_MIN_FRAMES = 10

func init(pos=null):
	.init(pos)
	if infinite_resources:
		momentum_stores = 3

func explode_sticky_bomb():
	if bomb_thrown and obj_from_name(bomb_projectile):
		objs_map[bomb_projectile].explode()


func on_roll_started():
	detach()

func process_extra(extra):
	var vel = get_vel()
	current_momentum = fixed.vec_len(vel.x, vel.y)
	.process_extra(extra)
	if extra.has("explode"):
		if extra["explode"]:
			explode_sticky_bomb()
	if extra.has("pull"):
		pulling = extra.pull
	if extra.has("detach"):
		if extra.detach:
			detach()

	if extra.has("release"):
		if extra.release:
			if extra.has("release_dir"):
				will_release_momentum = true
				var dir = extra.release_dir
				var stored_speed = "0"
				match momentum_stores:
					1:
						stored_speed = stored_speed_1
					2:
						stored_speed = stored_speed_2
					3:
						stored_speed = stored_speed_3
				var impulse = xy_to_dir(dir.x, dir.y, fixed.mul(RELEASE_MODIFIER, stored_speed))
				stored_momentum_x = impulse.x
				stored_momentum_y = impulse.y
				if fixed.lt(stored_momentum_y, "0"):
					if fixed.lt(fixed.add(get_vel().y, stored_momentum_y), MAX_MOMENTUM_UPWARD_SPEED):
						set_vel(vel.x, "0")
						stored_momentum_y = MAX_MOMENTUM_UPWARD_SPEED
				super_effect(2)
				use_super_bar()
	if extra.has("store"):
		will_store_momentum = extra.store

func apply_forces():
	if released_this_turn:
		apply_forces_no_limit()
	else:
		.apply_forces()
	pass

func store_momentum():
		var speed = current_momentum
		var stored_speed = speed
		if infinite_resources and fixed.lt(stored_speed, "11"):
			stored_speed = "11"
#		print(stored_speed)
		reset_momentum()
		momentum_stores += 1
		if momentum_stores > 3:
			momentum_stores = 3
		match momentum_stores:
			1:
				stored_speed_1 = stored_speed
			2:
				stored_speed_2 = stored_speed
			3:
				stored_speed_3 = stored_speed

		will_store_momentum = false
		play_sound("Swish3")
		spawn_particle_effect_relative(preload("res://characters/stickman/ReleaseMomentumEffect.tscn"), Vector2(0, -16))

func release_momentum():
#		reset_momentum()
		var can_boost_vert = !is_grounded()
		if current_state().get_node_or_null("AirBoost") != null:
			can_boost_vert = true
		apply_force(stored_momentum_x, stored_momentum_y if !is_grounded() else "0")
		if !infinite_resources:
			momentum_stores -= 1
		if momentum_stores < 0:
			momentum_stores = 0

		released_this_turn = true
		will_release_momentum = false
		play_sound("Swish2")
		if combo_count > 0:
			boosted_during_combo = true
			combo_count += 1
		spawn_particle_effect_relative(preload("res://characters/stickman/StoreMomentumEffect.tscn"), Vector2(0, -16))
		colliding_with_opponent = false
#		super_effect(2)
#		use_super_bar()

func reset_combo():
	.reset_combo()
	boosted_during_combo = false

func detach():
	var hook = obj_from_name(grappling_hook_projectile)
	if hook:
		hook.disable()

func apply_grav():
	if previous_state() and previous_state().name == "AirDash":
		if !(current_state() is CharacterHurtState):
			if turn_frames <= 7:
				return
	.apply_grav()

func tick():
	.tick()
	if turn_frames <= 1 and boost_frames_left <= 0:
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
		if skull_shaker_bleed_ticks % 8 == 0:
			opponent.take_damage(SKULL_SHAKER_BLEED_DAMAGE, 0, "0.25")
	
	if will_release_momentum and turn_frames == 1:
		release_momentum()

	if will_store_momentum and turn_frames == 2:
		store_momentum()

	if released_this_turn:
#	if released_this_turn and turn_frames % 1 == 0:
		var color = style_extra_color_2 if (style_extra_color_2 and applied_style)  else extra_color_2
		color.a = 0.5
		create_speed_after_image(color)

	if is_grounded():
		used_grappling_hook = false

func on_got_parried():
	.on_got_parried()
	if released_this_turn:
		hitlag_ticks +=  20
	pass

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
