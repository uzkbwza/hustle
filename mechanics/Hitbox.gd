tool

extends CollisionBox

class_name Hitbox

const COMBO_PUSHBACK_COEFFICIENT = "0.4"
const COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_GROUNDED = "1.25"
const COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_AERIAL = "1.05"
const COMBO_SAME_MOVE_HITSTUN_DECREASE_AMOUNT = 0

const HIT_PARTICLE = preload("res://fx/HitEffect1.tscn")

#const DAMAGE_SUPER_GAIN_DIVISOR = 1

signal hit_something(obj, hitbox)
signal got_parried()

enum HitHeight {
	High
	Mid
	Low
}

export var _c_Damage = 0
export var damage: int = 0
export var minimum_damage: int = 0

export var _c_Hit_Properties = 0
export var hitstun_ticks: int = 30
export var hitlag_ticks: int = 4
export var victim_hitlag: int = -1
export var cancellable = true
export var increment_combo = true
export var hits_otg = false
export var hits_vs_grounded = true
export var hits_vs_aerial = true
export var can_counter_hit = true

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
export var rumble = true

export var _c_Sfx = 0
export(AudioStream) var whiff_sound = preload("res://sound/common/whiff1.wav") 
export(AudioStream) var hit_sound = preload("res://sound/common/hit1.wav") 
export(AudioStream) var hit_bass_sound = preload("res://sound/common/hit_bass.wav")
export var whiff_sound_volume = -8.0
export var hit_sound_volume = -5.0

export var _c_Knockback = 0
export var dir_x: String = "1.0"
export var dir_y: String = "-1.0"
export var knockback: String = "10.0"
export var launch_reversible = false

export var pushback_x: String = "1.0"

export var _c_Knockback_Type = 0
export var grounded_hit_state = "HurtGrounded"
export var aerial_hit_state = "HurtAerial"
export var knockdown = false
export var knockdown_extends_hitstun = true # if true, aerial victim will stay in hitstun until hitting the ground
export var disable_collision = true
export var ground_bounce = true

export var _c_Frame_Data = 0
export var start_tick: int = 0
export var active_ticks: int = 5
export var always_on = false

export var _c_Loop_Data = 0
export var looping = false
export var loop_active_ticks: int = 2
export var loop_inactive_ticks: int = 2

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


func copy_to(hitbox: CollisionBox):
	for variable in ["x", "y", "pos_x", "pos_y", "dir_x", "dir_y", "damage", "knockback", "hitstun_ticks", "hitlag_ticks", "tick", "victim_hitlag", "active", "enabled"]:
		hitbox.set(variable, get(variable))

func setup_audio():
#	if !host.is_ghost:
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
			hit_bass_sound_player.volume_db = hit_sound_volume

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

func activate():
	if active:
		return
	spawn_whiff_particle()
	play_whiff_sound()
	tick = 0
	active = true
	enabled = true
	cancellable = cancellable or (bool(host.get("turbo_mode")) and !throw)
	if victim_hitlag == -1:
		victim_hitlag = hitlag_ticks

func deactivate():
	played_whiff_sound = false
	active = false
	enabled = false
	hit_objects = []

func to_data():
	return HitboxData.new(self)

func is_counter_hit():
	return host.is_in_group("Fighter") and host.read_advantage and host.opponent.current_state().has_hitboxes

func spawn_whiff_particle():
	if whiff_particle:
		var center = get_center()
		host.spawn_particle_effect(whiff_particle, Vector2(center.x, center.y))

func spawn_particle(particle, obj, dir):
	host.spawn_particle_effect(particle, get_overlap_center_float(obj.hurtbox), dir)

func init():
	if height < 0:
		height *= -1
	if width < 0:
		width *= -1
	call_deferred("setup_audio")

func get_real_knockback():
	if host.is_in_group("Fighter"):
		if not (host.current_state().state_name in host.combo_moves_used):
			return knockback
		var knockback_modifier = host.fixed.powu(COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_GROUNDED if host.opponent.is_grounded() else COMBO_SAME_MOVE_KNOCKBACK_INCREASE_AMOUNT_AERIAL, host.combo_moves_used[host.current_state().state_name])
		var final_kb = host.fixed.mul(knockback, knockback_modifier)
#		var max_kb = host.fixed.mul(knockback, "2")
#		if host.fixed.gt(final_kb, max_kb):
#			return max_kb
#		else:
		return final_kb
	else:
		return knockback

func get_real_hitstun():
	if host.is_in_group("Fighter"):
		if not (host.current_state().state_name in host.combo_moves_used):
			return hitstun_ticks
		var final_hitstun = Utils.int_max(hitstun_ticks - (COMBO_SAME_MOVE_HITSTUN_DECREASE_AMOUNT * (host.combo_moves_used[host.current_state().state_name] + 1)), hitstun_ticks / 2)
		return final_hitstun
	else:
		return hitstun_ticks

func otg_check(obj):
	return !obj.is_otg() or hits_otg

func hit(obj):
	if !(obj.name in hit_objects) and !obj.invulnerable and otg_check(obj):
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		var dir = get_dir_float(true)
		if grounded_hit_state == "HurtGrounded" and obj.is_grounded():
				dir.y *= 0
		for hitbox in grouped_hitboxes:
			hitbox.hit_objects.append(obj.name)
		obj.hit_by(self.to_data())
		var can_hit = true
		if obj.is_in_group("Fighter"):
			if !host.is_ghost:
				camera.bump(camera_bump_dir, screenshake_amount, Utils.frames(victim_hitlag if screenshake_frames < 0 else screenshake_frames))
			if obj.can_parry_hitbox(self) or name in obj.parried_hitboxes:
				can_hit = false
				emit_signal("got_parried")
			if obj.on_the_ground:
				if !hits_otg:
					can_hit = false
			if can_hit and spawn_particle_effect:
				if hit_particle:
					spawn_particle(hit_particle, obj, dir)
				if !replace_hit_particle:
					spawn_particle(HIT_PARTICLE, obj, dir)

		if can_hit:
			var pushback = host.fixed.mul(host.fixed.add(pushback_x, host.fixed.mul(str(host.combo_count), COMBO_PUSHBACK_COEFFICIENT)), "-1")
			host.add_pushback(pushback)
	#		obj.add_pushback(pushback)
			var opponent = obj.get("opponent")
			
			if opponent:
				if increment_combo:
					opponent.incr_combo()
				if opponent != host:
					opponent.add_pushback(pushback)
			if hit_sound_player and !ReplayManager.resimulating:
				hit_sound_player.play()
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
	
	if Global.get("show_hitboxes") and !Network.get("multiplayer_active"):
		return (active and enabled and Global.show_hitboxes)
	else:
		return .can_draw_box()
#	return .can_draw_box()
#
func tick():
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
