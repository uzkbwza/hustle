extends BaseObj

class_name Fighter

signal action_selected(action, data)
signal super_started()
signal parried()

signal undo()
var MAX_HEALTH = 1000
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

const DAMAGE_SUPER_GAIN_DIVISOR = 1
const DAMAGE_TAKEN_SUPER_GAIN_DIVISOR = 3
const HITLAG_COLLISION_TICKS = 4

const MAX_GROUNDED_HITS = 7

const GUTS_REDUCTIONS = {
	"1": "1",
#	"0.90": "1.10",
#	"0.80": "1.0",
	"0.70": "0.90",
	"0.60": "0.80",
	"0.50": "0.70",
	"0.40": "0.60",
	"0.30": "0.55",
	"0.20": "0.52",
	"0.10": "0.50",
}

const MAX_GUTS = 10

const MAX_DI_COMBO_ENHANCMENT = 15

const MAX_BURSTS = 1
const BURST_BUILD_SPEED = 4
const MAX_BURST_METER = 1500
const START_BURSTS = 1

const MAX_SUPER_METER = 125
const MAX_SUPERS = 9
const VEL_SUPER_GAIN_DIVISOR = 4

#const NUDGE_SPEED = "2.0"
const NUDGE_DISTANCE = 20

const PARRY_METER = 50
const METER_GAIN_MODIFIER = "1.0"

export var num_air_movements = 2

export(Texture) var character_portrait

onready var you_label = $YouLabel
onready var actionable_label = $ActionableLabel

var input_state = InputState.new()

export(PackedScene) var player_info_scene
export(PackedScene) var player_extra_params_scene

var opponent

var queued_action = null
var queued_data = null
var queued_extra = null

var dummy_interruptable = false

var game_over = false

var colliding_with_opponent = true

var air_movements_left = 0

var action_cancels = {
}

var ghost_ready_tick = null
var ghost_ready_set = false
var got_parried = false

var di_enabled = true
var turbo_mode = false
var infinite_resources = false
var one_hit_ko = false
var burst_enabled = true

var trail_hp: int = MAX_HEALTH
var hp: int = 0
var super_meter: int = 0
var supers_available: int = 0

var burst_meter: int = 0
var bursts_available: int = 0
#var parried_this_frame = false
var busy_interrupt = false
var any_available_actions = true

var on_the_ground = false

var current_nudge = {
	"x": "0",
	"y": "0",
}

var current_di = {
	"x": "0",
	"y": "0",
}

var reverse_state = false
var ghost_reverse = false

var nudge_distance_left = 0

var can_nudge = false
var parried = false

var stance = "Normal"

var parried_hitboxes = []

var grounded_hits_taken = 0

var throw_pos_x = 16
var throw_pos_y = -5

var combo_damage = 0
var hitlag_applied = 0

class InputState:
	var name
	var data

func init(pos=null):
	.init(pos)
	if !is_ghost:
		Network.player_objects[id] = self
		
	if one_hit_ko:
		MAX_HEALTH = 1
	hp = MAX_HEALTH
	game_over = false
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

func start_super():
	emit_signal("super_started")

func change_stance_to(stance):
	self.stance = stance

func show_you_label():
	if is_you():
		you_label.show()

func is_you():
	if Network.multiplayer_active:
		return id == Network.player_id
	return false

func _ready():
	sprite.animation = "Wait"

	state_variables.append_array(
		["current_di", "current_nudge", "reverse_state", "parried", "got_parried", "parried_this_frame", "grounded_hits_taken", "on_the_ground", "hitlag_applied", "combo_damage", "burst_enabled", "di_enabled", "turbo_mode", "infinite_resources", "one_hit_ko", "dummy_interruptable", "air_movements_left", "super_meter", "supers_available", "parried", "parried_hitboxes", "burst_meter", "bursts_available"]
	)

func gain_burst_meter():
	if !burst_enabled:
		return
	if bursts_available < MAX_BURSTS:
		burst_meter += BURST_BUILD_SPEED
		if burst_meter > MAX_BURST_METER:
			gain_burst()

func copy_to(f):
	.copy_to(f)
	f.update_data()
	f.set_facing(get_facing_int(), true)
	f.update_data()

func gain_burst():
	if bursts_available < MAX_BURSTS:
		bursts_available += 1
		burst_meter = 0

func use_burst():
	if infinite_resources:
		return
	bursts_available -= 1
	refresh_air_movements()

func use_super_bar():
	if infinite_resources:
		return
	supers_available -= 1
	if supers_available < 0:
		supers_available = 0
		super_meter = 0

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

func gain_super_meter(amount):
	amount = combo_stale_meter(amount)
	super_meter += amount
	if super_meter > MAX_SUPER_METER:
		if supers_available < MAX_SUPERS:
			super_meter -= MAX_SUPER_METER
			supers_available += 1
		else:
			super_meter = MAX_SUPER_METER
			
func combo_stale_meter(meter: int):
	var staling = get_combo_stale(combo_count)
	return fixed.round(fixed.mul(fixed.mul(str(meter), staling), METER_GAIN_MODIFIER))
	
func update_data():
	data = get_data()
	obj_data = data["object_data"]
	data["state_data"] = {
		"state": current_state().state_name,
		"frame": current_state().current_tick,
		"combo count": combo_count,
	}

func get_playback_input():
	if ReplayManager.playback:
		if get_frames().has(current_tick):
			return get_frames()[current_tick]

func get_global_throw_pos():
	var pos = get_pos()
	pos.x += throw_pos_x * get_facing_int()
	pos.y += throw_pos_y
	return pos

func reset_combo():
	combo_count = 0
	combo_damage = 0
	opponent.trail_hp = opponent.hp

func incr_combo():
	combo_count += 1

func is_colliding_with_opponent():
	return (colliding_with_opponent or (hitlag_applied - hitlag_ticks) < HITLAG_COLLISION_TICKS) and current_state().state_name != "Grabbed"

func thrown_by(hitbox: ThrowBox):
	emit_signal("got_hit")
	state_machine._change_state("Grabbed")

func hitbox_from_name(hitbox_name):
		var hitbox_props = hitbox_name.split("_")
		var obj_name = hitbox_props[0]
		var hitbox_id = int(hitbox_props[-1])
		var obj = objs_map[obj_name]
		return objs_map[obj_name].hitboxes[hitbox_id]

func hit_by(hitbox):
	if parried:
		return
	if hitbox.name in parried_hitboxes:
		return
	if !hitbox.hits_otg and current_state().state_name == "Knockdown":
		return
	if hitbox.throw:
		return thrown_by(hitbox)
	if !can_parry_hitbox(hitbox):
		var state
		if is_grounded():
			state = hitbox.grounded_hit_state
		else:
			state = hitbox.aerial_hit_state
#		if hitlag_ticks < hitbox.victim_hitlag:
		hitlag_ticks = hitbox.victim_hitlag
		hitlag_applied = hitbox.victim_hitlag
		
		if objs_map.has(hitbox.host):
			var host = objs_map[hitbox.host]
			if host.hitlag_ticks < hitbox.hitlag_ticks:
				host.hitlag_ticks = hitbox.hitlag_ticks
		
		if hitbox.rumble:
			rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
		
		if state == "HurtGrounded":
			grounded_hits_taken += 1
			if grounded_hits_taken >= MAX_GROUNDED_HITS:
				state = "HurtAerial"
				grounded_hits_taken = 0
		state_machine._change_state(state, {"hitbox": hitbox})
		if hitbox.disable_collision:
			colliding_with_opponent = false
	#	state_interruptable = false
		busy_interrupt = true
		can_nudge = true
	#	reset_combo()
		emit_signal("got_hit")
		take_damage(hitbox.damage)
		state_tick()
	else:
		parried = true
		opponent.got_parried = true
#		hitlag_ticks = (hitbox.hitlag_ticks * 2) / 3
#		hitlag_ticks = (hitbox.hitlag_ticks * 2) / 3
		hitlag_ticks = 0
		parried_hitboxes.append(hitbox.name)
		var particle_location = current_state().get("particle_location")
		particle_location.x *= get_facing_int()
		
		if !particle_location:
			particle_location = hitbox.get_overlap_center_float(hurtbox)
		current_state().parry()
		gain_super_meter(PARRY_METER)
		spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), get_pos_visual() + particle_location)
		play_sound("Parry")
		play_sound("Parry2")
		emit_signal("parried")

func set_throw_position(x: int, y: int):
	throw_pos_x = x
	throw_pos_y = y

func get_center_position_float():
	return Vector2(position.x + collision_box.x, position.y + collision_box.y)

func take_damage(damage: int):
	if opponent.combo_count == 0:
		trail_hp = hp
	if damage == 0:
		return
	damage = Utils.int_max(guts_stale_damage(combo_stale_damage(damage)), 1)
	opponent.combo_damage += damage
	hp -= damage
	opponent.gain_super_meter(damage / DAMAGE_SUPER_GAIN_DIVISOR)
	gain_super_meter(damage / DAMAGE_TAKEN_SUPER_GAIN_DIVISOR)

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

func combo_stale_damage(damage: int):
	var staling = get_combo_stale(opponent.combo_count)
	return fixed.round(fixed.mul(str(damage), staling))

func can_parry_hitbox(hitbox):
	if not current_state() is ParryState:
		return false
	return current_state().can_parry_hitbox(hitbox)

func process_action():
	if ReplayManager.playback:
		var input = get_playback_input()
		if input:
			queued_action = input["action"]
			queued_data = input["data"]
			queued_extra = input["extra"]
	else:
		if queued_action:
			if queued_action == "Undo":
				queued_action = null
				queued_data = null
				return
#			if queued_action != "ContinueAuto":
			if !is_ghost:
				ReplayManager.frames[id][current_tick] = {
					"action": queued_action,
					"data": queued_data,
					"extra": queued_extra,
				}
#			else:
#				queued_action = null
	if queued_action:
		if queued_action in state_machine.states_map:
			state_machine.queue_state(queued_action, queued_data)
	if queued_extra:
		process_extra(queued_extra)

func set_color(color: Color):
	sprite.get_material().set_shader_param("color", color)

func release_opponent():
	if opponent.current_state().state_name == "Grabbed":
		opponent.change_state("Fall")

func process_extra(extra):
	if "DI" in extra:
		if di_enabled:
			var di = extra["DI"]
			nudge_distance_left = NUDGE_DISTANCE
			current_nudge = xy_to_dir(di.x, di.y, str(NUDGE_DISTANCE))
			current_di = xy_to_dir(di.x, di.y, fixed.add("1.0", fixed.mul("1.0", fixed.div(str(Utils.int_min(MAX_DI_COMBO_ENHANCMENT, opponent.combo_count)), "5"))))
		else:
			current_di = FixedVec2String.new(0, 0)
	if "reverse" in extra:
		reverse_state = extra["reverse"]
		if reverse_state:
			ghost_reverse = true

func refresh_air_movements():
	air_movements_left = num_air_movements

func clean_parried_hitboxes():
	if is_ghost:
		return
	if !parried_hitboxes:
		return
	var hitboxes_to_refresh = []
	for hitbox_name in parried_hitboxes:
		var hitbox = hitbox_from_name(hitbox_name)
#		if hitbox:
		if !hitbox.enabled or !hitbox.active:
			hitboxes_to_refresh.append(hitbox)
	
	for hitbox in hitboxes_to_refresh:
		parried_hitboxes.erase(hitbox.name)

func get_opponent_dir():
	return Utils.int_sign(opponent.get_pos().x - get_pos().x)

func tick():
	dummy_interruptable = false
	clean_parried_hitboxes()
	busy_interrupt = false
	update_grounded()
	if !game_over:
		process_action()
		queued_action = null
		queued_data = null
		queued_extra = null

	if hitlag_ticks > 0:
		if can_nudge:
			if fixed.round(fixed.mul(fixed.vec_len(current_nudge.x, current_nudge.y), "100.0")) > 1:
				spawn_particle_effect(preload("res://fx/NudgeIndicator.tscn"), Vector2(get_pos().x, get_pos().y + hurtbox.y), Vector2(current_di.x, current_di.y).normalized())
				move_directly(current_nudge.x, current_nudge.y if !is_grounded() else "0")
			can_nudge = false
		hitlag_ticks -= 1
		if hitlag_ticks == 0:
			if state_hit_cancellable:
				state_interruptable = true
				can_nudge = false
	else:
		if parried:
			state_interruptable = true
			if current_state().get("parry_active"):
				current_state().parry_active = false
				parried = false
		state_tick()
		if state_hit_cancellable:
			state_interruptable = true
			can_nudge = false
		chara.apply_pushback(get_opponent_dir())
		if is_grounded():
			refresh_air_movements()
		current_tick += 1
		if not (current_state().is_hurt_state) and !(opponent.current_state().is_hurt_state):
			var x_vel_int = chara.get_x_vel_int()
			if Utils.int_sign(x_vel_int) == Utils.int_sign(opponent.get_pos().x - get_pos().x):
				gain_super_meter(Utils.int_max(Utils.int_abs(x_vel_int) / VEL_SUPER_GAIN_DIVISOR, 1))
	#	if current_state().current_tick == -1:
	#		state_tick()
	if state_interruptable:
		update_grounded()
	gain_burst_meter()
	update_data()
	for particle in particles.get_children():
		particle.tick()
	any_available_actions = true

func set_ghost_colors():
	if !ghost_ready_set and (state_interruptable or dummy_interruptable):
		ghost_ready_set = true
		ghost_ready_tick = current_tick
		if opponent.ghost_ready_tick == null or opponent.ghost_ready_tick == ghost_ready_tick:
			set_color(Color.green)
			if opponent.current_state().interruptible_on_opponent_turn:
				opponent.ghost_ready_set = true
				opponent.set_color(Color.green)
		elif opponent.ghost_ready_tick < ghost_ready_tick:
			set_color(Color.orange)

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

func on_state_interruptable(state):
	grounded_hits_taken = 0
	if !dummy:
		state_interruptable = true
	else:
		dummy_interruptable = true

func on_state_hit_cancellable(state):
	if !dummy:
		state_hit_cancellable = true

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
	emit_signal("action_selected", action, data, extra)
