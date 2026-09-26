extends BaseProjectile

const LIFETIME = 900
const ACTIVATE_TIME = 30
const EXPLOSION = preload("res://characters/robo/projectiles/NadeExplosion.tscn")
const DI_INFLUENCE = "5"
const DI_HORIZONTAL_MODIFIER = "0.85"
const DI_DEGRADATION_PER_HIT = "0.0"
const NUDGE_DISTANCE = 10
const ARM_TIME_REDUCTION_ON_HIT = 5
const ARM_TIME_ON_OPPONENT_HIT = 4
# Knockback multiplier applied on top of `hitbox.knockback` for any
# attacker. Creator no longer gets a knockback multiplier of their own —
# the escalation now comes from the tiered hit-counter speed boost below.
const KNOCKBACK_MULTIPLIER = "1.5"
# DI influence amount when the attacker steers the bomb via their DI.
# Creator gets a boosted value so their own DI has more pull on the bomb
# than an opponent's DI does.
const CREATOR_DI_INFLUENCE = "12"
# Per-tier air- and fall-speed caps, indexed by creator hit count in the
# current bounce sequence. tier_index = clamp(hit_count, 1, CAP) - 1.
# Tier 1 (= 1 hit) matches scene base so the first hit just primes the
# counter. Subsequent tiers ramp up — 75% / 125% / 150% of the prior
# single-hit boost reference (19 air, 16 fall) — so the creator builds
# speed by juggling. Reset by any opponent hit, or by GROUNDED_RESET_FRAMES
# consecutive grounded ticks (= done bouncing).
const CREATOR_TIER_AIR_SPEEDS = ["12", "14.25", "23.75", "28.5"]
const CREATOR_TIER_FALL_SPEEDS = ["15", "15", "20", "24"]
const CREATOR_HIT_COUNT_CAP = 4
const GROUNDED_RESET_FRAMES = 60

# Tracked in extra_state_variables so rollback / replay restore preserves
# the creator's hit-stack and the grounded-debounce counter.
var creator_hit_count = 0
var grounded_frames = 0

onready var my_hitbox = $StateMachine/Active/Hitbox
onready var active_indicator = $Flip/ActiveIndicator

var last_vel_x
var last_vel_y
var hits_chained = 0
var last_hit_by = -1

var active = false
var hitbox_out = false

var ticks_left = LIFETIME

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init(pos=null):
	.init(pos)

func tick():
	.tick()
	if hitlag_ticks <= 0:
		ticks_left -= 1
		if ticks_left == ACTIVATE_TIME - 3:
			has_projectile_parry_window = false
		if ticks_left <= 0 and !creator.opponent.current_state().state_name == "Grabbed":
			explode()
		elif ticks_left <= ACTIVATE_TIME:
			activate()
	# Creator's hit-stack speed boost decays once the bomb has been grounded
	# for GROUNDED_RESET_FRAMES consecutive ticks — i.e., it's done bouncing.
	# Brief touches don't reset, so a low bounce keeps the boost alive.
	if creator_hit_count > 0:
		if is_grounded():
			grounded_frames += 1
			if grounded_frames >= GROUNDED_RESET_FRAMES:
				_clear_creator_hit_speed_boost()
		else:
			grounded_frames = 0
	# Cap upward velocity to the horizontal air-speed limit. The chara backend
	# only enforces a fall-speed (downward) cap natively, so without this an
	# uppercut could shoot the bomb straight up at speeds well above the
	# horizontal cap. Mirrors the active tier's air-speed cap.
	var up_cap = _current_air_speed_cap()
	var neg_cap = fixed.mul(up_cap, "-1")
	var vel = get_vel()
	if fixed.lt(vel.y, neg_cap):
		set_vel(vel.x, neg_cap)

func activate():
	if active:
		return
	ticks_left = Utils.int_min(ticks_left, ACTIVATE_TIME)
	play_sound("Beep")
	active = true
	current_state().hitbox.sdi_modifier = "0.0"
	my_hitbox.increment_combo = false


func _process(delta):
	if active and !disabled:
		active_indicator.visible = Utils.pulse(0.064, 0.5)

func explode():
	if disabled:
		return
	disable()
	spawn_object(EXPLOSION, 0, -8)

func can_hit_cancel(fighter):
	if active:
		return hit_cancel_on_hit and fighter.id == id
	return hit_cancel_on_hit

func hit_by(hitbox):
	.hit_by(hitbox)
	if hitbox:
		if hitbox.throw:
			return
		if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
			var vel = get_vel()
			set_vel(fixed.mul(vel.x, "-1"), vel.y)
		else:
			reset_momentum()
			# Resolve the attacker up-front so we can pick the creator-vs-
			# opponent path for the speed-boost stack and DI influence. Knockback
			# multiplier is the same for everyone — the creator's edge now
			# comes from the stacking speed tiers + boosted DI, not knockback.
			var host = hitbox.host
			var host_object = obj_from_name(host) if host != null else null
			var attacker_is_creator = is_instance_valid(host_object) and host_object.id == id
			var dir = fixed.normalized_vec_times(get_hitbox_x_dir(hitbox), hitbox.dir_y, fixed.mul(hitbox.knockback, KNOCKBACK_MULTIPLIER))
			if is_grounded() and fixed.gt(dir.y, "0"):
				dir.y = fixed.mul(dir.y, "-1")
			change_state("Active")
			apply_force(dir.x, dir.y)
			var nudge = fixed.normalized_vec_times(get_hitbox_x_dir(hitbox), hitbox.dir_y, str(NUDGE_DISTANCE))
			move_directly(nudge.x, nudge.y)
			if host:
				my_hitbox.hit_objects.append(host)
			# Creator hit → bump the hit counter (capped) and apply the next
			# speed tier. Reset the grounded debounce so a fresh hit isn't
			# treated as "still grounded" on the very next tick. Opponent hit
			# while the stack is active wipes it back to base.
			if attacker_is_creator:
				creator_hit_count = Utils.int_min(creator_hit_count + 1, CREATOR_HIT_COUNT_CAP)
				grounded_frames = 0
				_apply_creator_hit_speed_boost()
			elif creator_hit_count > 0:
				_clear_creator_hit_speed_boost()
			if host_object:
				var player_object = host_object.get_owner()
				var player = player_object.obj_name
				hit_cancel_on_hit = true
				if last_hit_by != host_object.id or player_object.combo_count > 0 or player_object.opponent.combo_count > 0:
					last_hit_by = host_object.id
					hits_chained = 0
				else:
					hits_chained += 1
#				if hits_chained > 0:
#					hit_cancel_on_hit = false

#				if player_object.combo_count > 0:
#					hit_cancel_on_hit = true
#
				# new
				hit_cancel_on_hit = player_object.combo_count > 0 and hits_chained == 0

				if host != player:
					my_hitbox.hit_objects.append(player)
				else:
					# DI pull on the bomb. Creator gets the boosted influence
					# so their own DI moves the bomb more than an opponent's.
					var di_influence = CREATOR_DI_INFLUENCE if attacker_is_creator else DI_INFLUENCE
					var di_amount = fixed.mul(fixed.sub("1.0", fixed.mul(DI_DEGRADATION_PER_HIT, str(hits_chained))), di_influence)
					if fixed.lt(di_amount, "0"):
						di_amount = "0"
#					print(di_amount)
					var di_force = xy_to_dir(host_object.current_di.x, host_object.current_di.y, di_amount)
					apply_force(fixed.mul(di_force.x, DI_HORIZONTAL_MODIFIER), di_force.y)

				if active:
					if host_object.id != id:
						ticks_left = Utils.int_min(ticks_left, ARM_TIME_ON_OPPONENT_HIT)
					else:
						ticks_left -= ARM_TIME_REDUCTION_ON_HIT
					if ticks_left < 0:
						ticks_left = 0

func refresh():
	hitbox_out = false
	change_state(current_state().state_name)
	
func on_got_blocked():
	.on_got_blocked()
	var vel = get_vel()
	if active:
		ticks_left = Utils.int_min(ticks_left, ARM_TIME_ON_OPPONENT_HIT)
	else:
		set_vel(fixed.mul(vel.x, "-0.9"), vel.y)
	if creator.magnet_ticks_left > 0:
		creator.magnetize_opponent = true
		creator.magnetize_opponent_blocked = true

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		if creator.magnet_ticks_left > 0:
			creator.magnetize_opponent = true
			creator.magnetize_opponent_blocked = false

func disable():
	.disable()
	active_indicator.hide()
	creator.grenade_object = null
	creator.magnetize_opponent = false
	creator.magnetize_opponent_blocked = false

# Push the current tier's air- and fall-speed caps to the chara backend.
# tier_index = clamp(hit_count, 1, CAP) - 1 — caller must have already
# bumped creator_hit_count. Mirrors Wizard.tick's spark-explosion pattern.
func _apply_creator_hit_speed_boost():
	var tier = Utils.int_min(creator_hit_count, CREATOR_HIT_COUNT_CAP) - 1
	if tier < 0:
		return
	chara.set_max_air_speed(CREATOR_TIER_AIR_SPEEDS[tier])
	chara.set_max_fall_speed(CREATOR_TIER_FALL_SPEEDS[tier])

func _clear_creator_hit_speed_boost():
	creator_hit_count = 0
	grounded_frames = 0
	chara.set_max_air_speed(max_air_speed)
	chara.set_max_fall_speed(max_fall_speed)

# Air-speed cap reflecting the active tier — falls back to the scene
# default when no creator hits are stacked.
func _current_air_speed_cap():
	var tier = Utils.int_min(creator_hit_count, CREATOR_HIT_COUNT_CAP) - 1
	if tier < 0:
		return max_air_speed
	return CREATOR_TIER_AIR_SPEEDS[tier]
