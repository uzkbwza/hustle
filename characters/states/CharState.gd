extends ObjectState

class_name CharacterState

signal state_interruptable()
signal state_hit_cancellable()

const WHIFF_SUPER_GAIN = 10

enum ActionType {
	Movement,
	Attack,
	Special,
	Super,
	Defense,
	Hurt,
}

enum BusyInterrupt {
	Normal,
	Hurt,
	None,
}

enum AirType {
	Grounded,
	Aerial,
	Both
}

export var _c_Menu = 0
export(String) var title
export var show_in_menu = true
export(ActionType) var type
export(PackedScene) var data_ui_scene = null
export(Texture) var button_texture = null
export var flip_icon = true
export var flip_with_facing = false

export var _c_Air_Data = 0
export(AirType) var air_type = AirType.Grounded
export var uses_air_movement = false
export var ignore_air_option_use_in_combos = false
export var land_cancel = false
export var landing_recovery = -1
export var min_land_cancel_frame = -1
export var land_cancel_state = "Landing"

export var _c_Interrupt_Data = 0
export var iasa_at = -1
export var iasa_on_hit = -1
export var iasa_on_hit_on_block = true
export var interrupt_frames = []
export var throw_techable = false
export var interruptible_on_opponent_turn = false
export var update_facing_on_exit = true
export var dynamic_iasa = true
export var backdash_iasa = false
export var allow_framecheat = false
export var next_state_on_hold = true
export var next_state_on_hold_on_opponent_turn = false
export var combo_only = false
export var neutral_only = false
export var end_feint = true
export var usable_from_whiff_cancel_if_possible = true
export var count_projectile_hits = true
export var hold_restart = ""

var starting_iasa_at = -1
var starting_interrupt_frames = []


export var _c_Interrupt_Categories = 0
export(BusyInterrupt) var busy_interrupt_type = BusyInterrupt.Normal
export var burst_cancellable = true
export var burstable = true
export var self_hit_cancellable = true
export var self_interruptable = true
export var reversible = true
export var instant_cancellable = true
export var force_feintable = false
export var can_feint_if_possible = true


export var selectable = true
export(String, MULTILINE) var interrupt_from_string
export(String, MULTILINE) var interrupt_into_string
export(String, MULTILINE) var hit_cancel_into_string
export(String, MULTILINE) var interrupt_exceptions_string
export(String, MULTILINE) var hit_cancel_exceptions_string
export var always_usable = false

export var _c_Stances = 0
export(String, MULTILINE) var allowed_stances_string = "Normal"
export(String) var change_stance_to = ""

export var _c_Misc = 0
export var release_opponent_on_startup = false
export var release_opponent_on_exit = false
export var initiative_effect = false
export var initiative_startup_reduction_amount = 0
export var apply_pushback = true
export var beats_backdash = false
export var no_collision_start_frame = -1
export var no_collision_end_frame = -1
export var can_be_counterhit = true
export var tick_priority = 0
export var velocity_forward_meter_gain_multiplier = "1.0"
export var whiff_meter_gain_multiplier = "1.0"


export var _c_Super = 0
export var super_level_ = 0
export var supers_used_ = -1
export var super_freeze_ticks_ = 15
export var super_effect_ = false
export var scale_combo_meter_ = false
export var force_super_effect = false

func _frame_0_shared():
	var levels = super_level_ if supers_used_ == -1 else supers_used_
	if scale_combo_meter_ and levels > 0:
		host.combo_supers += 1
	if !force_super_effect and (super_effect_ and levels <= 1):
		host.ex_effect(super_freeze_ticks_)
	elif force_super_effect or super_effect_:
		host.super_effect(super_freeze_ticks_)
	for i in range(super_level_ if supers_used_ == -1 else supers_used_):
		host.use_super_bar()

#func _enter_shared():
#	._enter_shared()
#	host.combo_supers += 1
#	if super_effect:
#		host.super_effect(super_freeze_ticks)
#	for i in range(super_level if supers_used == -1 else supers_used):
#		host.use_super_bar()

var initiative_effect_spawned = false

var dash_iasa = false
var started_in_air = false
var entered_in_air = false
var hit_yet = false
var hit_anything = false
var was_blocked = false
var hit_cancelled = false
var started_during_combo = false

var hit_hit_cancellable_projectile = false
var hit_fighter = false

var feinted_last = false
var is_brace = false

var feinting = false
var land_cancelled = false

var interrupt_into = [] setget , get_interrupt_into
var interrupt_from = [] setget , get_interrupt_from
var interrupt_exceptions = [] setget , get_interrupt_exceptions
var hit_cancel_into = [] setget , get_hit_cancel_into
var hit_cancel_exceptions = [] setget , get_hit_cancel_exceptions
var busy_interrupt_into = [] setget , get_busy_interrupt_into
var allowed_stances = [] setget , get_allowed_stances
var usable_requirement_nodes = []

var is_hurt_state = false
var start_interruptible_on_opponent_turn = false
var initiative_startup_reduction = false


func get_interrupt_into():
	return interrupt_into

func get_interrupt_from():
	return interrupt_from

func get_interrupt_exceptions():
	return interrupt_exceptions

func get_hit_cancel_into():
	return hit_cancel_into

func get_hit_cancel_exceptions():
	return hit_cancel_exceptions

func get_busy_interrupt_into():
	return busy_interrupt_into

func get_allowed_stances():
	return allowed_stances

func init():
	if iasa_at < 0:
		iasa_at = anim_length + iasa_at
	if starting_iasa_at == -1:
		starting_iasa_at = iasa_at
	interrupt_frames = interrupt_frames.duplicate(true)
	connect("state_interruptable", host, "on_state_interruptable", [self])
	connect("state_hit_cancellable", host, "on_state_hit_cancellable", [self])
	host.connect("got_hit", self, "on_got_hit")
	if selectable:
		interrupt_from.append_array(get_categories(interrupt_from_string))
	interrupt_into.append_array(get_categories(interrupt_into_string))
	hit_cancel_into.append_array(get_categories(hit_cancel_into_string))
	hit_cancel_exceptions.append_array(get_categories(hit_cancel_exceptions_string))
	allowed_stances.append_array(get_categories(allowed_stances_string))
	interrupt_exceptions.append_array(get_categories(interrupt_exceptions_string))
	start_interruptible_on_opponent_turn = interruptible_on_opponent_turn

	for node in get_children():
		if node is UsableRequirement:
			usable_requirement_nodes.append(node)
	if burst_cancellable:
		hit_cancel_into.append("OffensiveBurst")
	if instant_cancellable:
		hit_cancel_into.append("InstantCancel")
	hit_cancel_into.append("GroundedDefense")
	hit_cancel_into.append("AerialDefense")
	hit_cancel_into.append("GroundedGrab")
	hit_cancel_into.append("AerialGrab")
	hit_cancel_into.append("Wait")
	hit_cancel_into.append("Fall")

	if title == "":
		title = state_name
	match busy_interrupt_type:
		BusyInterrupt.Normal:
			busy_interrupt_into.append("BusyNormal")
		BusyInterrupt.Hurt:
			if burstable:
				busy_interrupt_into.append("BusyHurt")
		BusyInterrupt.None:
			pass
	.init()

# func copy_to(state: ObjectState):
#	.copy_to(state)
#	state.interrupt_frames = interrupt_frames.duplicate()

func get_hold_restart():
	return hold_restart

func get_ui_category():
	return ActionType.keys()[type]

func is_usable_with_grounded_check(force_aerial = false, force_grounded = false):
	if !is_usable():
		return false
	if air_type == AirType.Aerial:
		if force_grounded:
			return false
		if host.is_grounded() and !force_aerial:
			return false
	if air_type == AirType.Grounded:
		if force_aerial:
			return false
		if !host.is_grounded() and !force_grounded:
			return false
	return true

func is_usable():
	if host.current_state().state_name == "WhiffInstantCancel":
		if !has_hitboxes:
			return false
		if !usable_from_whiff_cancel_if_possible:
			return false
	if uses_air_movement and !(ignore_air_option_use_in_combos and host.combo_count > 0):
			if host.air_movements_left <= 0:
				return false
	if type == ActionType.Defense and host.penalty_ticks > 0:
		return false
	if combo_only and host.combo_count < 1:
		return false
	if neutral_only and host.combo_count >= 1:
		return false
	for node in usable_requirement_nodes:
		if !node.check(host):
			return false
	
	if host.supers_available < super_level_:
		return false
	return true

func get_velocity_forward_meter_gain_multiplier():
	return velocity_forward_meter_gain_multiplier

func get_categories(string: String):
	return Utils.split_lines(string)

func _enter_shared():
	if force_same_direction_as_previous_state:
		host.reverse_state = false
	._enter_shared()
	if !get("IS_NEW_PARRY"):
		host.block_used_air_movement = false
	started_during_combo = false
	if dynamic_iasa:
		interruptible_on_opponent_turn = start_interruptible_on_opponent_turn
#	host.update_advantage()
#	if host.opponent:
#		host.opponent.update_advantage()
	hit_yet = false
	land_cancelled = false
	hit_anything = false
	hit_fighter = false
	hit_hit_cancellable_projectile = false
	entered_in_air = !host.is_grounded()
	was_blocked = false
	started_in_air = false
	host.update_grounded()
	if change_stance_to:
		host.change_stance_to(change_stance_to)
	if !host.is_grounded() or air_type == AirType.Aerial:
		started_in_air = true
	if uses_air_movement and !(ignore_air_option_use_in_combos and host.combo_count > 0):
		if !host.infinite_resources and host.gravity_enabled:
			host.air_movements_left -= 1
#	if host.hitlag_ticks == 0 and host.blockstun_ticks == 0:
#		if host.can_update_sprite:
#			call_deferred("update_sprite_frame")
	if has_hitboxes:
		var dir = host.get_move_dir()
		if dir == 0 or dir == host.get_opponent_dir():
			host.add_penalty(-8)
		host.gain_super_meter(fixed.round(fixed.mul(str(WHIFF_SUPER_GAIN), whiff_meter_gain_multiplier)))

func allowed_in_stance():
	return "All" in allowed_stances or host.stance in allowed_stances

func enable_interrupt(check_opponent=true, remove_hitlag=false):
	if backdash_iasa:
		var opponent_state = host.opponent.current_state()
		if opponent_state.beats_backdash:
			return
	if check_opponent and beats_backdash and host.opponent.current_state().beats_backdash:
		host.opponent.current_state().enable_interrupt(false)
		if !allow_framecheat: 
			queue_state_change(fallback_state)
	if beats_backdash and host.opponent.current_state().backdash_iasa:
		if !host.opponent.current_state().allow_framecheat:
			host.opponent.current_state().queue_state_change(host.opponent.current_state().fallback_state)
		if !allow_framecheat:
			queue_state_change(fallback_state)
	if hit_fighter and !allow_framecheat:
			queue_state_change(fallback_state)
	emit_signal("state_interruptable")

func enable_hit_cancel(projectile=false):
	emit_signal("state_hit_cancellable", projectile)

func _on_hit_something(obj, hitbox):
	if !hit_yet and obj == host.opponent:
		hit_yet = true
		host.stack_move_in_combo(state_name)
		if host.combo_count > 0 and hit_yet:
			started_during_combo = true
	if count_projectile_hits and !obj.is_in_group("Fighter"):
		hit_anything = true
	if obj.is_in_group("Fighter"):
		hit_anything = true
		hit_fighter = true
		host.melee_attack_combo_scaling_applied = true
		host.add_penalty(-25)

	elif obj.get("hit_cancel_on_hit"):
		hit_hit_cancellable_projectile = true
	._on_hit_something(obj, hitbox)
	try_hit_cancel(obj, hitbox)

func _can_hit_cancel(obj, hitbox):
	if hitbox.cancellable:
		if obj == host.opponent and obj.has_armor():
			return false
#		if obj == host.opponent and obj.prediction_correct():
#			return
		if ((!burst_cancellable) or host.bursts_available == 0) and hit_cancel_into == ["OffensiveBurst"]:
			return false
		if hitbox is ThrowBox:
			return false
		if !can_hit_cancel():
			return false
		var can_hit_cancel = false
		if obj.has_method("can_hit_cancel"):
			can_hit_cancel = obj.can_hit_cancel(host)
		if obj.is_in_group("Fighter") or can_hit_cancel:
			var projectile = !obj.is_in_group("Fighter")
			if projectile or hitbox.followup_state == "":
				return true

func can_hit_cancel():
	return true

func try_hit_cancel(obj, hitbox):
	if hitbox.cancellable and _can_hit_cancel(obj, hitbox):
		var projectile = !obj.is_in_group("Fighter")
		enable_hit_cancel(projectile)
		if projectile:
			host.global_hitlag(host.hitlag_ticks, true)
			host.hitlag_ticks = 0

func process_hitboxes():
#	if hitbox_start_frames.has(current_tick + 1) and host.feinting:
#		host.feinting = false
#		feinting = true
#		return true
	.process_hitboxes()

func spawn_exported_projectile():
	.spawn_exported_projectile()

func initiative_effect():
	host.spawn_particle_effect(preload("res://fx/YomiEffect.tscn"), host.get_center_position_float())

func _tick_shared():
	if current_tick == 0:
		initiative_startup_reduction = false
		feinting = host.feinting
		hit_cancelled = false
#		hit_cancelled = false
		var forward_movement_initiative = host.was_moving_forward()
		if host.initiative:
			if (initiative_effect):
				if host.initiative_effect:
					initiative_effect()
				host.initiative_effect = false
				if initiative_startup_reduction_amount > 0:
					initiative_startup_reduction = true
			host.on_state_initiative_start()
#		elif forward_movement_initiative:
#			if initiative_effect:
#				host.spawn_particle_effect(preload("res://fx/YomiEffect.tscn"), host.get_center_position_float())
		host.moved_forward = false
		if release_opponent_on_startup:
			host.release_opponent()
		if !is_hurt_state and reversible and !force_same_direction_as_previous_state:
			if host.reverse_state:
				var facing = host.get_facing_int()
				var opponent_x = host.opponent.get_pos().x
				var my_x = host.get_pos().x
				var equal_x = opponent_x == my_x
				host.set_facing(facing * (-1 if !equal_x else 1))
				host.update_data()
		else:
			host.reverse_state = false
		host.moved_backward = false
	if initiative_startup_reduction:
		current_tick += initiative_startup_reduction_amount
		initiative_startup_reduction = false
#	if busy_interrupt_type != BusyInterrupt.Hurt:
#		host.update_advantage()
#		if host.opponent:
#			host.opponent.update_advantage()
	if !host.is_grounded() or air_type == AirType.Aerial:
		started_in_air = true
	var next_state = ._tick_shared()
	if host.combo_count > 0 and hit_yet:
		started_during_combo = true
#	started_during_combo = host.combo_count > 0
	if next_state:
		return next_state
#	if land_cancel:
#		print(started_in_air)

	if land_cancel and can_land_cancel() and host.is_grounded() and started_in_air and current_tick > min_land_cancel_frame and fixed.ge(host.get_vel().y, "0"):
		queue_state_change(land_cancel_state, landing_recovery if landing_recovery >= 0 else null)
		_on_land_cancel()
	if current_tick <= anim_length and !endless:
		if can_interrupt() and !interrupt_into.empty():
			enable_interrupt()
			if dynamic_iasa:
				interruptible_on_opponent_turn = true
	if current_tick == no_collision_start_frame:
		host.colliding_with_opponent = false
	if current_tick == no_collision_end_frame:
		host.colliding_with_opponent = true

func can_land_cancel():
	return true

func _on_land_cancel():
	land_cancelled = true
	pass

func get_last_action_text() -> String:
	return ""

func _tick_after():
#	if backdash_iasa:
#		var opponent_state = host.opponent.current_state()
#		if opponent_state.beats_backdash():
#			iasa_at = -1
#			interrupt_frames = []
#			endless = true
#			interruptible_on_opponent_turn = true
#		else:
#			iasa_at = starting_iasa_at
#			interrupt_frames = starting_interrupt_frames
#			endless = false
#			interruptible_on_opponent_turn = false
#	iasa_at = starting_iasa_at

#	if beats_backdash:
#		var opponent_state = host.opponent.current_state()
#		if opponent_state.backdash_iasa:
#			iasa_at = anim_length - 1
##			interrupt_frames = []
#		else:
#			iasa_at = starting_iasa_at

#			interrupt_frames = starting_interrupt_frames
	host.set_lowest_tick(current_real_tick)
	._tick_after()

func update_parameters():
	pass

func on_continue():
	pass

func can_feint():
	return (has_hitboxes or force_feintable) and (host.feints > 0 or host.get_total_super_meter() >= host.MAX_SUPER_METER) and can_feint_if_possible

func can_interrupt():
	return current_tick == iasa_at or current_tick in interrupt_frames or current_tick == anim_length - 1 or ((hit_fighter or hit_hit_cancellable_projectile) and current_tick == iasa_on_hit) or (was_blocked and iasa_on_hit_on_block and current_tick == iasa_on_hit)

func on_got_hit():
	pass

func opponent_turn_interrupt():
	pass

func _exit_shared():
	beats_backdash = false
	if feinting and end_feint:
		host.update_facing()
		host.feinting = false
	feinting = false
	host.melee_attack_combo_scaling_applied = false
#	host.update_advantage()
#	host.opponent.update_advantage()
	._exit_shared()
	if update_facing_on_exit:
		host.update_facing()
	else:
		host.reverse_state = false
		host.set_facing(host.get_facing_int())
	terminate_hitboxes()

	if release_opponent_on_exit:
		host.release_opponent()
	host.got_parried = false
	host.got_blocked = false
	host.colliding_with_opponent = true
	host.state_interruptable = false
	host.projectile_hit_cancelling = false
	host.has_hyper_armor = false
	host.has_projectile_armor = false
	host.state_hit_cancellable = false
	host.clipping_wall = false

#	if host.reverse_state:
#		host.set_facing(host.get_facing_int() * -1)
#	host.sprite.rotation = 0
	emit_signal("state_ended")
	host.z_index = 0

func flip_allowed():
	return true

func on_interrupt():
	pass

func update_sprite_frame():
#	if host.blockstun_ticks > 0 and !force:
#		return
	.update_sprite_frame()
#	pass
