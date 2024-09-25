extends BaseObj

class_name Fighter

signal action_selected(action, data)
signal super_started(freeze_ticks)
signal parried()
signal got_parried()
signal undo()
signal forfeit()
signal clashed()
#signal blocked()

signal blocked_melee_attack()
signal blocked_melee_attack_at_frame(frame)
signal predicted(freeze_ticks)

#signal got_counter_hit()

var MAX_HEALTH = 1500

#const STALING_REDUCTIONS = [
#	"1.0",
#	"0.90",
#	"0.85",
#	"0.70",
#	"0.62",
#	"0.55",
#	"0.50",
#	"0.46",
#	"0.43",
#	"0.41",
#	"0.40",
#]

const MAX_STALES = 15
const MIN_STALE_MODIFIER = "0.2"

const WALL_SLAM_DAMAGE = "0.75"
const DI_SNAP_DISTANCE = "0.01"

const DAMAGE_SUPER_GAIN_DIVISOR = 1
const DAMAGE_TAKEN_SUPER_GAIN_DIVISOR = 5
const HITLAG_COLLISION_TICKS = 4
const PROJECTILE_PERFECT_PARRY_WINDOW = 3
const BURST_ON_DAMAGE_AMOUNT = 5
const AUTO_PARRY_TICKS = 20
const SADNESS_IMMUNITY_TICKS = 60

const VISUAL_GUTS_RATIO = 1.5

const MAX_WALL_SLAMS = 3

const COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES = 0

const MAX_GROUNDED_HITS = 7
const PREDICTION_CORRECT_SUPER_GAIN = 30
const INCORRECT_PREDICTION_LAG = 7

const PARRY_CHIP_DIVISOR = 3
const PARRY_CHIP_PROJECILE_DIVISOR = 4
const PUSH_BLOCK_CHIP_MODIFIER = "0.33"
const PARRY_KNOCKBACK_DIVISOR = "3"

const PARRY_COMBO_SCALING = "0.85"
const PARRY_GROUNDED_KNOCKBACK_DIVISOR = "1.5"
const PUSH_BLOCK_FORCE = "-10"
const PUSH_BLOCK_DIST = "220"
const PUSH_BLOCK_ADVANTAGE_PENALTY = 0
const AIR_BLOCK_PUSHBACK_MODIFIER = "0.35"
const WAKEUP_THROW_IMMUNITY_TICKS = 3

const GLOBAL_HITLAG_MODIIFER = 0.6
const GLOBAL_BLOCKLAG_MODIFIER = 0.25
const MAX_GLOBAL_HITLAG = 10

const BASE_PLUS_FRAMES = 0
const VS_AERIAL_ADDITIONAL_PLUS_FRAMES = 2
const WRONG_HIT_HEIGHT_ADDITIONAL_PLUS_FRAMES = 2

const DISTANCE_EXTRA_SADNESS = "180"
const MIN_DIST_SADNESS = "128"

const GUARD_BREAK_SCALING = 1

const MISSED_BRACE_DAMAGE_MULTIPLIER = "1.0"
const SUCCESSFUL_BRACE_HITSTUN_MODIFIER = "0.35"
const SUCCESSFUL_BRACE_DI_MODIFIER = "1.5"
const COUNTER_HIT_DAMAGE_MODIFIER = "1.1"

var HOLD_RESTARTS = [
	"Wait",
	"Fall",
	"DashForward",
#	"DashBackward",
	"ParryHigh",
	"BlockHigh",
	"ParryLow",
	"ParryAir",
]

var HOLD_FORCE_STATES = {
	"ParrySuper": "ParryHigh",
#	"ParryLow": "Wait",
#	"ParryAir": "Fall",
	"DashBackward": "Wait",
#	"DashBackwardHold": "Wait",
}

const P1_COLOR = Color("aca2ff")
const P2_COLOR = Color("ff7a81")

const GUTS_REDUCTIONS = {
	"1.0": "1.0",
#	"0.8": "0.9",
#	"0.7": "0.8",
#	"0.6": "0.72",
#	"0.5": "0.64",
#	"0.4": "0.58",
#	"0.3": "0.52",
#	"0.2": "0.46",
#	"0.1": "0.41",
#	"0.1": "0.37",
#	"0.05": "0.35",
}
#
const GUTS_REDUCTIONS_OLD = {
	"1": "1",
	"0.70": "0.90",
	"0.60": "0.80",
	"0.50": "0.70",
	"0.40": "0.60",
	"0.30": "0.55",
	"0.20": "0.52",
	"0.10": "0.50",
}
#
#const GUTS_REDUCTIONS = {
#	"1": "1",
#	"0.70": "0.90",
#	"0.60": "0.80",
#	"0.50": "0.65",
#	"0.40": "0.50",
#	"0.30": "0.40",
#	"0.20": "0.35",
#	"0.10": "0.33",
#}

const MAX_GUTS = 10

const MAX_BURSTS = 1
const BURST_BUILD_SPEED = 4
const MAX_BURST_METER = 1500
const START_BURSTS = 1

const MAX_SUPER_METER = 125
const MAX_SUPERS = 9
const VEL_SUPER_GAIN_DIVISOR = 4
const AERIAL_VELOCITY_SUPER_GAIN_MODIFIER = "0.5"

#const NUDGE_SPEED = "2.0"
const NUDGE_DISTANCE = 20

const PARRY_METER = 50

const METER_GAIN_MODIFIER = "0.85"

const CLASH_MOVE_BACK = 3

const MIN_PENALTY = -20
const MAX_PENALTY = 75
const PENALTY_MIN_DISPLAY = 50

const PENALTY_TICKS = 120

export var _c_NEW_MODDED_CHARACTERS_IMPORTANT = 0
export var _c_ENABLE_THIS_SETTING_IF_YOU_WANT_CONSISTENCY_WITH_THE_BASE_CAST = 0
export var enable_extra_aesthetic_hitstop = false
export var _c_THANK_YOU = 0

export var num_air_movements = 2
export var lose_one_air_option_in_neutral = true
export var use_air_option_bar = false
export var air_option_bar_max = 100
export var air_option_bar = 0
export var air_option_bar_name = "Air Options"

export(Texture) var character_portrait
export(Texture) var character_portrait2

onready var you_label = $YouLabel
onready var actionable_label = $ActionableLabel
onready var quitter_label = $"%QuitterLabel"
onready var velocity_label_container = $VelocityLabelContainer
onready var grounded_indicator = $GroundedIndicator
onready var block_frame_label = $BlockFrameLabel
onready var hit_frame_label = $HitFrameLabel

var input_state = InputState.new()

var color = Color.white

var style_extra_color_1 = extra_color_1
var style_extra_color_2 = extra_color_2

export(PackedScene) var player_info_scene
export(PackedScene) var player_extra_params_scene

export var damage_taken_modifier = "1.0"
export var knockback_taken_modifier = "1.0"
export var di_modifier = "1.0"
export var num_feints = 2

export var use_extra_color_1 = false
export var extra_color_1 = Color("ff00ff")
export var use_extra_color_2 = false
export var extra_color_2 = Color("ff00ff")



var global_damage_modifier = "1.0"
var global_hitstun_modifier = "1.0"
var global_hitstop_modifier = "1.0"
var min_di_scaling = "1.0"
var max_di_scaling = "6.0"
var di_combo_limit = 15

var ghost_blocked_melee_attack = -1
var ghost_got_hit = false


var opponent

var actions = 0

var visible_combo_count = 0
var buffered_global_hitlag = 0

var queued_action = null
var queued_data = null
var queued_extra = null
var buffered_input = {}
var last_input = {}
var previous_input = {}
var use_buffer = false

var hit_out_of_brace = false
var braced_attack = false
var brace_effect_applied_yet = false

var dummy_interruptable = false

var game_over = false
var forfeit = false
var will_forfeit = false

var applied_style = null
var is_color_active = false
var is_aura_active = false
var is_style_active = null
var touching_wall = false
var was_my_turn = false
#var whiffed_block = false


var touch_of_death = true

var ivy_effect = false
var ivy_effect_t = 0.0

var colliding_with_opponent = true

var air_movements_left = 0

var action_cancels = {
}

var ghost_ready_tick = null
var ghost_ready_set = false
var got_parried = false
var got_blocked = false

var block_used_air_movement = false

var di_enabled = true
var turbo_mode = false
var extremely_turbo_mode = false
var infinite_resources = false
var one_hit_ko = false
var burst_enabled = true
var always_perfect_parry = false
var blocked_last_hit = false
var blocked_last_turn = false
var sadness_enabled = false
var last_turn_block = false

var trail_hp: int = MAX_HEALTH
var hp: int = 0
var super_meter: int = 0
var supers_available: int = 0
var combo_proration: int = 0
var last_parry_tick = 0

var parried_last_state = false
var initiative_effect = false

var clipping_wall = false
var burst_meter: int = 0
var bursts_available: int = 0
var turn_frames = 0
#var parried_this_frame = false
var busy_interrupt = false
var any_available_actions = true
var refresh_prediction = false
var burst_cancel_combo = false

var parry_chip_divisor = PARRY_CHIP_DIVISOR
var parry_chip_projectile_divisor = PARRY_CHIP_PROJECILE_DIVISOR
var parry_knockback_divisor = PARRY_KNOCKBACK_DIVISOR

var moved_forward = false
var buffer_moved_forward = false

var moved_backward = false
var buffer_moved_backward = false
var blocked_hitbox_plus_frames = 0

var had_sadness = false

var state_changed = false
var on_the_ground = false
var nudge_amount = "1.0"
var used_air_dodge = false
var used_buffer = false

var has_hyper_armor = false
var has_projectile_armor = false
var hit_during_armor = false

var projectile_hit_cancelling = false

var melee_attack_combo_scaling_applied = false

var wall_slams = 0

var counterhit_this_turn = false
var guard_broken_this_turn = false

var last_pos = null
var penalty = 0
var penalty_buffer = 0
var penalty_ticks = 0
var blockstun_ticks = 0
var sadness_immunity_ticks = 0

var emote_tween: SceneTreeTween

var feints = 2
var feinted_last = false
var feint_parriable = false

var grounded_last_frame = true

var super_meter_used_recently = 0
var super_meter_grace_ticks = 0
const SUPER_METER_GRACE_PERIOD = 3
const SUPER_METER_GRACE_DIVISOR = 2

#var current_prediction = -1

var ghost_was_in_air = false
var ghost_wrong_block = ""

var current_nudge = {
	"x": "0",
	"y": "0",
}

var current_di = {
	"x": "0",
	"y": "0",
}

var last_vel = {
	"x": "0",
	"y": "0",
}

var last_aerial_vel = {
	"x": "0",
	"y": "0",
}

var combo_moves_used = {}

var reverse_state = false
var ghost_reverse = false

var nudge_distance_left = 0

var can_nudge = false
var parried = false

var busy = false

var initiative = false
var aura_particle = null

var in_blockstring = false
var brace_enabled = false

var parry_combo = false

var feinting = false
var clashing = false

var last_action = 0

var stance = "Normal"

var parried_hitboxes = []

var grounded_hits_taken = 0

var throw_pos_x = 16
var throw_pos_y = -5

var combo_supers = 0
var combo_damage = 0
var hitlag_applied = 0
var forfeit_ticks = 0

var minus_frames = 0

var hitstun_decay_combo_count = 0

var lowest_tick = 0
var wakeup_throw_immunity_ticks = 0

class InputState:
	var name
	var data

func clash():
	clashing = true
	update_grounded()
	on_state_interruptable(current_state())
#	reset_momentum()
	var vel = get_vel()
	set_vel("0", vel.y)
	projectile_hit_cancelling = false
#	apply_force_relative(-CLASH_MOVE_BACK, 0)
	add_pushback(str(-CLASH_MOVE_BACK))
	if feints < num_feints:
		feints += 1
	emit_signal("clashed")

func get_visual_hp():
	var ratio = float(hp) / MAX_HEALTH
	return MAX_HEALTH * pow(ratio, VISUAL_GUTS_RATIO)

func init(pos=null):
	.init(pos)
	if !is_ghost:
		Network.player_objects[id] = self
	feints = num_feints
	if one_hit_ko:
		MAX_HEALTH = 1
	hp = MAX_HEALTH
	game_over = false
	if fixed.lt(max_di_scaling, min_di_scaling):
		max_di_scaling = min_di_scaling
	show_you_label()
	if burst_enabled:
		for i in range(START_BURSTS):
			gain_burst()
	for state in state_machine.get_children():
		if state is CharacterState:
			for category in state.interrupt_from:
				if !action_cancels.has(category):
					action_cancels[category] = []
				if !(state in action_cancels[category]):
					action_cancels[category].append(state)
	if infinite_resources:
		supers_available = MAX_SUPERS
		super_meter = MAX_SUPER_METER
	last_pos = get_pos()
	refresh_air_movements()


func is_ivy():
	if !Network.multiplayer_active and !SteamLobby.SPECTATING:
		var username = Network.pid_to_username(id)
		return username in SteamHustle.FX_NAMES
	else:
		if id in Network.network_ids:
			return Network.network_ids[id] in SteamHustle.FX_IDS
	return false

#func prediction_correct():
#	return !is_in_hurt_state() and opponent and current_prediction == opponent.current_state().type

func apply_style(style):
	if (!SteamHustle.STARTED) or Global.steam_demo_version:
		return
	
	if style != null and !is_ghost:
		ivy_effect = is_ivy() and style.style_name == "ivy"
		is_color_active = true
		is_style_active = true
		applied_style = style
		if Global.enable_custom_colors:
			var e1 = style.get("extra_color_1")
			var e2 = style.get("extra_color_2")
			if e1 == null:
				use_extra_color_1 = false
			if e2 == null:
				use_extra_color_2 = false
			
			set_color(style.get("character_color"), e1, e2)
			Custom.apply_style_to_material(style, sprite.get_material())
			sprite.get_material().set_shader_param("extra_replace_color_1", extra_color_1)
			sprite.get_material().set_shader_param("extra_replace_color_2", extra_color_2)
			sprite.get_material().set_shader_param("use_extra_color_1", use_extra_color_1)
			sprite.get_material().set_shader_param("use_extra_color_2", use_extra_color_2)
			
#			print(material)
		else:
			sprite.get_material().set_shader_param("use_extra_color_1", false)
			sprite.get_material().set_shader_param("use_extra_color_2", false)
		if Global.enable_custom_particles and !is_ghost and style.show_aura and style.has("aura_settings"):
			reset_aura()
			is_aura_active = true
			aura_particle = preload("res://fx/CustomTrailParticle.tscn").instance()
			particles.add_child(aura_particle)
			aura_particle.load_settings(style.aura_settings)
			aura_particle.position = hurtbox_pos_float()
			aura_particle.start_emitting()
			if aura_particle.show_behind_parent:
				aura_particle.z_index = -1
		if style.has("hitspark"):
			if Custom.hitsparks.has(style.hitspark):
				custom_hitspark = load(Custom.hitsparks[style.hitspark])
				for hitbox in hitboxes:
					hitbox.HIT_PARTICLE = custom_hitspark


func reset_color():
	is_color_active = false
	sprite.get_material().set_shader_param("color", P1_COLOR if id == 1 else P2_COLOR)
	sprite.get_material().set_shader_param("use_outline", false)

func reset_aura():
	is_aura_active = false
	if is_instance_valid(aura_particle):
		aura_particle.queue_free()
	aura_particle = null

func reset_style():
	reset_color()
	reset_aura()
	is_style_active = false

func reapply_style():
	apply_style(applied_style)

func start_super(freeze_ticks=0):
	emit_signal("super_started", freeze_ticks)

func change_stance_to(stance):
	self.stance = stance

func show_you_label():
	if is_you(false):
		you_label.show()

func is_you(default=true):
	if Network.multiplayer_active:
		return id == Network.player_id
	return default

func unlock_achievement(achievement_name, multiplayer_only=false):
	if !can_unlock_achievements():
		return
	if is_you(!multiplayer_only):
		SteamHustle.unlock_achievement(achievement_name)

func can_unlock_achievements():
	if ReplayManager.playback or ReplayManager.replaying_ingame:
		return false
	if is_ghost:
		return false
	if SteamLobby.SPECTATING:
		return false
	return is_you()

func _ready():
	sprite.animation = "Wait"
	state_variables.append_array(
		["current_di", "current_nudge", "got_blocked", "super_meter_used_recently", "super_meter_grace_ticks", "parry_combo", "busy", "air_option_bar", "air_option_bar_max", "blocked_last_turn", "burst_cancel_combo", "in_blockstring", "knockback_taken_modifier", "block_used_air_movement", "last_parry_tick", "grounded_last_frame", "wakeup_throw_immunity_ticks", "sadness_immunity_ticks", "blockstun_ticks", "guard_broken_this_turn", "counterhit_this_turn", "feint_parriable", "brace_enabled", "turn_frames", "last_turn_block", "parry_chip_divisor", "parry_knockback_divisor", "feinted_last", "hit_out_of_brace", "brace_effect_applied_yet", "braced_attack", "blocked_hitbox_plus_frames", "visible_combo_count", "melee_attack_combo_scaling_applied", "projectile_hit_cancelling", "used_buffer", "max_di_scaling", "min_di_scaling", "last_input", "penalty_buffer", "buffered_input", "use_buffer", "was_my_turn", "combo_supers", "penalty_ticks", "can_nudge", "buffer_moved_backward", "wall_slams", "moved_backward", "moved_forward", "buffer_moved_forward", "used_air_dodge", "refresh_prediction", "clipping_wall", "has_hyper_armor", "hit_during_armor", "colliding_with_opponent", "clashing", "last_pos", "penalty", "hitstun_decay_combo_count", "touching_wall", "feinting", "feints", "lowest_tick", "is_color_active", "blocked_last_hit", "combo_proration", "state_changed","nudge_amount", "initiative_effect", "reverse_state", "combo_moves_used", "parried_last_state", "initiative", "last_vel", "last_aerial_vel", "trail_hp", "always_perfect_parry", "parried", "got_parried", "parried_this_frame", "grounded_hits_taken", "on_the_ground", "hitlag_applied", "combo_damage", "burst_enabled", "di_enabled", "turbo_mode", "infinite_resources", "one_hit_ko", "dummy_interruptable", "air_movements_left", "super_meter", "supers_available", "parried", "parried_hitboxes", "burst_meter", "bursts_available"]
	)
	add_to_group("Fighter")
	connect("got_hit", self, "on_got_hit")
	connect("got_hit_by_fighter", self, "on_got_hit_by_fighter")
	connect("got_hit_by_projectile", self, "on_got_hit_by_projectile")
	state_machine.connect("state_changed", self, "on_state_changed")

func on_state_changed(states_stack):
	if buffer_moved_forward:
		buffer_moved_forward = false
		moved_forward = true
	if buffer_moved_backward:
		buffer_moved_backward = false
		moved_backward = true
	pass

func on_got_hit():
	pass

func on_got_hit_by_fighter():
	pass

func on_got_hit_by_projectile():
	pass

func gain_burst_meter(amount=null):
	if !burst_enabled:
		return

	if penalty_ticks > 0:
		return
		
	if bursts_available < MAX_BURSTS:
		var burst_build_speed = BURST_BUILD_SPEED if amount == null else amount
		if amount == null:
			# it's passive burst gain
			if combo_count <= 0 and opponent.combo_count <= 0:
				burst_build_speed -= 1
				if !is_grounded():
					burst_build_speed -= 1
		if burst_cancel_combo:
			burst_build_speed -= 3
#		print(burst_build_speed)
		burst_meter += burst_build_speed
		if burst_meter > MAX_BURST_METER:
			gain_burst()

func copy_to(f):
	.copy_to(f)
	f.got_parried = got_parried
	f.colliding_with_opponent = colliding_with_opponent
	f.has_hyper_armor = has_hyper_armor
	f.has_projectile_armor = has_hyper_armor
	f.has_projectile_armor = has_projectile_armor
	f.blockstun_ticks = blockstun_ticks
	f.blocked_hitbox_plus_frames = blocked_hitbox_plus_frames
	f.stance = stance
	f.current_state().interrupt_frames = current_state().interrupt_frames.duplicate(true)
	f.update_data()
	var facing = get_facing_int()
	f.set_facing(facing, true)
#	f.set_grounded(is_grounded())
	f.update_data()

func gain_burst():
	if bursts_available < MAX_BURSTS:
		bursts_available += 1
		burst_meter = 0

func load_last_input_into_buffer():
	buffered_input = last_input.duplicate(true)

func use_buffer():
	use_buffer = true

func use_burst():
#	if infinite_resources:
#		return
	bursts_available -= 1
	if bursts_available < 0:
		bursts_available = 0
	refresh_air_movements()

func use_burst_meter(amount):
#	if infinite_resources:
#		return
	if bursts_available > 0:
		bursts_available = 0
		burst_meter = MAX_BURST_METER
	burst_meter -= amount

func get_total_super_meter():
	return MAX_SUPER_METER * supers_available + super_meter

func use_super_bar():
	if infinite_resources:
		return
	supers_available -= 1
	if supers_available < 0:
		supers_available = 0
		super_meter = 0
	super_meter_grace_ticks = SUPER_METER_GRACE_PERIOD
	super_meter_used_recently += MAX_SUPER_METER

func use_super_meter(amount):
	if infinite_resources:
		return
	super_meter -= amount
	if super_meter < 0:
		if supers_available > 0:
			super_meter = MAX_SUPER_METER + super_meter
			use_super_bar()
		else:
			super_meter = 0

func stack_move_in_combo(move_name):
	if combo_moves_used.has(move_name):
		combo_moves_used[move_name] += 1
	else:
		combo_moves_used[move_name] = 1

func meter_gain_modified(amount):
	if penalty_ticks > 0:
		return 0
	var pen = fixed.div(str(penalty), str(MAX_PENALTY))
	if penalty <= 0:
		pen = fixed.div(pen, "5.0")
	amount = fixed.round(fixed.mul(fixed.sub("1", pen), str(amount)))
	return amount

func gain_super_meter(amount,stale_amount = "1.0"):
	
	if amount == null:
		return

	var full_staled_amount = combo_stale_meter(amount)
	amount = fixed.round(fixed.lerp_string(str(amount), str(full_staled_amount), stale_amount))
	amount = meter_gain_modified(amount)
	var super_modified_amount = fixed.round(fixed.div(str(amount), fixed.powu("2", combo_supers)))
	amount = fixed.round(fixed.lerp_string(str(amount), str(super_modified_amount), stale_amount))
	gain_super_meter_raw(amount)

func gain_super_meter_raw(amount):
	super_meter += amount
	var played_sound = false
	while super_meter >= MAX_SUPER_METER:
		if supers_available < MAX_SUPERS:
			super_meter -= MAX_SUPER_METER
			supers_available += 1
			if !played_sound:
				played_sound = true
				play_sound("SuperGain")
				play_sound("SuperGain2")
		else:
			super_meter = MAX_SUPER_METER
			if !infinite_resources:
				unlock_achievement("ACH_ULTIMATE_POWER", true)
			break

func drain_super_meter(amount):
	if infinite_resources:
		return
	super_meter -= amount
	if super_meter < 0:
		if supers_available > 0:
			super_meter += MAX_SUPER_METER
			supers_available -= 1
		else:
			super_meter = 0


func spawn_object(projectile: PackedScene, pos_x: int, pos_y: int, relative=true, data=null, local=true):
	var obj = .spawn_object(projectile, pos_x, pos_y, relative, data, local)
#	if obj is BaseProjectile:
#		add_penalty(-2)
	return obj

func combo_stale_meter(meter: int):
	var staling = get_combo_stale(combo_count)
	return fixed.round(fixed.mul(fixed.mul(str(meter), staling), METER_GAIN_MODIFIER if current_tick > 0 else "1.0"))
	
func update_data():
	data = get_data()
	obj_data = data["object_data"]
	data["state_data"] = {
		"state": current_state().state_name,
		"frame": current_state().current_tick,
		"combo count": combo_count,
	}

func emote(message):
	ReplayManager.emote(message, id, current_tick)
	if !Global.enable_emotes:
		return
	if is_instance_valid(emote_tween):
		emote_tween.kill()
	emote_tween = create_tween()
	$EmoteLabel.clear()
	$EmoteLabel.append_bbcode("[center]" + ProfanityFilter.filter(message))
	$EmoteLabel.show()
	emote_tween.tween_method(self, "set_emote_visible", 1.0, 0.0, 3.0)

func set_emote_visible(amount: float):
	if amount <= 0.001:
		$EmoteLabel.visible = false
		return
	$EmoteLabel.visible = true

func get_playback_input():
	if ReplayManager.playback:
		if get_frames().has(current_tick):
			return get_frames()[current_tick]

func get_global_throw_pos():
	var pos = get_pos()
	pos.x += throw_pos_x * get_facing_int()
	pos.y += throw_pos_y
	return pos

func emit_hit_by_signal(hitbox):
	emit_signal("got_hit")
	if hitbox == null:
		return
	if hitbox.get("host") == null:
		return
	if hitbox.host is String:
		var host = objs_map[hitbox.host]
		if host.is_in_group("Fighter"):
			emit_signal("got_hit_by_fighter")
		else:
			emit_signal("got_hit_by_projectile")

func reset_combo():
	if combo_damage >= 750:
		unlock_achievement("ACH_5000_DAMAGE")
	if touch_of_death and combo_damage >= MAX_HEALTH:
		if !one_hit_ko and !turbo_mode and !extremely_turbo_mode and !infinite_resources and fixed.eq(global_damage_modifier, "1") and fixed.eq(global_hitstop_modifier, "1") and fixed.eq(global_hitstun_modifier, "1"):
			unlock_achievement("ACH_TOUCH_OF_DEATH")
	if visible_combo_count >= 20:
		unlock_achievement("ACH_RELENTLESS", true)
	if combo_count > 0 and !is_ghost:
		touch_of_death = false
	combo_count = 0
	visible_combo_count = 0
	combo_damage = 0
	hitstun_decay_combo_count = 0
	combo_proration = 0
	combo_moves_used = {}
	burst_cancel_combo = false
	combo_supers = 0
	opponent.grounded_hits_taken = 0
	opponent.trail_hp = opponent.get_visual_hp()
	opponent.wall_slams = 0
	opponent.hit_out_of_brace = false
	opponent.braced_attack = false
	opponent.brace_effect_applied_yet = false
	parry_combo = false
	if lose_one_air_option_in_neutral and num_air_movements == air_movements_left:
			refresh_air_movements()

func create_speed_after_image(color: Color = Color.white, lifetime=0.2):
	if is_ghost or ReplayManager.resimulating:
		return
	call_deferred("_create_speed_after_image", color)

func create_speed_after_image_from_style(which=2):
	var color = style_extra_color_2 if (style_extra_color_2 and applied_style) else extra_color_2
	if which == 1:
		color = style_extra_color_1 if (style_extra_color_1 and applied_style) else extra_color_1

	color.a = 0.5
	create_speed_after_image(color)

func _create_speed_after_image(color: Color = Color.white, lifetime=0.2):
	var speed_image_effect = preload("res://fx/SpeedImageEffect.tscn")
	var texture = sprite.frames.get_frame(sprite.animation, sprite.frame)
	var effect = _spawn_particle_effect(speed_image_effect, get_pos_visual() + sprite.offset)
	effect.set_texture(texture)
	effect.lifetime = lifetime
	effect.set_color(color)
	effect.sprite.flip_h = get_facing_int() == -1

func incr_combo(scale=true, projectile=false, force=false, combo_scale_amount=1):
	if (scale and (!melee_attack_combo_scaling_applied or projectile)) or force:
		combo_count += combo_scale_amount
		hitstun_decay_combo_count += 1
	visible_combo_count += 1
	if combo_count == 2 and combo_moves_used.has("Burst"):
		unlock_achievement("ACH_UNFAIR")

func is_colliding_with_opponent():
	return ((colliding_with_opponent or (current_state() is CharacterHurtState and (hitlag_applied - hitlag_ticks) < HITLAG_COLLISION_TICKS)) and current_state().state_name != "Grabbed")

func on_state_started(state):
	.on_state_started(state)


func thrown_by(hitbox: ThrowBox):
	emit_signal("got_hit")
	state_machine._change_state("Grabbed")

func on_grabbed():
	pass

func hitbox_from_name(hitbox_name):
	var hitbox_props = hitbox_name.split("_")
	var obj_name = hitbox_props[0]
	var hitbox_id = int(hitbox_props[-1])
	var obj = obj_from_name(obj_name)
	if obj:
		return objs_map[obj_name].hitboxes[hitbox_id]

func _process(delta):
	if ivy_effect and !is_ghost:
		sprite.get_material().set_shader_param("color", Color.from_hsv(ivy_effect_t, 0.8, 1))
#		sprite.get_material().set_shader_param("outline_color", Color.from_hsv(1 - ivy_effect_t, 1.0, 1.0))
		ivy_effect_t += delta
		ivy_effect_t = fmod(ivy_effect_t, 1.0)
#		print(ivy_effect_t)
#	update()
	if invulnerable:
		if (Global.current_game.real_tick / 1) % 2 == 0:
			var transparent = color
			self_modulate.a = 0.5
#			sprite.get_material().set_shader_param("color", transparent)
		else:
			self_modulate.a = 1.0
#			sprite.get_material().set_shader_param("color", color)
	else:
		self_modulate.a = 1.0
	if is_instance_valid(aura_particle):
		aura_particle.visible = Global.enable_custom_particles
		aura_particle.position = hurtbox_pos_float()
		aura_particle.facing = get_facing_int()
	
	if is_style_active:
		if applied_style and !is_color_active and Global.enable_custom_colors:
			apply_style(applied_style)
		if applied_style and !is_aura_active and Global.enable_custom_particles:
			apply_style(applied_style)
	if is_color_active and !Global.enable_custom_colors:
		reset_color()
	if is_aura_active and !Global.enable_custom_particles:
		reset_aura()
#	$PredictionLabel.show()
#	if is_ghost or ReplayManager.playback:
#		$PredictionLabel.text = "State: " + str(current_state().type) + "\nPrediction: " + str(current_prediction) 
#	else:
#		$PredictionLabel.text = ""

func debug_text():
	.debug_text()
	debug_info(
		{
			"hp": hp,
			"penalty": penalty,
#			"initiative": initiative,
			"combo_proration": combo_proration,
#			"flipped": reverse_state,
#			"real": current_state().current_real_tick,
#			"blocked_hitbox_plus_frames": blocked_hitbox_plus_frames,
			"blockstun_ticks": blockstun_ticks,
			"hitlag_ticks": hitlag_ticks,
#			"feinting": feinting,
			"proration": combo_proration,
			"parry_combo": parry_combo,
			"turn_frames": turn_frames,
			"whiffed_block": current_state().get_whiffed_block() if current_state().has_method("get_whiffed_block") else false,
			"parried": current_state().get("parried"),
			"state_interruptable": state_interruptable,
			"initiative": initiative,
			"busy_interrupt": busy_interrupt,
		}
	)

func has_armor():
	return has_hyper_armor

func has_autoblock_armor():
	return false

func has_projectile_armor():
	return has_projectile_armor

func increment_opponent_combo(hitbox):
	var host = objs_map[hitbox.host]
	var projectile = !host.is_in_group("Fighter")
	var will_scale = hitbox.scale_combo or opponent.combo_count == 0
	var old_count = opponent.combo_count

	if hitbox.increment_combo:
		opponent.incr_combo(will_scale, projectile, projectile and hitbox.scale_combo, hitbox.combo_scaling_amount)
		if opponent.combo_count <= 1 and hitbox.scale_combo:
			opponent.combo_proration = hitbox.damage_proration
			if opponent.combo_count == 1 and old_count == 0 and opponent.air_movements_left < opponent.num_air_movements:
				opponent.air_movements_left += 1

func apply_hitlag(hitbox, global=true):
	hitlag_ticks = (hitbox.victim_hitlag) + (COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES if hitbox.counter_hit else 0)
	if braced_attack:
		hitlag_ticks = fixed.round(fixed.mul(str(hitlag_ticks), SUCCESSFUL_BRACE_HITSTUN_MODIFIER))
	hitlag_ticks = fixed.round(fixed.mul(str(hitlag_ticks), global_hitstop_modifier))
	hitlag_applied = hitlag_ticks
	var host = obj_from_name(hitbox.host)
	if global and host and host.get("enable_extra_aesthetic_hitstop"):
		buffered_global_hitlag = min(hitbox.hitlag_ticks * GLOBAL_HITLAG_MODIIFER, MAX_GLOBAL_HITLAG) 

func get_active_projectiles():
	var objs = []
	for obj_name in objs_map:
		var obj = obj_from_name(obj_name)
		if obj and !obj.disabled and obj.id == id and !obj.is_in_group("Fighter"):
			objs.append(obj)
	return objs

func launched_by(hitbox):
	
	if super_meter_used_recently > 0:
		gain_super_meter_raw(super_meter_used_recently / SUPER_METER_GRACE_DIVISOR)
		super_meter_used_recently = 0
		super_meter_grace_ticks = 0
	
#		if hitlag_ticks < hitbox.victim_hitlag:
	apply_hitlag(hitbox, hitbox.followup_state == "")
	feinting = false
	
	if objs_map.has(hitbox.host):
		var host = objs_map[hitbox.host]
		var host_hitlag_ticks = fixed.round(fixed.mul(str(hitbox.hitlag_ticks), global_hitstop_modifier))
		if host.hitlag_ticks < host_hitlag_ticks:
			host.hitlag_ticks = host_hitlag_ticks
	
	if hitbox.rumble:
		var length = hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames
		rumble(hitbox.screenshake_amount, length + (length * GLOBAL_HITLAG_MODIIFER))
	
	nudge_amount = hitbox.sdi_modifier
	
	var host = objs_map[hitbox.host]
	var projectile = !host.is_in_group("Fighter")
	
	var will_launch =  hitbox.ignore_armor or !has_armor()
	if !hitbox.ignore_armor:
		if projectile and has_projectile_armor() and !hitbox.ignore_projectile_armor:
			will_launch = false
	var will_block = false
	var autoblock = has_autoblock_armor()
	if will_launch:
		if autoblock:
			if !hitbox.ignore_projectile_armor and !hitbox.ignore_armor:
				will_launch = false
				will_block = !projectile

	var scaling_offset = hitbox.combo_scaling_amount - 1
	

	
#	current_prediction = -1
	if will_launch:
		var state
		if is_grounded():
			state = hitbox.grounded_hit_state
		else:
			state = hitbox.aerial_hit_state

		if state == "HurtGrounded":
			grounded_hits_taken += 1
			if grounded_hits_taken >= MAX_GROUNDED_HITS:
				if !hitbox.force_grounded:
					state = "HurtAerial"
					grounded_hits_taken = 0

		if !projectile:
			refresh_feints()
			opponent.refresh_feints()
		else:
			if opponent.combo_count == 0:
				opponent.gain_free_cancel()

		increment_opponent_combo(hitbox)
		
		
		state_machine._change_state(state, {"hitbox": hitbox})
		if hitbox.disable_collision:
			colliding_with_opponent = false

		busy_interrupt = true
		can_nudge = true


#			reset_penalty()
#			opponent.reset_penalty()
		
		on_launched()

	elif will_block:
		change_state("ParryHigh" if !autoblock else "ParryAuto")
		block_hitbox(hitbox, false, true, false, autoblock)

	if has_hyper_armor:
		hit_during_armor = true

	emit_hit_by_signal(hitbox)
	var damage = hitbox.get_damage()
	if will_block:
		damage = fixed.round(fixed.mul(str(damage), "0.5"))
	if hitbox.counter_hit:
		damage = fixed.round(fixed.mul(str(damage), COUNTER_HIT_DAMAGE_MODIFIER))
	take_damage(damage, hitbox.minimum_damage, hitbox.meter_gain_modifier, scaling_offset)

	if will_launch:
		state_tick()

func on_launched():
	pass

func on_roll_started():
	pass

func can_counter_hitbox(hitbox):
	var host = obj_from_name(hitbox.host)
#	if host and !host.is_in_group("Fighter"):
#		return false
	var state: CharacterState = current_state()
	if !is_bracing():
		return false
	if (state is CounterAttack):
		match state.counter_type:
			CounterAttack.CounterType.Grab:
				return hitbox.throw
			CounterAttack.CounterType.High:
				return !hitbox.throw and (hitbox.hit_height == Hitbox.HitHeight.High or hitbox.hit_height == Hitbox.HitHeight.Mid)
			CounterAttack.CounterType.Low:
				return !hitbox.throw and (hitbox.hit_height == Hitbox.HitHeight.Low)
		return false
	return false

func is_bracing():
	return current_state() is CounterAttack and current_state().bracing

func prediction_effect(ticks=7):
	play_sound("Predict")
	play_sound("Predict2")
	play_sound("Predict3")
	emit_signal("predicted", ticks)

func counter_hitbox(hitbox):
	var pos = get_pos_visual()
	var hitbox_pos = Vector2(hitbox.pos_x, hitbox.pos_y)
	braced_attack = true

	prediction_effect()


func hit_by(hitbox, force_hit=false):
	if parried:
		return 
	if hitbox.name in parried_hitboxes:
		return 
	if not hitbox.hits_otg and is_otg():
		return 
	if not hitbox.hits_vs_dizzy and current_state().state_name == "HurtDizzy":
		return 
	if can_counter_hitbox(hitbox):
		counter_hitbox(hitbox)
	elif current_state() is CounterAttack:
		hit_out_of_brace = true

	if hitbox.throw and not is_otg():
		return thrown_by(hitbox)
	if force_hit or (not can_parry_hitbox(hitbox)):
		ghost_got_hit = true
		match hitbox.hitbox_type:
			Hitbox.HitboxType.Normal:
				launched_by(hitbox)
			Hitbox.HitboxType.NoHitstun:
				take_damage(hitbox.damage if opponent.combo_count <= 0 else hitbox.damage_in_combo)
			Hitbox.HitboxType.Burst:
				launched_by(hitbox)
			Hitbox.HitboxType.Flip:
				set_facing(get_facing_int() * - 1, true)
				var vel = get_vel()
				set_vel(fixed.mul(vel.x, "-1"), vel.y)
				for hitbox in hitboxes:
					hitbox.facing = get_facing()
					pass
				emit_signal("got_hit")
				increment_opponent_combo(hitbox)
				take_damage(hitbox.get_damage(), hitbox.minimum_damage, hitbox.meter_gain_modifier)
			Hitbox.HitboxType.ThrowHit:
				emit_signal("got_hit")
				apply_hitlag(hitbox)
				opponent.apply_hitlag(hitbox)
				if hitbox.rumble:
					rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
				take_damage(hitbox.get_damage(), hitbox.minimum_damage, hitbox.meter_gain_modifier)
#				increment_opponent_combo(hitbox)
				opponent.incr_combo(hitbox.scale_combo, false, false, hitbox.combo_scaling_amount)
			Hitbox.HitboxType.OffensiveBurst:
				opponent.hitstun_decay_combo_count = 0
#				opponent.combo_proration = Utils.int_min(opponent.combo_proration, 0)
				launched_by(hitbox)
				reset_pushback()
				opponent.reset_pushback()
	else:
		block_hitbox(hitbox)

func block_hitbox(hitbox, force_parry=false, force_block=false, ignore_guard_break=false, autoblock_armor=false):
		var host = objs_map[hitbox.host]
		var projectile = not host.is_in_group("Fighter")
		var perfect_parry
		var parry_type = current_state().parry_type
		var input_timing = current_state().data["Melee Parry Timing"].count + (blocked_hitbox_plus_frames - opponent.blocked_hitbox_plus_frames)
#		print(input_timing)
		var parry_timing = 0
		state_interruptable = false

		if not projectile:
			if current_state().get("IS_NEW_PARRY"):
	#				perfect_parry = current_state().can_parry and (always_perfect_parry or (current_state().current_tick == current_state().data.x - 1) and (opponent.current_state().feinting or opponent.feinting or initiative))
				parry_timing = turn_frames + (opponent.hitlag_ticks if !projectile else 0)
				
				var in_parry_window = (parry_timing == input_timing or input_timing >= 20 and turn_frames >= 20) or (hitbox.hitbox_type == Hitbox.HitboxType.Burst and combo_count > 0)
				var perfect_requirement_no_height =  can_perfect_parry() and (!current_state().get_whiffed_block())  and (opponent.current_state().feinting or opponent.feinting or initiative) and hitbox.parriable
				var perfect_requirement = perfect_requirement_no_height and current_state().matches_hitbox_height(hitbox)
\
#				if projectile:
#					perfect_requirement = perfect_requirement and host.has_projectile_parry_window
#				else:
				if is_ghost and perfect_requirement_no_height and !current_state().push and ghost_blocked_melee_attack == -1:
					ghost_blocked_melee_attack = parry_timing
					ghost_wrong_block = "Low" if hitbox.hit_height == Hitbox.HitHeight.Low else "High"
				perfect_parry = current_state().can_parry and ((can_perfect_parry() and always_perfect_parry) or (in_parry_window) and perfect_requirement and !blocked_last_hit)
				if opponent.feint_parriable:
					perfect_parry = true

			else:
				parry_timing = turn_frames
				var in_parry_window = (parry_timing == input_timing or input_timing >= 20 and turn_frames >= 20) or (hitbox.hitbox_type == Hitbox.HitboxType.Burst and combo_count > 0)
	#				perfect_parry = current_state().can_parry and (always_perfect_parry or opponent.current_state().feinting or opponent.feinting or (initiative and !blocked_last_hit) or parried_last_state)
				perfect_parry = current_state().can_parry and (always_perfect_parry or opponent.current_state().feinting or opponent.feinting or (initiative and !blocked_last_hit) or parried_last_state)
				perfect_parry = perfect_parry and hitbox.parriable
		else:
			perfect_parry = current_state().can_parry and !current_state().get("push") and (always_perfect_parry or host.always_parriable or parried_last_state or (current_state().current_tick < PROJECTILE_PERFECT_PARRY_WINDOW and host.has_projectile_parry_window))

		if force_parry:
			perfect_parry = true
		if force_block:
			perfect_parry = false

		if perfect_parry:
			parried_last_state = true
			last_parry_tick = current_tick
			if !hitbox.block_punishable and !projectile:
				parry_combo = true
		else:
			blocked_last_hit = true
			blocked_last_turn = true

			start_throw_invulnerability()
			if !projectile and !perfect_parry and  !last_turn_block and initiative:
				if hitbox.guard_break and !ignore_guard_break and (!current_state().get_whiffed_block()) and opponent.can_guard_break():
					hitbox.damage_proration = Utils.int_max(hitbox.guard_break_proration, hitbox.damage_proration)
					hit_by(hitbox, true)
					if current_state().get("guard_broken") != null:
						current_state().guard_broken = true
						guard_broken_this_turn = true
					return

		if not projectile:
			if !perfect_parry:
				opponent.feinting = false
				opponent.got_blocked = true
				on_blocked_melee_attack()
			else:
				opponent.feinting = false
				opponent.got_parried = true
				opponent.current_state().interruptible_on_opponent_turn = false
		
			if !current_state().get("IS_NEW_PARRY"):
				opponent.current_state().feinting = false
		
		
		parried = true

		hitlag_ticks = 0
		parried_hitboxes.append(hitbox.name)
		var particle_location = current_state().get("particle_location")
		particle_location.x *= get_facing_int()
		
		if current_state().get("IS_NEW_PARRY"):
			var high_anim = "ParryHigh" if !current_state().use_guard_sprites else "ShieldHigh"
			var low_anim = "ParryLow" if !current_state().use_guard_sprites else "ShieldLow"
			current_state().anim_name = low_anim if (hitbox.hit_height == Hitbox.HitHeight.Low or !is_grounded()) else high_anim
			current_state().update_sprite_frame()

		if not particle_location:
			particle_location = hitbox.get_hit_particle_location(hurtbox)
		var parry_meter = PARRY_METER if hitbox.parry_meter_gain == - 1 else hitbox.parry_meter_gain
		current_state().parry(perfect_parry)
		
		if not perfect_parry:
			last_turn_block = true

			var chip = fixed.round(fixed.mul(str(hitbox.damage / (parry_chip_divisor if !projectile else parry_chip_projectile_divisor)), hitbox.chip_damage_modifier))
			var push_block = current_state().get("push")
			if push_block:
				chip = fixed.round(fixed.mul(str(chip), PUSH_BLOCK_CHIP_MODIFIER))

			if !current_state().matches_hitbox_height(hitbox, parry_type):
				chip += fixed.round(fixed.mul(fixed.mul(str(hitbox.damage / parry_chip_divisor), "0.5"), hitbox.chip_damage_modifier))

			if !autoblock_armor:
				take_damage(chip, 0, "0.4", 0, "2.0")

#			gain_super_meter(parry_meter / 6)
			opponent.gain_super_meter(parry_meter / 10)
			var block_hitlag = hitbox.hitlag_ticks + 1

			if not projectile:
				if !block_used_air_movement:
#					use_air_movement()
					block_used_air_movement = true
				if autoblock_armor:
					opponent.hitlag_ticks = 0

				current_state().anim_length = opponent.current_state().anim_length
				current_state().endless = opponent.current_state().endless
				current_state().iasa_at = opponent.current_state().iasa_at
				current_state().current_tick = 0
				opponent.current_state().was_blocked = true
				opponent.on_attack_blocked()
				opponent.blockstun_ticks += block_hitlag
				opponent.add_penalty(-10)
				if opponent.feints < opponent.num_feints:
					opponent.feints += 1
				if !(hitbox.looping and !hitbox.cancellable) and hitbox.block_cancel_allowed and opponent.can_block_cancel():
					if !hitbox.block_punishable or autoblock_armor:
#						if opponent.current_state()._can_hit_cancel(self, hitbox):
#							opponent.current_state().enable_hit_cancel()
#						else:
						current_state().enable_interrupt()
						opponent.current_state().interruptible_on_opponent_turn = true
						opponent.last_turn_block = true
					else:
						current_state().enable_interrupt()
				var vel = get_vel()
				if fixed.sign(str(get_opponent_dir())) == fixed.sign(vel.x):
					set_vel("0", vel.y)
				var block_pushback_modifier = hitbox.block_pushback_modifier
				if hitbox.block_pushback_reversible:
					var dir = Utils.int_sign(hitbox.pos_x - get_pos().x)
					var modifier = "1"
					if dir == -1 and hitbox.facing == "Left":
						modifier = "-1"
					if dir == 1 and hitbox.facing == "Right":
						modifier = "-1"
					if fixed.eq(modifier, "-1"):
						modifier = fixed.mul(hitbox.block_reverse_pushback_modifier, modifier)
					block_pushback_modifier = fixed.mul(block_pushback_modifier, modifier)
				if current_state().get("push") and fixed.lt(block_pushback_modifier, "0"):
					block_pushback_modifier = fixed.mul(block_pushback_modifier, "-1")
				var pushback_force = fixed.mul(fixed.div(hitbox.knockback, fixed.mul(str(get_opponent_dir()), fixed.mul(parry_knockback_divisor, "-1"))), block_pushback_modifier)
				if !is_grounded():
					pushback_force = fixed.mul(pushback_force, AIR_BLOCK_PUSHBACK_MODIFIER)
				
				if pushback_force != null:
					apply_force(pushback_force, "0")
				opponent.apply_force_relative(fixed.mul(fixed.div(hitbox.knockback, fixed.mul(parry_knockback_divisor, "-2")), block_pushback_modifier), "0")

			if current_state().get("push"):
				if !projectile or fixed.le(get_opponent_distance(), PUSH_BLOCK_DIST):
	#				apply_force(fixed.mul(str(get_opponent_dir()), fixed.mul(fixed.div(hitbox.knockback, fixed.mul(PARRY_KNOCKBACK_DIVISOR, "-0.1")), hitbox.block_pushback_modifier)), "0")
					opponent.apply_force(fixed.mul(str(opponent.get_opponent_dir()), PUSH_BLOCK_FORCE), "0")
					opponent.on_got_push_blocked()
				if projectile:
					host.on_got_push_blocked()
	
			blocked_hitbox_plus_frames = BASE_PLUS_FRAMES

			current_state().interruptible_on_opponent_turn = true

			var total_plus_frames = hitbox.plus_frames
			
			if !current_state().matches_hitbox_height(hitbox, parry_type):
				total_plus_frames += WRONG_HIT_HEIGHT_ADDITIONAL_PLUS_FRAMES
			
			if current_state().get("push"):
				total_plus_frames += PUSH_BLOCK_ADVANTAGE_PENALTY
	
			if !projectile:
				total_plus_frames += BASE_PLUS_FRAMES
				if !is_grounded():
					total_plus_frames += VS_AERIAL_ADDITIONAL_PLUS_FRAMES

			set_block_stun(total_plus_frames, 0 if projectile else block_hitlag)
#
#			if not projectile:
#				blockstun_ticks += block_hitlag

			spawn_particle_effect(preload("res://fx/FlawedParryEffect.tscn"), get_pos_visual() + particle_location)
			parried = false
			if projectile:
				apply_force_relative(fixed.mul(fixed.div(hitbox.knockback, fixed.mul(PARRY_KNOCKBACK_DIVISOR, "-1")), hitbox.block_pushback_modifier), "0")

			play_sound("Block2")
			play_sound("Block3")
#			play_sound("Block3")
#			play_sound("HitBass")
#			play_sound("Parry")
			if host.has_method("on_got_blocked"):
				host.on_got_blocked()
			if host.has_method("on_got_blocked_by"):
				host.on_got_blocked_by(self)
			on_blocked_something()
			if host.get("enable_extra_aesthetic_hitstop"):
				global_hitlag(min(block_hitlag * GLOBAL_BLOCKLAG_MODIFIER, 20))
			if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
				set_facing(get_facing_int() * - 1, true)
		else:
			if not projectile:
				gain_super_meter(parry_meter)
				add_penalty(-20)
				
			else:
				add_penalty(-10)
				gain_super_meter(parry_meter / 3)
#				if opponent.feinting:
#					opponent.current_state().interruptible_on_opponent_turn = true
#					opponent.current_state().enable_interrupt()
			if host.has_method("on_got_parried"):
				host.on_got_parried()
			if host.has_method("on_got_parried_by"):
				host.on_got_parried_by(self)
			spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), get_pos_visual() + particle_location)
			play_sound("Parry2")
			play_sound("Parry")
			emit_signal("parried")
			on_parried()

func on_parried():
	pass

func projectile_free_cancel():
#	if current_state().state_name in ["Burst", "DefensiveBurst", "OffensiveBurst"]:
#		return
	if !current_state().can_feint_if_possible:
		return
	if (got_blocked or got_parried):
		return
	feinting = true

func on_blocked_something():
	pass

func set_block_stun(total_plus_frames, block_hitlag=null):
#	blockstun_ticks = 0
	if block_hitlag == null:
		block_hitlag = total_plus_frames
	if total_plus_frames > 0:
		blocked_hitbox_plus_frames = total_plus_frames
	elif total_plus_frames < 0:
		opponent.blocked_hitbox_plus_frames = total_plus_frames * -1
	blockstun_ticks += block_hitlag


func parry_effect(location, absolute=false):
	if !absolute:
		spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), get_pos_visual() + location)
	else:
		spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), location)
	play_sound("Parry2")
	play_sound("Parry")

func set_throw_position(x: int, y: int):
	throw_pos_x = x
	throw_pos_y = y

func get_penalty_damage_modifier():
	var min_penalty_for_damage = 20
	if penalty_ticks > 0:
		return "1.5"
	if penalty < min_penalty_for_damage:
		return "1.0"
	return fixed.add("1.0", fixed.mul(fixed.div(str(penalty - min_penalty_for_damage), str(MAX_PENALTY - min_penalty_for_damage)), "0.5"))

func take_damage(damage:int, minimum=0, meter_gain_modifier="1.0", combo_scaling_offset=0, damage_taken_meter_gain_modifier = "1.0"):
	
	if opponent.combo_count == 0:
		trail_hp = get_visual_hp()

	if damage == 0:
		return

	gain_burst_meter(damage / BURST_ON_DAMAGE_AMOUNT)
	var damage_score = Utils.int_max(damage, minimum)
	damage = Utils.int_max(combo_stale_damage(damage, combo_scaling_offset), 1)
	damage = Utils.int_max(damage, minimum)
	damage = Utils.int_max(guts_stale_damage(damage), 1)
	if opponent.parry_combo:
		damage = fixed.round(fixed.mul(str(damage), PARRY_COMBO_SCALING))
	damage = fixed.round(fixed.mul(str(damage), get_penalty_damage_modifier()))
	var meter_gain = fixed.round(fixed.mul(str(damage / DAMAGE_SUPER_GAIN_DIVISOR), meter_gain_modifier))

	opponent.gain_super_meter(meter_gain)
	gain_super_meter(fixed.round(fixed.mul(str(damage / DAMAGE_TAKEN_SUPER_GAIN_DIVISOR), damage_taken_meter_gain_modifier)))
	damage = fixed.round(fixed.mul(fixed.mul(str(damage), damage_taken_modifier), global_damage_modifier))
	opponent.combo_damage += damage
	hp -= damage
	add_penalty(-25)
	if hp < 0:
		hp = 0
	if current_state().get("IS_NEW_PARRY") and current_state().push:
		if hp <= 0:
			hp = 1

func get_guts():
	var current_guts = "1"
	for level in GUTS_REDUCTIONS:
		var hp_level = fixed.div(str(hp), str(MAX_HEALTH))
		if fixed.le(hp_level, level):
			current_guts = GUTS_REDUCTIONS[level]
	return current_guts

func get_combo_stale(count):
	var ratio = fixed.div(fixed.sub(str(MAX_STALES), str(Utils.int_min(count, MAX_STALES))), str(MAX_STALES))
	var mod = fixed.mul(fixed.sub("1", MIN_STALE_MODIFIER), fixed.powu(ratio, 2))
	mod = fixed.add(mod, MIN_STALE_MODIFIER)
	return mod

func guts_stale_damage(damage: int):
	var guts = get_guts()
	damage = fixed.round(fixed.mul(str(damage), guts))
	return damage

func combo_stale_damage(damage: int, combo_scaling_offset=0):
	var staling = get_combo_stale(Utils.int_max(opponent.combo_count - combo_scaling_offset + (opponent.combo_proration if opponent.combo_count > 1 else 0) - 1, 0))
	return fixed.round(fixed.mul(str(damage), staling))

func can_perfect_parry():
	return true

func can_parry_hitbox(hitbox):
	if not current_state() is ParryState:
		return false
#	if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
#		return true
	return current_state().can_parry_hitbox(hitbox)

func set_color(color, extra_color_1=null, extra_color_2=null):
	if color != null:
		sprite.get_material().set_shader_param("color", color)
		self.color = color
	
	if use_extra_color_1 and extra_color_1 != null:
		sprite.get_material().set_shader_param("extra_color_1", extra_color_1)
		self.style_extra_color_1 = extra_color_1
		
	if use_extra_color_2 and extra_color_2 != null:
		sprite.get_material().set_shader_param("extra_color_1", extra_color_1)
		self.style_extra_color_2 = extra_color_2

func release_opponent():
	if opponent.current_state().state_name == "Grabbed":
		opponent.change_state("Fall")

func on_attack_blocked():
	pass

func get_di_scaling(brace=true):
	if brace and hit_out_of_brace:
		return "0"
	var max_extra_di = fixed.sub(max_di_scaling, min_di_scaling)
	var scaling_amount = str(Utils.int_clamp(opponent.combo_count, 0, di_combo_limit))
	var scaling_ratio = fixed.div(scaling_amount, str(di_combo_limit))
	var total_extra_scaling = fixed.mul(max_extra_di, scaling_ratio)
	var total = fixed.add(min_di_scaling, total_extra_scaling)
	if brace and braced_attack:
		total = fixed.mul(total, SUCCESSFUL_BRACE_DI_MODIFIER)
	total = fixed.mul(total, di_modifier)
	return total

func can_guard_break():
	return true

func get_scaled_di(di):
	var scaling = get_di_scaling()
	var result = xy_to_dir(di.x, di.y, scaling)
	var length = fixed.vec_len(result.x, result.y)
	if fixed.lt(fixed.abs(fixed.sub(length, scaling)), DI_SNAP_DISTANCE) or fixed.gt(length, scaling):
		result = fixed.normalized_vec_times(result.x, result.y, scaling)
	return result

func consume_feint():
	if used_buffer:
		return
	if feints > 0:
		feints -= 1
	else:
		use_super_bar()
		ex_effect(0)

func process_extra(extra):
	if "DI" in extra:
		if di_enabled:
			var di = extra["DI"]
			current_nudge = xy_to_dir(di.x, di.y, str(NUDGE_DISTANCE))
			current_di = di
		else:
			current_di = {
				"x": 0,
				"y": 0,
			}
	if "reverse" in extra:
		reverse_state = extra["reverse"]
		if reverse_state:
			ghost_reverse = true
	if "feint" in extra:
		feinting = extra.feint
		if feinting and !infinite_resources:
			consume_feint()
#	if "prediction" in extra:
#		current_prediction = extra["prediction"]
#		prediction_processed = false
	else:
		feinting = false

func super_effect(freeze_ticks=0):
	start_super(freeze_ticks)
	play_sound("Super")
	play_sound("Super2")
	play_sound("Super3")

func ex_effect(freeze_ticks=0):
	start_super(freeze_ticks)
	play_sound("Ex1")
	play_sound("Ex2")
	play_sound("Ex3")
	play_sound("Ex4")

func use_air_movement():
	if infinite_resources:
		return
	if air_movements_left > 0:
		air_movements_left -= 1

func refresh_air_movements():
	if !lose_one_air_option_in_neutral:
		air_movements_left = num_air_movements
		return
	if num_air_movements == 0:
		air_movements_left = 0
		return
	air_movements_left = Utils.int_max(num_air_movements - 1, 1) if combo_count == 0 else num_air_movements

func refresh_feints():
	feints = num_feints

func clean_parried_hitboxes():
#	if is_ghost:
#		return
	if !parried_hitboxes:
		return
	var hitboxes_to_refresh = []
	for hitbox_name in parried_hitboxes:
		var hitbox = hitbox_from_name(hitbox_name)
		if hitbox:
			if !hitbox.enabled or !hitbox.active:
				hitboxes_to_refresh.append(hitbox)

	for hitbox in hitboxes_to_refresh:
		parried_hitboxes.erase(hitbox.name)

func get_opponent_dir():
	return Utils.int_sign(opponent.get_pos().x - get_pos().x)

func get_dir_vec(pos, normalized=true):

	var my_pos = get_pos()
	
	if normalized:
		return fixed.normalized_vec(str(pos.x - my_pos.x), str(pos.y - my_pos.y))
	return {
		"x": pos.x - my_pos.x,
		"y": pos.y - my_pos.y
	}


func get_opponent_dir_vec(normalized=true):
	var my_pos = get_pos()
	var opp_pos = opponent.get_pos()
	
	if normalized:
		return fixed.normalized_vec(str(opp_pos.x - my_pos.x), str(opp_pos.y - my_pos.y))
	return {
		"x": opp_pos.x - my_pos.x,
		"y": opp_pos.y - my_pos.y
	}

func get_opponent():
	return opponent

func update_property_list():
	if !is_ghost:
		for state in state_machine.states_map:
			state_machine.states_map[state].update_property_list()


func get_advantage():
	if opponent == null:
		return true
	if combo_count > 0:
		return true
#	var minus_modifier = 1 if id == 1 else 0
	var minus_modifier = 0
	var advantage = (opponent and opponent.lowest_tick <= lowest_tick) or parried_last_state

#		print(opponent.lowest_tick)
	if state_interruptable and opponent.state_interruptable:
		advantage = true
#	if prediction_correct():
#		advantage = true
#	if was_moving_backward():
#		advantage = false
	var prev_advantage = advantage
	var whiff_cancel_advantage = false
	if current_state().state_name == "WhiffInstantCancel" or (previous_state() and previous_state().state_name == "WhiffInstantCancel" and current_state().has_hitboxes):
		advantage = false
		whiff_cancel_advantage = true
	if opponent.current_state().state_name == "WhiffInstantCancel" or (opponent.previous_state() and opponent.previous_state().state_name == "WhiffInstantCancel" and opponent.current_state().has_hitboxes):
		advantage = false
		whiff_cancel_advantage = true
	if whiff_cancel_advantage and prev_advantage:
		if current_state().get("IS_NEW_PARRY"):
			advantage = true
	return advantage
	
func check_initiative():
	if combo_count > 0:
		return true
	if busy_interrupt:
		return false
	if opponent.busy_interrupt:
		return false
	if current_state().state_name == "WhiffInstantCancel":
		return false
	return true

func was_moving_forward():
	return moved_forward and current_state().has_hitboxes

func was_moving_backward():
	return moved_backward


func set_lowest_tick(tick):
	if lowest_tick == null or tick < lowest_tick:
		lowest_tick = tick

func update_advantage():
	var new_adv = get_advantage()
	if new_adv and !initiative:
		initiative_effect = true
	initiative = new_adv

func on_state_initiative_start():
	pass

func clear_buffer():
	buffered_input = {}

func process_continue():
	return false

func tick_before():
	if queued_action == "Forfeit":
		if forfeit:
			queued_action = "Continue"
	if clashing:
		if is_grounded():
			change_state("Wait")
		else:
			change_state("Fall")
		clashing = false
	turn_end_effects()
	dummy_interruptable = false
	clean_parried_hitboxes()
	busy_interrupt = false

	update_grounded()
	if ReplayManager.playback:
		var input = get_playback_input()
		if input:
			queued_action = input["action"]
			queued_data = input["data"]
			queued_extra = input["extra"]
#			last_action = current_tick
			if queued_action == "Forfeit":
#				dummy = true
				forfeit = true
				Global.current_game.forfeit(id)
	else:
		if queued_action:
			actions += 1
#			last_action = current_tick
			if queued_action == "Undo":
				queued_action = null
				queued_data = null
				return

			if queued_action == "Forfeit":
				forfeit = true
#			if queued_action != "ContinueAuto":
			if !is_ghost:
				ReplayManager.frames[id][current_tick] = {
					"action": queued_action,
					"data": queued_data,
					"extra": queued_extra,
				}
	previous_input = last_input.duplicate(true)
	feinted_last = feinting
	var pressed_feint = false
	if refresh_prediction:
		refresh_prediction = false
#		current_prediction = -1
#	if !prediction_processed and !is_in_hurt_state():
#		process_prediction()
	blocked_last_turn = false
	if use_buffer:
		if buffered_input.has("action"):
			queued_action = buffered_input.action
		if buffered_input.has("data"):
			queued_data = buffered_input.data
		if buffered_input.has("extra"):
			queued_extra = buffered_input.extra
		use_buffer = false
		used_buffer = true
		clear_buffer()
	if queued_extra:
		turn_frames = 0
		opponent.turn_frames = 0
		last_input["extra"] = queued_extra
		process_extra(queued_extra)
		pressed_feint = feinting
	if queued_action:
		process_action(queued_action)
		turn_frames = 0
		opponent.turn_frames = 0
		turn_start_effects()
		counterhit_this_turn = false
		guard_broken_this_turn = false
		if current_state() is CounterAttack:
			current_state().bracing = false
		if brace_effect_applied_yet:
			brace_effect_applied_yet = false
			braced_attack = false
		last_input["action"] = queued_action
		last_input["data"] = queued_data
		feint_parriable = false
		if queued_action == "Continue":
			var current_state_name = current_state().name
			if process_continue():
				pass
			elif current_state().get_hold_restart() != "" and current_state().interruptible_on_opponent_turn:
				queued_action = current_state().get_hold_restart()
				queued_data = current_state().data
			elif current_state_name in HOLD_RESTARTS and current_state().interruptible_on_opponent_turn:
				queued_action = current_state_name
				queued_data = current_state().data
			elif current_state_name in HOLD_FORCE_STATES and current_state().interruptible_on_opponent_turn:
				queued_action = HOLD_FORCE_STATES[current_state_name]
			elif (was_my_turn or (current_state().interruptible_on_opponent_turn and current_state().next_state_on_hold_on_opponent_turn) \
					or (current_state().hit_fighter and combo_count == 0)) and !feinting and current_state().next_state_on_hold:
				queued_action = current_state().fallback_state
			if feinted_last:
				feint_parriable = true
			if !current_state().interruptible_on_opponent_turn:
				current_state().on_continue()

		if current_state().interruptible_on_opponent_turn:
			current_state().opponent_turn_interrupt()
#			elif projectile_hit_cancelling:
#				queued_action = current_state().fallback_state

		if queued_action in state_machine.states_map:
#			last_action = current_tick
			if feinted_last:
				var particle_pos = get_hurtbox_center_float()
				spawn_particle_effect(preload("res://fx/FeintEffect.tscn"), particle_pos)
				
			state_machine._change_state(queued_action, queued_data)
			if !current_state().is_hurt_state:
				if !last_turn_block:
					hitlag_ticks = 0
				last_turn_block = false
			if !(current_state() is ParryState):
				if blocked_hitbox_plus_frames > 0:
					hitlag_ticks += blocked_hitbox_plus_frames
					blocked_hitbox_plus_frames = 0
			if pressed_feint:
				feinting = true
				current_state().feinting = true
		current_state().feinted_last = feinted_last
	queued_action = null
	queued_data = null
	queued_extra = null
	was_my_turn = false
	lowest_tick = current_state().current_real_tick

func process_action(queued_action):
	pass

func touching_which_wall():
	var col_box = get_collision_box()
	var vel = get_vel()
	var bounce = 0

	if (col_box.x1 <= -stage_width and fixed.le(vel.x, "0")):
		bounce = -1
	elif (col_box.x2 >= stage_width and fixed.ge(vel.x, "0")):
		bounce = 1
		
	return bounce

func turn_end_effects():
	pass

func turn_start_effects():
	pass

func toggle_quit_graphic(on=null):
	if on == null:
		quitter_label.visible = !quitter_label.visible
		if quitter_label.visible:
			play_sound("QuitterSound")
	else:
		quitter_label.visible = on
		if on:
			play_sound("QuitterSound")

func get_sadness_distance_penalty():
	if combo_count > 0 or opponent.is_in_hurt_state(false):
		return 1
	var pos = obj_local_center(opponent)
	var amount = 0
	if pos.y > 0:
		var dist = str(pos.y)
		amount = fixed.round(fixed.div(dist, DISTANCE_EXTRA_SADNESS))
#	print(amount)
	return 1 + amount

func can_be_thrown():
	return .can_be_thrown() and blockstun_ticks <= 0

func tick():
	if is_ghost and !is_grounded():
		ghost_was_in_air = true
	if hitlag_ticks > 0:
		if can_nudge:
			if fixed.round(fixed.mul(fixed.vec_len(current_nudge.x, current_nudge.y), "100.0")) > 1:
				current_nudge = fixed.vec_mul(current_nudge.x, current_nudge.y, nudge_amount)
				var di_scaled = get_scaled_di(current_di)
				var di_scaling = fixed.round(get_di_scaling())
#				for i in range(min(di_scaling, 2)):
				var particle = preload("res://fx/NudgeIndicator.tscn") if  di_scaling <= 2 else preload("res://fx/NudgeIndicatorStrong.tscn")
				spawn_particle_effect(particle, Vector2(get_pos().x, get_pos().y + hurtbox.y), Vector2(di_scaled.x, di_scaled.y).normalized())
#					spawn_particle_effect(preload("res://fx/NudgeIndicatorStrong.tscn"), Vector2(get_pos().x, get_pos().y + hurtbox.y), Vector2(di_scaled.x, di_scaled.y).normalized())
				move_directly(current_nudge.x, current_nudge.y if !is_grounded() else "0")
			can_nudge = false
		hitlag_ticks -= 1
		if hitlag_ticks == 0:
			if state_hit_cancellable:
				state_interruptable = true
				can_nudge = false
			if projectile_hit_cancelling:
				state_interruptable = true
				can_nudge = false
		turn_frames += 1
	elif blockstun_ticks > 0:
		blockstun_ticks -= 1
	else:
		turn_frames += 1
#		if current_tick > 1:
#			blocked_hitbox_plus_frames = 0
#			pass
		if projectile_hit_cancelling:
			state_interruptable = true
			can_nudge = false
		projectile_hit_cancelling = false
		
		if parried:
#			state_interruptable = true
			parried = false
			if current_state().get("parry_active"):
				current_state().parry_active = false
			var prev = previous_state()
			if prev and prev.get("parry_active"):
				prev.parry_active = false
		var minus_offset = 0 if id == 1 else 1
		state_tick()
	
		if in_blockstring:
			if !current_state().get("IS_NEW_PARRY"):
				in_blockstring = false
			
		if state_hit_cancellable:
			state_interruptable = true
			can_nudge = false

		if !current_state() is ThrowState and current_state().apply_pushback:
			chara.apply_pushback(get_opponent_dir())
		if is_grounded():
			used_air_dodge = false
			refresh_air_movements()
		current_tick += 1
		game_tick += 1
		if not (current_state().is_hurt_state) and !(opponent.current_state().is_hurt_state):
			var x_vel_int = chara.get_x_vel_int()
			if Utils.int_sign(x_vel_int) == Utils.int_sign(opponent.get_pos().x - get_pos().x):
				var multiplier = current_state().get_velocity_forward_meter_gain_multiplier()
#				print(multiplier)
				var super_gain = fixed.abs(fixed.mul(str(x_vel_int), multiplier))
				if !is_grounded():
					super_gain = fixed.mul(super_gain, AERIAL_VELOCITY_SUPER_GAIN_MODIFIER)
				super_gain = fixed.round(fixed.div(super_gain, str(VEL_SUPER_GAIN_DIVISOR)))
#				print(super_gain)
				var vel_gain_amount = Utils.int_max(super_gain, 0)
#				print("vel meter: " + str(vel_gain_amount))
				gain_super_meter(vel_gain_amount)
	#	if current_state().current_tick == -1:
	#		state_tick()

	if state_interruptable:
		update_grounded()
		
	if hit_during_armor:
		has_hyper_armor = false
		hit_during_armor = false
		
	if parried_last_state and current_tick - last_parry_tick >= AUTO_PARRY_TICKS:
		parried_last_state = false

	if wakeup_throw_immunity_ticks > 0:
		wakeup_throw_immunity_ticks -= 1

	if sadness_immunity_ticks > 0:
		sadness_immunity_ticks -= 1

	gain_burst_meter()
	update_data()
	if current_state().beats_backdash:
		buffer_moved_forward = true
	if current_state().backdash_iasa:
		buffer_moved_backward = true
	for particle in particles.get_children():
		particle.tick()
	any_available_actions = true
	can_update_sprite = true
	last_vel = get_vel()
	var pos = get_pos()

#	if opponent.combo_count > 0:
#		current_prediction = -1


	if !is_in_hurt_state() and !opponent.is_in_hurt_state() and combo_count <= 0 and penalty_ticks <= 0:
#		var dir = Utils.int_sign(last_pos.x - pos.x)
		passive_sadness_gain()
	
#	var penalty_add_amount = 0
#	if penalty_buffer > 0:
#		penalty_add_amount = (penalty_buffer / 10) + 1
#		if penalty_add_amount > penalty_buffer:
#			penalty_add_amount = penalty_buffer
#		add_penalty_directly(penalty_add_amount)
#		penalty_buffer -= penalty_add_amount
#		if penalty_buffer < 0:
#			penalty_buffer = 0
	
	last_pos = pos
	if penalty_ticks > 0:
		penalty_ticks -= 1
		if current_tick % 3 == 0 and hp > 0:
			take_damage(2, 1)
			if hp <= 0:
				hp = 1
	
	touching_wall = false
	var col_box = get_collision_box()
	var vel = last_vel
	if (col_box.x1 <= -stage_width and fixed.lt(vel.x, "0")):
		touching_wall = true
	if (col_box.x2 >= stage_width and fixed.gt(vel.x, "0")):
		touching_wall = true
	if !is_grounded():
		last_aerial_vel = last_vel
	if !(previous_state() is ParryState) or !(current_state() is ParryState):
		parried_last_state = false
	used_buffer = false

	grounded_last_frame = is_grounded()

#	lowest_tick = null
	if forfeit:
		forfeit_ticks += 1

	if forfeit and forfeit_ticks > 2:
		change_state("ForfeitExplosion")
		forfeit = false
	
	if buffered_global_hitlag:
		global_hitlag(buffered_global_hitlag)
		buffered_global_hitlag = 0


	if super_meter_grace_ticks > 0:
		super_meter_grace_ticks -= 1
		if super_meter_grace_ticks == 0:
			super_meter_used_recently = 0

	if ReplayManager.playback:
		if "emotes" in ReplayManager.frames:
			if current_tick in ReplayManager.frames.emotes[id]:
				emote(ReplayManager.frames.emotes[id][current_tick])

func passive_sadness_gain():
	var dir = fixed.sign(last_vel.x)
	var opp_dir = get_opponent_dir()
	if dir != 0 and dir != opp_dir and current_tick % 3 == 0:
		add_penalty(1)
	if dir != 0 and dir == opp_dir and current_tick % 4 == 0:
		if fixed.gt(fixed.abs(last_vel.x), "0.01"):
			add_penalty(-1)
	if current_tick % 7 == 0:
		add_penalty(get_sadness_distance_penalty())

func landing_effect():
	spawn_particle_effect_relative(preload("res://fx/LandingParticle.tscn"))
	play_sound("Landing")

func get_move_dir():
	return fixed.sign(last_vel.x)

func get_opponent_distance():
	return obj_distance(opponent)

func can_block_cancel():
	return true

func add_penalty(amount, ignore_min_distance=false):
	if !sadness_enabled:
		return

	if sadness_immunity_ticks > 0:
		return

	if amount > 0:
		if !ignore_min_distance:
			var opp_pos = obj_local_center(opponent)
			var opp_dist = fixed.vec_len(str(opp_pos.x), str(opp_pos.y))
			if fixed.lt(opp_dist, MIN_DIST_SADNESS):
				return
				
		var modifier = "1.0"
		if is_grounded() and !opponent.is_grounded():
			modifier = "0.25"
		elif !is_grounded() and opponent.is_grounded():
			modifier = "1.0"
		amount = fixed.round(fixed.mul(str(amount), modifier))
	else:
		var modifier = "1.0"
		if !is_grounded() and opponent.is_grounded():
			modifier = "0.75"
		amount = fixed.round(fixed.mul(str(amount), modifier))
	
	if hp < opponent.hp:
		var diff = Utils.int_abs(hp - opponent.hp)
		var ratio = fixed.sub("1", fixed.div(str(diff), "3000"))
#		print(ratio)
		amount = fixed.round(fixed.mul(str(amount), ratio))
	
#	print("adding penalty: " + str(amount))
	penalty += amount
	if penalty > MAX_PENALTY:
		supers_available = 0
		super_meter = 0
		penalty = 0
		penalty_buffer = 0
		penalty_ticks = PENALTY_TICKS
		had_sadness = true
	if penalty < MIN_PENALTY:
		penalty = MIN_PENALTY

func has_super_meter():
	return super_meter > 0 or supers_available > 0

func reset_penalty():
	penalty = 0

func is_in_hurt_state(count_all=true):
	var state = current_state()
	if count_all:
		return state.busy_interrupt_type == CharacterState.BusyInterrupt.Hurt or state.is_hurt_state
	else:
		return state.is_hurt_state

func set_ghost_colors():
	if not ghost_ready_set and (state_interruptable or dummy_interruptable or ghost_ready_tick!=null):
#		print(current_state().name)
		var first_color = Color.green
		var second_color = Color.orange
		ghost_ready_set = true
		if opponent.ghost_ready_tick == null or opponent.ghost_ready_tick == ghost_ready_tick:
			set_color(first_color)
			if (opponent.current_state().interruptible_on_opponent_turn or opponent.feinting or opponent.current_state().started_during_combo):
				opponent.ghost_ready_set = true
				opponent.set_color(first_color)
		elif ghost_ready_tick != null and opponent.ghost_ready_tick < ghost_ready_tick:
			set_color(second_color)

func set_facing(facing: int, force=false):
	if reverse_state and !force:
		facing *= -1
	.set_facing(facing)

func update_facing():
	if obj_data.position_x < opponent.obj_data.position_x:
		set_facing(1)
	elif obj_data.position_x > opponent.obj_data.position_x:
		set_facing(-1)
	if initialized:
		update_data()

func on_state_interruptable(state=null):
	if !dummy:
		state_interruptable = true
		was_my_turn = true
	else:
		dummy_interruptable = true
		refresh_prediction = true

func on_state_hit_cancellable(projectile=false, state=null):
	if !dummy:
		state_hit_cancellable = true
		refresh_prediction = true
		if projectile:
			projectile_hit_cancelling = true

func get_fighter():
	return self

func on_action_selected(action, data, extra):
#	if !state_interruptable:
#		return
	if you_label.visible:
		you_label.hide()
	queued_action = action
	queued_data = data
	queued_extra = extra
	state_interruptable = false
	state_hit_cancellable = false
	if action == "Undo":
		emit_signal("undo")
#	if action == "Forfeit":
#		emit_signal("forfeit")
	var state = state_machine.get_state(action)
	if state:
		if !state.is_usable():
			action = "Forfeit"
	emit_signal("action_selected", action, data, extra)


func drain_air_option_bar(amount):
	if infinite_resources:
		return
	air_option_bar -= amount
	if air_option_bar < 0:
		air_option_bar = 0

func gain_free_cancel(amount=1):
	feints += amount
	if feints > num_feints:
		feints = num_feints

func gain_air_option_bar(amount):
	air_option_bar += amount
	if air_option_bar > air_option_bar_max:
		air_option_bar = air_option_bar_max

func get_state_hash():
	var pos = get_pos()
	var vel = get_vel()
	return hash(pos.x) + hash(pos.y) + hash(vel.x) + hash(vel.y) + hash(current_di.x) + hash(current_di.y) + hash(current_state().state_name)

func start_sadness_immunity():
	sadness_immunity_ticks = SADNESS_IMMUNITY_TICKS

func should_free_cancel_allow_grounded_and_aerial_states():
	return true

func start_wakeup_throw_immunity():
	wakeup_throw_immunity_ticks = WAKEUP_THROW_IMMUNITY_TICKS

func forfeit():
	will_forfeit = true

func on_blocked_melee_attack():
	emit_signal("blocked_melee_attack")
	in_blockstring = true

func _draw():
#	draw_circle(Vector2(), 0.01, Color.transparent) # possible fix to esoteric graphics bug
#	if initiative:
#		draw_arc(Vector2(0, -16), 24, 0, TAU, 32, Color.green)
#	if state_interruptable:
#		draw_circle(Vector2(0, -16), 8, Color.red)
	pass
