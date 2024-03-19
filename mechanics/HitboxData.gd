class_name HitboxData

var id: int
var hit_height: int
var hitstun_ticks: int
var facing: String
var facing_int: int
var knockback: String
var dir_y: String
var dir_x: String
var pos_x: int
var pos_y: int
var counter_hit = false
var knockdown: bool
var hitlag_ticks
var victim_hitlag
var disable_collision
var aerial_hit_state
var grounded_hit_state
var ground_bounce
var air_ground_bounce
var hits_otg
var damage
var parriable = true
var reversible
var name
var throw
var combo_count = 0
var knockdown_extends_hitstun = true
var rumble
var host
var screenshake_frames = 0
var screenshake_amount = 0
var minimum_damage = 0
var sdi_modifier = "1.0"
var di_modifier = "1.0"
var meter_gain_modifier = "1.0"
var increment_combo = false
var ignore_armor = false
var damage_proration = 0
var parry_meter_gain = -1
var force_grounded = false
var hitbox_type = 0
var hard_knockdown = false
var damage_in_combo = -1
var wall_slam = false
var hits_vs_dizzy = true
var is_projectile = false
var scale_combo = true
var combo_scaling_amount = 1
var vacuum = false
var hits_vs_standing = true
var send_away_from_center = false
var minimum_grounded_frames = -1
var plus_frames = 0
var chip_damage_modifier = "1.0"
var block_pushback_modifier = "1.0"
var ground_bounce_knockback_modifier = "1.0"
var hits_projectiles = true
var cancellable = false
var followup_state = ""
var guard_break = false
var block_punishable = false
var guard_break_proration = 0
var ignore_projectile_armor = false
var looping = false
var block_cancel_allowed = true
var allowed_to_hit_own_team = true
var block_pushback_reversible = false
var block_reverse_pushback_modifier = "1.0"
var misc_data = ""

func get_damage():
	if combo_count > 0:
		return damage_in_combo
	return damage

func _init(state):
	hit_height = state.hit_height
	if !state.has_method("get_real_hitstun"):
		hitstun_ticks = state.hitstun_ticks
	else:
		hitstun_ticks = state.get_real_hitstun()
	if !state.has_method("get_real_victim_hitlag"):
		victim_hitlag = state.victim_hitlag
	else:
		victim_hitlag = state.get_real_victim_hitlag()
	facing = state.host.get_facing()
	facing_int = state.host.get_facing_int()
	id = state.host.id
	if !state.has_method("get_real_knockback"):
		knockback = state.knockback
	else:
		knockback = state.get_real_knockback()
	damage = state.damage
	dir_y = state.dir_y
	hitlag_ticks = state.hitlag_ticks
	disable_collision = state.disable_collision
	dir_x = state.dir_x
	knockdown = state.knockdown
	aerial_hit_state = state.aerial_hit_state
	grounded_hit_state = state.grounded_hit_state
	damage = state.damage
	name = state.name
	ground_bounce = state.ground_bounce
	throw = state.throw
	hard_knockdown = state.hard_knockdown
	force_grounded = state.force_grounded
	wall_slam = state.wall_slam
	reversible = false if !state.get("launch_reversible") else state.launch_reversible
	if state.has_method("get_absolute_position"):
		var pos = state.get_absolute_position()
		pos_x = pos.x
		pos_y = pos.y
	if state.has_method("is_projectile"):
		is_projectile = state.is_projectile()
	if state.get("knockdown_extends_hitstun") != null:
		knockdown_extends_hitstun = state.knockdown_extends_hitstun
	if state.get("hits_otg") != null:
		hits_otg = state.hits_otg
	if state.get("rumble") != null:
		rumble = state.rumble
	self.host = state.host.obj_name
	combo_count = 0
	if state.host.is_in_group("Fighter"):
		combo_count = state.host.combo_count
	else:
		if state.host.fighter_owner:
			combo_count = state.host.fighter_owner.combo_count
	if state.get("screenshake_amount") != null:
		screenshake_amount = state.screenshake_amount
	if state.get("screenshake_frames") != null:
		screenshake_frames = state.screenshake_frames
	if state.has_method("is_counter_hit"):
		counter_hit = state.is_counter_hit()
	if state.get("minimum_damage") != null:
		minimum_damage = state.minimum_damage
	if state.get("sdi_modifier") != null:
		sdi_modifier = state.sdi_modifier
	if state.get("di_modifier") != null:
		di_modifier = state.di_modifier
	if state.get("increment_combo") != null:
		increment_combo = state.increment_combo
	if state.get("ignore_armor") != null:
		ignore_armor = state.ignore_armor
	if state.get("damage_proration") != null:
		damage_proration = state.damage_proration
	if state.get("parry_meter_gain") != null:
		parry_meter_gain = state.parry_meter_gain
	if state.get("hitbox_type") != null:
		hitbox_type = state.hitbox_type
	if state.get("damage_in_combo") != null:
		damage_in_combo = state.damage_in_combo
	if state.get("hits_vs_dizzy") != null:
		hits_vs_dizzy = state.hits_vs_dizzy
	if state.get("meter_gain_modifier") != null:
		meter_gain_modifier = state.meter_gain_modifier
	if state.get("air_ground_bounce") != null:
		air_ground_bounce = state.air_ground_bounce
	if state.get("scale_combo") != null:
		scale_combo = state.scale_combo
	if state.get("plus_frames") != null:
		plus_frames = state.plus_frames
	if state.get("vacuum") != null:
		vacuum = state.vacuum
	if state.get("send_away_from_center") != null:
		send_away_from_center = state.send_away_from_center
	if state.get("minimum_grounded_frames") != null:
		minimum_grounded_frames = state.minimum_grounded_frames
	if state.get("chip_damage_modifier") != null:
		chip_damage_modifier = state.chip_damage_modifier
	if state.get("block_pushback_modifier") != null:
		block_pushback_modifier = state.block_pushback_modifier
	if state.get("hits_vs_standing") != null:
		hits_vs_standing = state.hits_vs_standing
	if state.get("combo_scaling_amount") != null:
		combo_scaling_amount = state.combo_scaling_amount
	if state.get("ground_bounce_knockback_modifier") != null:
		ground_bounce_knockback_modifier = state.ground_bounce_knockback_modifier
	if state.get("hits_projectiles") != null:
		hits_projectiles = state.hits_projectiles
	if state.get("cancellable") != null:
		cancellable = state.cancellable
	if state.get("followup_state") != null:
		followup_state = state.followup_state
	if state.get("guard_break") != null:
		guard_break = state.guard_break
	if state.get("parriable") != null:
		parriable = state.parriable
	if state.get("block_punishable") != null:
		block_punishable = state.block_punishable
	if state.get("looping") != null:
		looping = state.looping
	if state.get("ignore_projectile_armor") != null:
		ignore_projectile_armor = state.ignore_projectile_armor
	if state.get("block_cancel_allowed") != null:
		block_cancel_allowed = state.block_cancel_allowed
	if state.get("allowed_to_hit_own_team") != null:
		allowed_to_hit_own_team = state.allowed_to_hit_own_team
	if state.get("block_pushback_reversible") != null:
		block_pushback_reversible = state.block_pushback_reversible
	if state.get("block_reverse_pushback_modifier") != null:
		block_reverse_pushback_modifier = state.block_reverse_pushback_modifier
	if state.get("misc_data") != null and state.misc_data != "":
		misc_data = state.misc_data
	if state.get("guard_break_proration") != null:
		guard_break_proration = state.guard_break_proration

	if damage_in_combo == -1:
		damage_in_combo = damage

func is_projectile():
	return is_projectile()
