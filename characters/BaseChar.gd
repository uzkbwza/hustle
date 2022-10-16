extends BaseObj

class_name Fighter

signal action_selected(action, data)
signal undo()

const MAX_HEALTH = 1000
const STALING_REDUCTION = "0.075"
const MAX_STALES = 10

const GUTS_REDUCTION = "0.05"
const MAX_GUTS = 6

const MAX_DI_COMBO_ENHANCMENT = 10

const MAX_BURSTS = 1
const BURST_BUILD_SPEED = 2
const MAX_BURST_METER = 1500
const START_BURSTS = 1

const MAX_SUPER_METER = 150
const MAX_SUPERS = 9
const VEL_SUPER_GAIN_DIVISOR = 3

#const NUDGE_SPEED = "2.0"
const NUDGE_DISTANCE = 20

const PARRY_METER = 50

export var num_air_movements = 2

export(Texture) var character_portrait

onready var you_label = $YouLabel

var input_state = InputState.new()

var opponent

var queued_action = null
var queued_data = null
var queued_extra = null

var game_over = false

var colliding_with_opponent = true

var air_movements_left = 0

var action_cancels = {
}

var hp: int = 0
var super_meter: int = 0
var supers_available: int = 0

var burst_meter: int = 0
var bursts_available: int = 0

var busy_interrupt = false
var any_available_actions = true

var current_nudge = {
	"x": "0",
	"y": "0",
}

var current_di = {
	"x": "0",
	"y": "0",
}
var nudge_distance_left = 0

var can_nudge = false
var parried = false

var stance = "Normal"

var parried_hitboxes = []

var throw_pos_x = 16
var throw_pos_y = -5

class InputState:
	var name
	var data

func init():
	.init()
	if !is_ghost:
		Network.player_objects[id] = self
	hp = MAX_HEALTH
	game_over = false
	show_you_label()
	bursts_available = START_BURSTS

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
	for state in state_machine.get_children():
		if state is CharacterState:
			for category in state.interrupt_from:
				if !action_cancels.has(category):
					action_cancels[category] = []
				if !(state in action_cancels[category]):
					action_cancels[category].append(state)
	state_variables.append_array(
		["current_di", "current_nudge", "air_movements_left", "super_meter", "supers_available", "parried", "parried_hitboxes", "burst_meter", "bursts_available"]
	)
	setup_hitbox_names()

func gain_burst_meter():
	if bursts_available < MAX_BURSTS:
		burst_meter += BURST_BUILD_SPEED
		if burst_meter > MAX_BURST_METER:
			gain_burst()

func copy_to(f: BaseObj):
	.copy_to(f)
	f.update_data()
#	f.update_data()

func gain_burst():
	if bursts_available < MAX_BURSTS:
		bursts_available += 1
		burst_meter = 0

func use_burst():
	bursts_available -= 1
	refresh_air_movements()

func use_super_bar():
	supers_available -= 1

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
	var combo = Utils.int_min(combo_count, MAX_STALES)
	if combo == 0:
		return meter
	var modifier = fixed.mul(str(combo), STALING_REDUCTION)
	return fixed.round(fixed.mul(str(meter), fixed.sub("1.0", modifier)))
	
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

func incr_combo():
	combo_count += 1

func is_colliding_with_opponent():
	return colliding_with_opponent or hitlag_ticks > 0

func thrown_by(hitbox: ThrowBox):
	state_machine._change_state("Grabbed")

func hitbox_from_name(hitbox_name):
		var hitbox_props = hitbox_name.split("_")
		var obj_name = hitbox_props[0]
		var hitbox_id = int(hitbox_props[-1])
		return objs_map[obj_name].hitboxes[hitbox_id]

func hit_by(hitbox):
	if hitbox.name in parried_hitboxes:
		return
	if hitbox.throw:
		return thrown_by(hitbox)
	if !can_parry_hitbox(hitbox):
		var state
		if is_grounded():
			state = hitbox.grounded_hit_state
		else:
			state = hitbox.aerial_hit_state
		if hitlag_ticks < hitbox.hitlag_ticks:
			hitlag_ticks = hitbox.hitlag_ticks
		state_machine._change_state(state, {"hitbox": hitbox})
	#	state_interruptable = false
		busy_interrupt = true
		can_nudge = true
	#	reset_combo()
		take_damage(hitbox.damage)
		state_tick()
	else:
		parried = true
		hitlag_ticks = (hitbox.hitlag_ticks * 2) / 3
		parried_hitboxes.append(hitbox.name)
		var particle_location = current_state().get("particle_location")
		particle_location.x *= get_facing_int()
		if !particle_location:
			particle_location = hitbox.get_overlap_center_float(hurtbox)
		gain_super_meter(PARRY_METER)
		spawn_particle_effect(preload("res://fx/ParryEffect.tscn"), get_pos_visual() + particle_location)

func set_throw_position(x: int, y: int):
	throw_pos_x = x
	throw_pos_y = y

func get_center_position_float():
	return Vector2(position.x + collision_box.x, position.y + collision_box.y)

func take_damage(damage: int):
	hp -= guts_stale_damage(combo_stale_damage(damage))

func guts_stale_damage(damage: int):
	var dmg = Utils.int_min((MAX_HEALTH - hp) / 10, MAX_GUTS)
	if dmg == 0:
		return damage
	var modifier = fixed.mul(str(dmg), GUTS_REDUCTION)

	return fixed.round(fixed.mul(str(damage), fixed.sub("1.0", modifier)))

func combo_stale_damage(damage: int):
	var combo = Utils.int_min(opponent.combo_count, MAX_STALES)
	if combo == 0:
		return damage
	var modifier = fixed.mul(str(combo), STALING_REDUCTION)
	return fixed.round(fixed.mul(str(damage), fixed.sub("1.0", modifier)))

func can_parry_hitbox(hitbox):
	if not current_state() is ParryState:
		return false
	return current_state().can_parry_hitbox(hitbox)

func get_extra_data():
	var data = {}
	return data

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
			if queued_action != "ContinueAuto":
				if !is_ghost:
					ReplayManager.frames[id][current_tick] = {
						"action": queued_action,
						"data": queued_data,
						"extra": queued_extra,
					}
			else:
				queued_action = null
	if queued_action:
		if queued_action in state_machine.states_map:
			state_machine.queue_state(queued_action, queued_data)
	if queued_extra:
		if "DI" in queued_extra:
			var di = queued_extra["DI"]
			nudge_distance_left = NUDGE_DISTANCE
			current_nudge = xy_to_dir(di.x, di.y, str(NUDGE_DISTANCE))
			current_di = xy_to_dir(di.x, di.y, fixed.add("1.0", fixed.mul("1.0", fixed.div(str(Utils.int_min(MAX_DI_COMBO_ENHANCMENT, opponent.combo_count)), "10"))))
	
func refresh_air_movements():
	air_movements_left = num_air_movements

func clean_parried_hitboxes():
	if !parried_hitboxes:
		return
	var hitboxes_to_refresh = []
	for hitbox_name in parried_hitboxes:
		var hitbox = hitbox_from_name(hitbox_name)
		if !hitbox.active:
			hitboxes_to_refresh.append(hitbox)
	
	for hitbox in hitboxes_to_refresh:
		parried_hitboxes.erase(hitbox.name)

func get_opponent_dir():
	return sign(opponent.get_pos().x - get_pos().x)

func tick():
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
		chara.apply_pushback()
		if is_grounded():
			refresh_air_movements()
		current_tick += 1
		if not (state_machine.state is CharacterHurtState):
			var x_vel_int = chara.get_x_vel_int()
			if sign(x_vel_int) == sign(opponent.get_pos().x - get_pos().x):
				gain_super_meter(abs(x_vel_int) / VEL_SUPER_GAIN_DIVISOR)
	#	if current_state().current_tick == -1:
	#		state_tick()

	gain_burst_meter()
	update_data()
	for particle in particles.get_children():
		particle.tick()
	any_available_actions = true

func update_facing():
	if obj_data.position_x < opponent.obj_data.position_x:
		set_facing(1)
	elif obj_data.position_x > opponent.obj_data.position_x:
		set_facing(-1)

func on_state_interruptable(state):
	if !dummy:
		state_interruptable = true

func on_state_hit_cancellable(state):
	if !dummy:
#		state_interruptable = true
		state_hit_cancellable = true

func on_action_selected(action, data, extra):
	if !state_interruptable:
		return
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
