class_name HitboxData

var hit_height: int
var hitstun_ticks: int
var facing: String
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
var hits_otg
var damage
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
var increment_combo = false
var ignore_armor = false
var damage_proration = 0
var parry_meter_gain = -1
var force_grounded = false
var hitbox_type = 0
var hard_knockdown = false
var damage_in_combo = -1

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
	facing = state.host.get_facing()
	if !state.has_method("get_real_knockback"):
		knockback = state.knockback
	else:
		knockback = state.get_real_knockback()	

	damage = state.damage
	dir_y = state.dir_y
	hitlag_ticks = state.hitlag_ticks
	victim_hitlag = state.victim_hitlag
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
	reversible = false if !state.get("launch_reversible") else state.launch_reversible
	if state.has_method("get_absolute_position"):
		var pos = state.get_absolute_position()
		pos_x = pos.x
		pos_y = pos.y
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
	if damage_in_combo == -1:
		damage_in_combo = damage
