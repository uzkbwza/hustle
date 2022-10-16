tool

extends CollisionBox

class_name Hitbox

const COMBO_PUSHBACK_COEFFICIENT = "0.4"

const HIT_PARTICLE = preload("res://fx/HitEffect1.tscn")

const DAMAGE_SUPER_GAIN_DIVISOR = 1

signal hit_something(obj, hitbox)

enum HitHeight {
	High
	Mid
	Low
}

export var _c_Damage = 0
export var damage: int = 0

export var _c_Hit_Properties = 0
export var hitstun_ticks: int = 30
export var hitlag_ticks: int = 4
export var cancellable = true
export(HitHeight) var hit_height = HitHeight.Mid

export var _c_Grouping = 0
# lower values have higher priority
# when multiple hitboxes are overlapping an opponent, the highest-priority hitbox will be chosen
export var priority: int = 0

# grouped hitboxes are considered to be part of the same continuous attack.
# use this if you want attacks that use multiple hitboxes over time
# but are not multi-hitting attacks
export var group: int = 0

export var _c_Fx = 0
export var screenshake_amount: int = 4
export var screenshake_frames: int = -1

export var _c_Knockback = 0
export var dir_x: String = "1.0"
export var dir_y: String = "-1.0"
export var knockback: String = "10.0"

export var pushback_x: String = "1.0"

export var _c_Knockback_Type = 0
export var grounded_hit_state = "HurtGrounded"
export var aerial_hit_state = "HurtAerial"
export var knockdown = false

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

var grouped_hitboxes = []

var hit_objects = []

func activate():
	if active:
		return
	tick = 0
	active = true
	enabled = true

func deactivate():
	active = false
	enabled = false
	hit_objects = []

func to_data():
	return HitboxData.new(self)

func hit(obj):
	if !(obj.name in hit_objects) and !obj.invulnerable:
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
				camera.bump(Vector2(), screenshake_amount, Utils.frames(hitlag_ticks if screenshake_frames < 0 else screenshake_frames))
			if obj.can_parry_hitbox(self) or name in obj.parried_hitboxes:
				can_hit = false
			if can_hit and spawn_particle_effect:
				host.spawn_particle_effect(HIT_PARTICLE, get_overlap_center_float(obj.hurtbox), dir)

		if host.hitlag_ticks < hitlag_ticks:
			host.hitlag_ticks = hitlag_ticks
		if can_hit:
			var pushback = host.fixed.mul(host.fixed.add(pushback_x, host.fixed.mul(str(host.combo_count), COMBO_PUSHBACK_COEFFICIENT)), "-1")
			host.add_pushback(pushback)
	#		obj.add_pushback(pushback)
			var opponent = obj.get("opponent")
			
			if opponent:
				opponent.incr_combo()
				if opponent != host:
					opponent.add_pushback(pushback)
				opponent.gain_super_meter(damage / DAMAGE_SUPER_GAIN_DIVISOR)
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
	return .can_draw_box() or (active and enabled)
#	return .can_draw_box()

func tick():
	if looping:
		var loop_tick = tick % (loop_active_ticks + loop_inactive_ticks)
		var prev_enabled = enabled
		enabled = loop_tick < loop_active_ticks
		if !enabled and prev_enabled:
			for hitbox in grouped_hitboxes:
				hitbox.hit_objects.clear()
	tick += 1
	if tick > active_ticks:
		if !always_on:
			deactivate()
