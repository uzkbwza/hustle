tool

extends CollisionBox

class_name Hitbox, "res://addons/collision_box/hitbox.png"

const COMBO_PUSHBACK_COEFFICIENT = "0.4"
const COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_GROUNDED = "1.25"
const COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_AERIAL = "1.05"
const COMBO_SAME_MOVE_HITSTUN_DECREASE_AMOUNT = 1
const PRORATION_HITSTUN_ADJUSTMENT_AMOUNT = 0
const DEFAULT_HIT_PARTICLE = preload("res://fx/HitEffect1.tscn")

const MAX_KNOCKBACK = "30"


var HIT_PARTICLE = preload("res://fx/HitEffect1.tscn")

enum HitboxType {
	Normal,
	Flip,
	ThrowHit,
	OffensiveBurst,
	Burst,
	NoHitstun,
	Detect,
}

#const DAMAGE_SUPER_GAIN_DIVISOR = 1

signal hit_something(obj, hitbox)
signal got_parried()
signal got_blocked()

enum HitHeight {
	High
	Mid
	Low
}

export var activated = true

export var _c_Damage = 0
export var damage: int = 0
export var damage_in_combo: int = -1
export var minimum_damage: int = 0
export var chip_damage_modifier = "1.0"

export var _c_Hit_Properties = 0
export(HitboxType) var hitbox_type = HitboxType.Normal
export var hitstun_ticks: int = 30
export var combo_hitstun_ticks: int = -1
export var hitlag_ticks: int = 4
export var victim_hitlag: int = -1
export var combo_victim_hitlag: int = -1
export var damage_proration: int = 0
export var scale_combo = true
export var combo_scaling_amount: int = 1
export var cancellable = true
export var increment_combo = true
export var hits_otg = false
export var hits_vs_standing = true
export var hits_vs_grounded = true
export var hits_vs_aerial = true
export var can_counter_hit = true
export var di_modifier = "1.0"
export var sdi_modifier = "1.0"
export var meter_gain_modifier = "1.0"
export var parry_meter_gain = -1
export var ignore_armor = false
export var followup_state = ""
export var force_grounded = false
export var can_clash = true
export var hits_vs_dizzy = true
export var beats_grab = true
export var hits_projectiles = true
export var ignore_projectile_armor = false
export var allowed_to_hit_own_team = true

export var _c_Block_Properties = 0
export var guard_break = false
export var guard_break_proration = 1
export var block_punishable = false
export var parriable = true
export var block_cancel_allowed = true

export(int, -1024, 1024) var plus_frames = 0

export(HitHeight) var hit_height = HitHeight.Mid

export var _c_Grouping = 0
# when multiple hitboxes are overlapping an opponent, the highest-priority hitbox will be chosen
export var priority: int = 0

# grouped hitboxes are considered to be part of the same continuous attack.
# use this if you want attacks that use multiple hitboxes over time
# but are not multi-hitting attacks
export var group: int = 0

export var _c_Fx = 0
export var screenshake_amount: int = 4
export var screenshake_frames: int = -1
export(PackedScene) var hit_particle
export var replace_hit_particle = false
export var camera_bump_dir = Vector2()
export(PackedScene) var whiff_particle = null
export var bump_on_whiff = false
export var rumble = true

export var _c_Sfx = 0
export(AudioStream) var whiff_sound = preload("res://sound/common/whiff1.wav") 
export(AudioStream) var hit_sound = preload("res://sound/common/hit1.wav") 
export(AudioStream) var hit_bass_sound = preload("res://sound/common/hit_bass.wav")
export var whiff_sound_volume = -8.0
export var hit_sound_volume = -5.0
export var bass_sound_volume = -5.0
export var bass_on_whiff = false

export var _c_Knockback = 0
export var dir_x: String = "1.0"
export var dir_y: String = "-1.0"
export var knockback: String = "10.0"
export var launch_reversible = false
export var vacuum = false
export var send_away_from_center = false
export var block_pushback_modifier: String = "1.0"
export var block_pushback_reversible = false
export var block_reverse_pushback_modifier: String = "1.0"
export var pushback_x: String = "1.0"

export var _c_Knockback_Type = 0
export var grounded_hit_state = "HurtGrounded"
export var aerial_hit_state = "HurtAerial"
export var minimum_grounded_frames = -1
export var knockdown = false
export var knockdown_extends_hitstun = true # if true, aerial victim will stay in hitstun until hitting the ground
export var hard_knockdown = false
export var disable_collision = true
export var air_ground_bounce = false
export var ground_bounce = true
export var ground_bounce_knockback_modifier = "1.0"
export var wall_slam = false

export var _c_Frame_Data = 0
export var start_tick: int = 0
export var active_ticks: int = 5
export var always_on = false

export var _c_Loop_Data = 0
export var looping = false
export var loop_active_ticks: int = 2
export var loop_inactive_ticks: int = 2

export var _c_Misc = 0
export(String, MULTILINE) var misc_data = ""

var tick: int = 1
var host
var active = false # is the hitbox started
var enabled = false # will it actually hit you
var spawn_particle_effect = true
var throw = false
var played_whiff_sound = false

var grouped_hitboxes = []

var hit_objects = []

var whiff_sound_player
var hit_sound_player
var hit_bass_sound_player

var native = null

var property_list: PoolStringArray

func copy_to(hitbox: CollisionBox):
	if hitbox == null:
		return
	hitbox.property_list = property_list
	native.copy_state(self, hitbox)

func is_projectile():
	return !host.is_in_group("Fighter")

func setup_audio():
	if !host.is_ghost:
		if whiff_sound:
			whiff_sound_player = VariableSound2D.new()
			call_deferred("add_child", whiff_sound_player)
			whiff_sound_player.bus = "Fx"
			whiff_sound_player.stream = whiff_sound
			whiff_sound_player.volume_db = whiff_sound_volume

		if hit_sound:
			hit_sound_player = VariableSound2D.new()
			call_deferred("add_child", hit_sound_player)
			hit_sound_player.bus = "Fx"
			hit_sound_player.stream = hit_sound
			hit_sound_player.volume_db = hit_sound_volume
			
		if hit_bass_sound:
			hit_bass_sound_player = VariableSound2D.new()
			call_deferred("add_child", hit_bass_sound_player)
			hit_bass_sound_player.bus = "Fx"
			hit_bass_sound_player.stream = hit_bass_sound
			hit_bass_sound_player.volume_db = bass_sound_volume

func play_whiff_sound():
	if ReplayManager.resimulating or host.is_ghost:
		return
	if whiff_sound_player:
		var can_play_whiff_sound = true
		for hitbox in grouped_hitboxes:
			if hitbox.played_whiff_sound:
				can_play_whiff_sound = false
				break
		if can_play_whiff_sound:
			played_whiff_sound = true
			whiff_sound_player.play()
			if bass_on_whiff and hit_bass_sound_player:
				hit_bass_sound_player.play()

func activate():
	if active:
		return
	update_position(host.get_pos().x, host.get_pos().y)
	spawn_whiff_particle()
	play_whiff_sound()
	tick = 0
	active = true
	enabled = true
	if host.is_in_group("Fighter"):
		cancellable = cancellable or (bool(host.get("turbo_mode")) and !throw)
	if victim_hitlag == -1:
		victim_hitlag = hitlag_ticks
	if combo_victim_hitlag == -1:
		combo_victim_hitlag = victim_hitlag
	if bump_on_whiff and !host.is_ghost:
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		camera.bump(camera_bump_dir, screenshake_amount, Utils.frames(victim_hitlag if screenshake_frames < 0 else screenshake_frames))

func deactivate():
	played_whiff_sound = false
	active = false
	enabled = false
	hit_objects = []

func to_data():
	return HitboxData.new(self)

func is_counter_hit():
	if host.is_in_group("Fighter"):
		if host.counterhit_this_turn:
			return true
		pass
	return can_counter_hit and (host.is_in_group("Fighter") and host.initiative and host.opponent.current_state().has_hitboxes and host.opponent.current_state().can_be_counterhit) or (host.is_in_group("Fighter") and host.opponent.current_state().is_brace and !host.opponent.can_counter_hitbox(self))

func spawn_whiff_particle():
	if whiff_particle:
		var center = get_center()
		host.spawn_particle_effect(whiff_particle, Vector2(center.x, center.y), Vector2(x_facing(), 0))

func spawn_particle(particle, obj, dir):
	host.spawn_particle_effect(particle, get_hit_particle_location(obj.hurtbox), dir)

func init():
	if height < 0:
		height *= -1
	if width < 0:
		width *= -1
	if combo_hitstun_ticks == -1:
		combo_hitstun_ticks = hitstun_ticks
	if hitbox_type == HitboxType.Detect:
		can_clash = false
	update_property_list()
	call_deferred("setup_audio")

func update_property_list():
	if !host.is_ghost:
		property_list = Utils.get_copiable_properties(self)

func get_real_knockback():
	var creator = host.get_fighter()
	if creator:
		if !host.is_in_group("Fighter"):
			return knockback
		if not (creator.current_state().state_name in creator.combo_moves_used):
			return knockback
		var knockback_modifier = creator.fixed.powu(COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_GROUNDED if creator.opponent.is_grounded() else COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_AERIAL, creator.combo_moves_used[creator.current_state().state_name])
		var final_kb = creator.fixed.mul(knockback, knockback_modifier)
		if creator.fixed.gt(final_kb, MAX_KNOCKBACK):
			final_kb = MAX_KNOCKBACK
#		var max_kb = host.fixed.mul(knockback, "2")
#		if host.fixed.gt(final_kb, max_kb):
#			return max_kb
#		else:
		return final_kb
	else:
		return knockback

#
#func get_real_damage():
#	var is_combo = false
#	if host.is_in_group("Fighter"):
#		is_combo = host.combo_count > 0
#	else:
#		if host.fighter_owner:
#			is_combo = host.fighter_owner.combo_count > 0
#	if is_combo and damage_in_combo != -1:
#		return damage_in_combo
#	return damage

func get_real_hitstun():
	var creator = host.get_fighter()
	if creator:
		var ticks = hitstun_ticks if creator.combo_count <= 0 else combo_hitstun_ticks
		var started_above_0 = ticks > 0
		if creator.combo_proration > 1:
			ticks -= PRORATION_HITSTUN_ADJUSTMENT_AMOUNT * (creator.combo_proration - 1)
			
		if host.is_in_group("Fighter"):
			if (creator.current_state().state_name in creator.combo_moves_used):
				ticks = Utils.int_max(ticks - (COMBO_SAME_MOVE_HITSTUN_DECREASE_AMOUNT * (creator.combo_moves_used[creator.current_state().state_name] + 1)), ticks / 2)
		if started_above_0 and ticks <= 0:
			ticks = 1
		return ticks
	else:
		return hitstun_ticks

func get_real_victim_hitlag():
	var creator = host.get_fighter()
	if creator: 
		return victim_hitlag if creator.combo_count <= 0 else combo_victim_hitlag
	else:
		return victim_hitlag

func otg_check(obj):
	return !obj.is_otg() or hits_otg

func save_hit_object(obj):
	for hitbox in grouped_hitboxes:
		hitbox.hit_objects.append(obj.name)

func already_hit_object(obj):
	for hitbox in grouped_hitboxes:
		if obj.obj_name in hitbox.hit_objects:
			return true

func hit(obj):
	if !(obj.name in hit_objects) and (!obj.invulnerable or hitbox_type == HitboxType.ThrowHit) and otg_check(obj):
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		var dir = get_dir_float(true)
		if grounded_hit_state is String and grounded_hit_state == "HurtGrounded" and obj.is_grounded():
				dir.y *= 0
		save_hit_object(obj)
		if hitbox_type == HitboxType.Detect:
			host.detect(obj)
			return
		obj.hit_by(self.to_data())
		var can_hit = true
		if obj.is_in_group("Fighter"):
			if host.is_in_group("Fighter"):
				if host.current_state().end_feint:
					host.feinting = false
					host.current_state().feinting = false
			if !host.is_ghost:
				if !bump_on_whiff:
					var length = Utils.frames(victim_hitlag if screenshake_frames < 0 else screenshake_frames) * float(obj.global_hitstop_modifier)
#					length = length + (length * (Fighter.GLOBAL_HITLAG_MODIIFER if (Global.replay_extra_freeze_frames and !obj.is_ghost) else 0))
					camera.bump(camera_bump_dir, screenshake_amount, length)
			if obj.can_parry_hitbox(self) or name in obj.parried_hitboxes:
				can_hit = false
				emit_signal("got_parried")
			if obj.can_counter_hitbox(self):
				can_hit = false
			if obj.on_the_ground:
				if !hits_otg:
					can_hit = false

			if !hits_vs_dizzy:
				if obj.current_state().state_name == "HurtDizzy":
					can_hit = false
		if can_hit and spawn_particle_effect:
			if hit_particle:
				spawn_particle(hit_particle, obj, dir)
			if !replace_hit_particle:
				spawn_particle(HIT_PARTICLE if Global.enable_custom_hit_sparks else DEFAULT_HIT_PARTICLE, obj, dir)

		if can_hit:
			var pushback_modifier = host.fixed.mul(str(host.hitstun_decay_combo_count) if host.is_in_group("Fighter") else "0", COMBO_PUSHBACK_COEFFICIENT)
			var pushback = host.fixed.mul(host.fixed.add(pushback_x, pushback_modifier), "-1")
			pushback = host.fixed.div(pushback, "2")
			host.add_pushback(pushback)
			obj.add_pushback(pushback)
			var opponent = obj.get("opponent")
			
			if opponent:
				if opponent != host:
					opponent.add_pushback(pushback)
			if hit_sound_player and !ReplayManager.resimulating:
				hit_sound_player.play()
				if !bass_on_whiff:
					hit_bass_sound_player.play()
			emit_signal("hit_something", obj, self)

func get_facing_int():
	return -1 if facing == "Left" else 1

func get_angle_float(facing=false):
	# for aesthetic purposes
	return get_dir_float(facing).angle()

func get_dir_float(facing=false):
	# for aesthetic purposes
	return Vector2(float(dir_x) * (get_facing_int() if facing else 1), float(dir_y))

func can_draw_box():
	if Global.get("show_hitboxes"):
		return (active and enabled and Global.show_hitboxes)
	else:
		return .can_draw_box()

func add_hit_object(obj_name):
	for hitbox in grouped_hitboxes:
		if !(obj_name in hitbox.hit_objects):
			hitbox.hit_objects.append(hitbox)

func reset_hit_objects():
	hit_objects.clear()
	for hitbox in grouped_hitboxes:
		hitbox.hit_objects.clear()
	if active and enabled:
		deactivate()
		activate()

func tick():
	var pos = host.get_pos()
	update_position(pos.x, pos.y)
	if looping:
		var loop_tick = tick % (loop_active_ticks + loop_inactive_ticks)
		var prev_enabled = enabled
		enabled = loop_tick < loop_active_ticks
		if !enabled and prev_enabled:
			for hitbox in grouped_hitboxes:
				hitbox.hit_objects.clear()
			played_whiff_sound = false
		if enabled and !prev_enabled:
			play_whiff_sound()
	tick += 1
	if tick > active_ticks:
		if !always_on:
			deactivate()

	update()
