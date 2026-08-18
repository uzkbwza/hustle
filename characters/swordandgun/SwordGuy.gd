extends Fighter

class_name Cowboy

signal bullet_used()

export(Texture) var epic_horse_moment

onready var shooting_arm = $"%ShootingArm"
const FORESIGHT = preload("res://characters/swordandgun/projectiles/AfterImage.tscn")
const BARREL_LOCATION_X = "26"
const BARREL_LOCATION_Y = "-5"
const GUN_PICKUP_DISTANCE = "26"
const GUN_PICKUP_DISTANCE_BOOMERANG = "32"
const IS_COWBOY = true # lol
const RIFT_PROJECTILE = preload("res://characters/swordandgun/projectiles/AfterImageExplosion.tscn")
const AFTER_IMAGE_MAX_DIST = "410"
const MAX_AIR_SPEED_1KCUTS = "12"
const CUTS_METER_DRAIN_1 = 3
const DRIFT_JUMP_TIMER = 4
const CUTS_METER_DRAIN_2 = 3
const DRIFT_SUPERS = 1
const GROUNDED_DRIFT_JUMP_SPEED = "-3"
const CUTS_EFFECT = preload("res://characters/swordandgun/projectiles/1000CutsEffect.tscn")
var bullets_left = 6
var cut_projectile = null
var lasso_projectile = null
var after_image_object = null
var used_aerial_h_slash = false
var used_aerial_l_slice = false
# One-per-combo gate for LightningSlice's ground bounce. Set true when LS
# connects on a fighter; LightningSlice._frame_0 reads this to disable
# air_ground_bounce on subsequent hits in the same combo. Reset by
# reset_combo() below — matches main-branch's "once per combo" buff.
var lightning_slice_ground_bounced = false
var has_gun = true
var gun_projectile = null
var consecutive_shots = 1
var shot_dir_x = 100
var shot_dir_y = 0
var lightning_slice_x = 0
var lightning_slice_y = 0
var up_swipe_momentum = true
var buffer_bullet_cancelling = false
var bullet_cancelling = false
var stance_teleport_x = 0
var detonating = false
var shifting = false
var temporal_round = null
# Count of Cowboy's own NewTimeBullets currently in play. Incremented by
# TemporalRoundDefault when it spawns the bullet; decremented by
# NewBullet.disable when the bullet's `is_time_bullet` flag is set and its
# creator is this Cowboy. Keeps gain_super_meter O(1) instead of walking
# objs_map every call.
var active_time_bullets: int = 0
var drift_effect = false
var fatal_cut_move_dir_x = 0
var fatal_cut_move_dir_y = 0
var fatal_cut_start_pos_x = 0
var fatal_cut_start_pos_y = 0
var drift_jump_timer = 0

var shifted_this_frame = false
var shifted_last_frame = false
var stance_teleport_y = 0
var ticks_until_time_shift = 0
var lasso_parried = false
var default_max_air_speed = "9"
var milk_toggled = false
var milk_toggle_tick = 0

var shifted_this_turn = false

func _ready():
	shooting_arm.set_material(sprite.get_material())
	material = null

# When the gun-shoot arm sprite is visible, redirect hand limb lookups to it
# so auras attached to the hands track the arm's gun_shoot_arm*.png frames
# instead of the main body sprite (which doesn't include the arms).
func get_current_limb_sprite_node_for(limb_name: String):
	if (limb_name == "LeftHand" or limb_name == "RightHand") and shooting_arm and shooting_arm.visible:
		return shooting_arm
	return .get_current_limb_sprite_node_for(limb_name)



func init(pos=null):
	if randi() % 65536 == 0:
		border_portrait = epic_horse_moment
	.init(pos)
	bullets_left = 6
	HOLD_FORCE_STATES["QuickerDraw"] = "SlowHolster"
	HOLD_RESTARTS.append("DashForward1k")

func copy_to(f):
	.copy_to(f)
	f.bullet_cancelling = bullet_cancelling

func get_barrel_location(angle, modifier="1.0"):
	var vec = fixed.rotate_vec(BARREL_LOCATION_X, BARREL_LOCATION_Y, angle)
	var barrel_location = fixed.vec_mul(vec.x, vec.y, modifier)
	barrel_location.y = fixed.sub(barrel_location.y, "24")
	return barrel_location

func shift():
	if opponent.combo_count > 0:
		return
	var obj = obj_from_name(after_image_object)
	
	if obj:
		set_pos(obj.get_pos().x, obj.get_pos().y)

		obj.disable()
		after_image_object = null
		shifted_this_frame = true
		if obj.get_pos().y >= 0:
			set_vel(get_vel().x, "0")
		if combo_count <= 0:
			add_penalty(15)

func gain_super_meter(amount, stale_amount = "1.0"):
	# 1000 Cuts (cut_projectile) halves meter gain ONLY during a combo (either
	# side comboing) — neutral meter builds at full rate while installed.
	if obj_from_name(cut_projectile) and (combo_count > 0 or opponent.combo_count > 0):
		amount = fixed.round(fixed.mul(str(amount), "0.5"))
	# The time-projectile penalty fires while any of Cowboy's own time
	# objects are alive — the frozen-round itself OR any NewTimeBullets
	# his temporal_round spawned. Without _has_active_time_bullet the
	# penalty stopped the moment the frozen round fired its bullet, even
	# though that bullet was still in play.
	if obj_from_name(temporal_round) or _has_active_time_bullet():
		amount = fixed.round(fixed.mul(str(amount), "0.75"))

	.gain_super_meter(amount, stale_amount)

func _has_active_time_bullet() -> bool:
	return active_time_bullets > 0

# Called from TemporalRoundDefault when a NewTimeBullet spawns, and from
# NewBullet.disable when one disables. Counter approach so gain_super_meter
# doesn't have to walk every object in the match.
func _register_time_bullet():
	active_time_bullets += 1

func _unregister_time_bullet():
	active_time_bullets -= 1
	if active_time_bullets < 0:
		active_time_bullets = 0

func start_1k_cuts_buff():
	max_air_speed = MAX_AIR_SPEED_1KCUTS
	chara.set_max_air_speed(MAX_AIR_SPEED_1KCUTS)

func end_1k_cuts_buff():
	max_air_speed = default_max_air_speed
	spawn_particle_effect_relative(CUTS_EFFECT, Vector2(0, -16))
	chara.set_max_air_speed(default_max_air_speed)

func tick():
	if after_image_object:
		var obj = obj_from_name(after_image_object)
		if obj:
			if detonating:
				detonating = false
				obj.detonating = true
			else:
				if fixed.gt(distance_to(obj), AFTER_IMAGE_MAX_DIST):
					obj.detonating = true
			if shifting and current_state().state_name != "Shift":
				set_grounded(obj.is_grounded())
				if !obj.is_grounded():
					move_directly(0, -1)
				shifted_this_turn = true
				change_state("Shift")
			elif current_state().state_name == "Shift":
				shifting = false

	.tick()

	if drift_effect:
		spawn_particle_effect_relative(preload("res://characters/swordandgun/freshmilkparticle.tscn"), Vector2(0, 0))

	if drift_jump_timer > 0:
		drift_jump_timer -= 1
		if drift_jump_timer == 0:
			apply_force("0", GROUNDED_DRIFT_JUMP_SPEED)
			move_directly(0, -1)
			set_grounded(false)

#	if id == 1:
#		print(current_state().entered_in_air)

#	if ((current_state().air_type == CharacterState.AirType.Grounded and !is_grounded() and current_state().entered_in_air) or (current_state().air_type == CharacterState.AirType.Aerial and is_grounded() and !current_state().entered_in_air)) and !is_in_hurt_state():
#		drift()


	if shifted_last_frame:
		if current_state().current_tick == 1 and current_state().has_hitboxes and not "Grab" in current_state().state_name:
			state_tick()
			state_tick()
		
		shifted_last_frame = false

	if shifted_this_frame:
		update_facing()
		shifted_this_frame = false
		shifted_last_frame = true

	if objs_map.has(cut_projectile):
		var proj = objs_map[cut_projectile]
		if proj == null or proj.disabled:
			cut_projectile = null
		else:
			if current_tick % 2 == 0:
				use_super_meter(CUTS_METER_DRAIN_1)
			else:
				use_super_meter(CUTS_METER_DRAIN_2)
			if super_meter == 0 and supers_available == 0:
				proj.disable()
	if is_grounded():
		if used_aerial_h_slash:
			used_aerial_h_slash = false
		if used_aerial_l_slice:
			used_aerial_l_slice = false
		if !up_swipe_momentum:
			up_swipe_momentum = true

	if combo_count > 0:
		up_swipe_momentum = true
	if !has_gun and gun_projectile != null:
		var gun = objs_map[gun_projectile]
		if is_instance_valid(gun) and gun.data and !gun.disabled:
			var dist = obj_local_center(gun)
			var pickup_dist = GUN_PICKUP_DISTANCE_BOOMERANG if gun.shot else GUN_PICKUP_DISTANCE
			if gun.can_be_picked_up and fixed.lt(fixed.vec_len(str(dist.x), str(dist.y)), pickup_dist):
				gun.disable()
				has_gun = true
				gun_projectile = null
				play_sound("GunPickup")
			if opponent.combo_count > 0:
				gun.deactivate_current_hitbox()
	if buffer_bullet_cancelling:
		bullet_cancelling = true
		buffer_bullet_cancelling = false
#	if bullet_cancelling and !("try_shoot" in current_state().host_commands.values()):
#		bullet_cancelling = false

func drift():
	var obj = obj_from_name(after_image_object)
	if supers_available >= DRIFT_SUPERS:
		if obj:
			detonating = false
			obj.detonating = true
			if !milk_toggled:
				if is_grounded():
					current_state().entered_in_air = true
					current_state().started_in_air = true
					drift_jump_timer = DRIFT_JUMP_TIMER
#						hitlag_ticks += 2
					
				milk_toggled = true
				milk_toggle_tick = current_tick
				prediction_effect(10)
#				use_air_movement()
				for i in range(DRIFT_SUPERS):
					use_super_bar()
				combo_supers += 1

				set_vel(get_vel().x, "0")
				drift_effect = true

func process_extra(extra):
	.process_extra(extra)
	if extra.has("gun_cancel"):
		buffer_bullet_cancelling = extra.gun_cancel
	if extra.has("detonate"):
		detonating = extra.detonate
	if extra.has("shift"):
		shifting = extra.shift
		if shifting:
			shifted_this_turn = true
			if current_state().get("IS_NEW_PARRY"):
				change_state("Wait")
	if extra.has("drift") and extra.drift:
		drift()

	if extra.has("hindsight") and supers_available > 0:
		if extra.hindsight:
			ex_effect(0)
#			drain_super_meter(MAX_SUPER_METER / 2)
			use_super_bar()
#			super_effect(1)
			var obj = obj_from_name(after_image_object) 
			if obj:
				obj.detonating = true
			var foresight = spawn_object(FORESIGHT, 0, 0)
			setup_foresight(foresight)

func setup_foresight(projectile):
	projectile.sprite.set_material(sprite.get_material())
	after_image_object = projectile.obj_name

func can_bullet_cancel():
	return bullets_left > 0 and has_gun

func try_shoot():
#	print("here")
	if got_parried:
		return
	if !bullet_cancelling:
		return
	if !has_gun:
		return
	if bullets_left > 0:
		bullet_cancelling = false
		can_update_sprite = false
		change_state("QuickerDraw")

func on_state_ended(state):
	.on_state_ended(state)
	if state.state_name == "Roll":
		lasso_parried = false
	bullet_cancelling = false

	if milk_toggle_tick < current_tick:
		drift_effect = false
	milk_toggled = false

func use_bullet():
	if infinite_resources:
		return
	bullets_left -= 1
	emit_signal("bullet_used")

func has_1k_cuts():
	return cut_projectile != null

func is_in_install_super():
	return has_1k_cuts()

func on_attack_blocked():
	if !bullet_cancelling:
		return
	if !has_gun:
		return
	# Multi-hit moves can lock the on-block draw out of their early hitboxes via
	# draw_cancel_on_block_min_tick — the attacker's current_tick at block time is
	# which hitbox connected, so a block before that tick (e.g. 3 Combo Down's 1st
	# hit) doesn't draw. Toggle stays armed; it just won't fire until a later hit.
	var state = current_state()
	if state.get("draw_cancel_on_block") and state.current_tick < state.draw_cancel_on_block_min_tick:
		return
	if bullets_left > 0:
		bullet_cancelling = false
		can_update_sprite = false
		change_state("Brandish")

# Whether a draw can still come out of `state`. Two designed routes:
#  - an unfired try_shoot command (HSlash etc.), gated by the move's own
#    can_draw_cancel() opt-out, or
#  - a move flagged draw_cancel_on_block (the Taunt/Hustle): on_attack_blocked()
#    draws it into Brandish, so the toggle is live while it can still land on
#    block, i.e. while a hitbox is active/upcoming.
# on_attack_blocked() is itself ungated, but a move can only ever trigger it by
# arming bullet_cancelling via this toggle — so NOT surfacing it here (e.g. on a
# raw, punishable move like BackSlash) is what keeps that move uncancellable.
# respect_tick measures from the move's current progress so a held move past its
# window stops offering it; pass false for a fresh move you'd cancel into.
#
# The two routes have different latch timing within a tick:
#  - try_shoot fires during state_tick() (inside .tick()), BEFORE this tick's
#    toggle latches into bullet_cancelling (SwordGuy.tick() sets it after .tick()).
#    So arming on the command's own tick is too late — the command already ran.
#    Require it strictly ahead of current progress (current_tick + 1).
#  - on_attack_blocked fires in apply_hitboxes(), AFTER the latch, so arming on
#    the active-hitbox tick still connects — that route stays inclusive.
func draw_cancel_possible(state, respect_tick = true):
	if state == null or !can_bullet_cancel():
		return false
	if state.has_method("can_draw_cancel") and !state.can_draw_cancel():
		return false
	# A decision at displayed tick T resolves with the FIRST simulated tick
	# advancing the move to T+1. try_shoot fires inside .tick() BEFORE the toggle
	# latches into bullet_cancelling (SwordGuy.tick() latches after .tick()), so
	# arming at the decision only takes hold from T+2 — require try_shoot >= T+2.
	var shoot_after_tick = state.current_tick + 2 if respect_tick else -1
	# on_attack_blocked fires in apply_hitboxes(), AFTER the latch in that same T+1
	# tick, so the on-block route is reachable one tick sooner (>= T+1).
	var block_after_tick = state.current_tick + 1 if respect_tick else -1
	# draw_cancel_on_block_min_tick locks the on-block route out of a move's early
	# hitboxes (e.g. 3 Combo Down's 1st hit), so only count hitboxes from that tick
	# on when deciding if the toggle is still reachable.
	var block_floor = Utils.int_max(block_after_tick, state.draw_cancel_on_block_min_tick)
	var shoot = state.has_upcoming_host_command("try_shoot", shoot_after_tick)
	var blk = state.get("draw_cancel_on_block") and state.has_active_or_upcoming_hitbox(block_floor)
	if shoot:
		return true
	return blk

# Of the two routes in draw_cancel_possible(), is `state` on the on-block one
# only? i.e. it has no unfired try_shoot to fire on hit/whiff, so the draw won't
# come out unless the opponent blocks. Drives the "Draw on Block" vs "Draw" label.
func draw_cancel_on_block_only(state, respect_tick = true):
	if state == null:
		return false
	# Match draw_cancel_possible's try_shoot timing (T+2): a command we can no
	# longer arm in time doesn't count as an on-hit route for the label either.
	var shoot_after_tick = state.current_tick + 2 if respect_tick else -1
	if state.has_upcoming_host_command("try_shoot", shoot_after_tick):
		return false
	return bool(state.get("draw_cancel_on_block"))

func on_got_hit():
	.on_got_hit()
	if cut_projectile:
		if objs_map.has(cut_projectile):
			objs_map[cut_projectile].disable()
			cut_projectile = null
	if after_image_object:
		var obj = obj_from_name(after_image_object)
		if obj != null:
			obj.disable()
			after_image_object = null

func can_block_cancel():
	if current_state().name == "Brandish" or current_state().name == "QuickerDraw":
		return false
	return .can_block_cancel()

func on_state_started(state):
	.on_state_started(state)
#
#func can_guard_break():
#	return .can_guard_break() and !milk_toggled

func should_free_cancel_allow_grounded_and_aerial_states():
	return current_state().state_name != "QuickerDraw" and .should_free_cancel_allow_grounded_and_aerial_states()

func reset_combo():
	.reset_combo()
	# Re-arm LightningSlice's once-per-combo ground-bounce gate.
	lightning_slice_ground_bounced = false

func _draw():
	._draw()
	var draw_target = Vector2()
	var draw_lasso = false
	if lasso_projectile:
		draw_lasso = true
		var obj = objs_map[lasso_projectile]
		var obj_pos = obj.get_pos()
		draw_target = to_local(Vector2(obj_pos.x, obj_pos.y))
	elif lasso_parried:
		draw_lasso = true
		draw_target = to_local(opponent.get_center_position_float())
	elif gun_projectile:
		var gun = obj_from_name(gun_projectile)
		if gun and gun.lassoed:
			draw_lasso = true
			draw_target = to_local(gun.get_center_position_float())
		
	draw_target -= draw_target.normalized() * 8
	if draw_lasso:
		draw_line(Vector2(0, -16), draw_target, Color("704137"), 2.0, false)
