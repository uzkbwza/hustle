extends ObjectState

const AIR_DRAG_MOD = "0.95"
const RICOCHET_SPEED_MOD = "0.75"
const MIN_SPEED = "4.0"
const BOUNCES = 6
const FORESIGHT_DIST = "20"
const KNOCKBACK = "12"
const RESET_HITBOX_TICKS = 2
const NUM_RICOCHET_SOUNDS = 3
const BOUNCE_HITLAG = 3
const TERRAIN_DI_AMOUNT = "0.35"
const DAMAGE_MODIFIER_PER_HIT = "0.8"
const MIN_TERRAIN_RICOCHET_AMOUNT = "0.1"
const DI_INFLUENCE = "0.125"
const BOUNCE_DAMAGE_SCALE = "0.85"
const BOUNCE_HITSTUN_SCALE = "0.85"
const BOUNCED_OFF_FORESIGHT_TIMER = 5

export var temporal = false

onready var front_hitbox = $Hitbox
onready var middle_hitbox = $Hitbox3
onready var trail_hitbox = $Hitbox2

var bounces_left = BOUNCES
var reset_hitbox_cooldown = 0


var bounce_lag_ticks = 0
var bounced_off_foresight_timer = 0


func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		reset_hitbox_cooldown = RESET_HITBOX_TICKS
		for h in [front_hitbox, middle_hitbox, trail_hitbox]:
			h.damage = fixed.round(fixed.mul(str(h.damage), DAMAGE_MODIFIER_PER_HIT))
			h.damage_in_combo = fixed.round(fixed.mul(str(h.damage_in_combo), DAMAGE_MODIFIER_PER_HIT))
			h.hitstun_ticks /= 2
			if h.hitstun_ticks < 5:
				h.hitstun_ticks = 5
#			h.scale_combo = false	

func bounce_off_foresight():
	if bounce_lag_ticks > 0:
		return
	var creator = host.get_fighter()
	if creator is Cowboy:
		var after_image = host.obj_from_name(creator.after_image_object)
		if after_image:
			var diff = host.obj_local_center(after_image)
			var dist = fixed.vec_len(str(diff.x), str(diff.y))
			if fixed.lt(dist, FORESIGHT_DIST):
#				after_image.disable()
				bounce_full_control()


func bounce_full_control(force=false):
	var creator = host.get_owned_fighter()
	if creator.is_in_group("Fighter") and creator.id == host.id:
		var di = creator.current_di
		var di_active = di.x != 0 or di.y != 0
		if di_active or force:
			host.reset_speed()
			var dir = fixed.normalized_vec(str(di.x), str(di.y))
			if force and !di_active:
				dir = fixed.normalized_vec(host.dir_x, host.dir_y)
			elif di_active:
				dir = xy_to_dir(di.x, di.y)
			host.dir_x = str(dir.x)
			host.dir_y = str(dir.y)
			bounced_off_foresight_timer = BOUNCED_OFF_FORESIGHT_TIMER
			on_bounce(false)

func _enter():
	host.set_facing(1) 

func _tick():
	if bounced_off_foresight_timer > 0:
		bounced_off_foresight_timer -= 1

	var move_vec = fixed.vec_mul(host.dir_x, host.dir_y, host.speed)

	trail_hitbox.x = fixed.round(fixed.mul(move_vec.x, "-1.0"))
	trail_hitbox.y = fixed.round(fixed.mul(move_vec.y, "-1.0"))
	
	middle_hitbox.x = fixed.round(fixed.mul(move_vec.x, "-0.5"))
	middle_hitbox.y = fixed.round(fixed.mul(move_vec.y, "-0.5"))
	
	if current_tick == 0:
		trail_hitbox.x = 0
		trail_hitbox.y = 0

	for hitbox in [front_hitbox, middle_hitbox, trail_hitbox]:
		hitbox.dir_x = host.dir_x
		hitbox.dir_y = host.dir_y
		hitbox.knockback = fixed.mul(KNOCKBACK, fixed.div(host.speed, host.SPEED))
	
	if reset_hitbox_cooldown > 0:
		reset_hitbox_cooldown -= 1

	if bounce_lag_ticks > 0:
		bounce_lag_ticks -= 1
		trail_hitbox.x = 0
		trail_hitbox.y = 0
		
		middle_hitbox.x = 0
		middle_hitbox.y = 0
		return

	host.move_directly(move_vec.x, move_vec.y)
	var pos = host.get_pos()

	if !host.ricochet:
		if pos.y >= 0:
			host.dir_y = fixed.mul(host.dir_y, "-1")
			on_bounce(host.get_owned_fighter().id == host.id)
			if fixed.gt(host.dir_y, "0"):
				host.dir_y = "-" + MIN_TERRAIN_RICOCHET_AMOUNT

		if Utils.int_abs(pos.x) >= host.stage_width:
			host.dir_x = fixed.mul(host.dir_x, "-1")
			if pos.x > 0:
				if fixed.gt(host.dir_x, "0"):
					host.dir_x = "-" + MIN_TERRAIN_RICOCHET_AMOUNT
			if pos.x < 0:
				if fixed.lt(host.dir_x, "0"):
					host.dir_x = MIN_TERRAIN_RICOCHET_AMOUNT
			on_bounce(host.get_owned_fighter().id == host.id)
		if host.has_ceiling and pos.y <= -host.ceiling_height:
			host.set_y(-host.ceiling_height)
			host.dir_y = fixed.mul(host.dir_y, "-1")
			on_bounce(host.get_owned_fighter().id == host.id)
			if fixed.lt(host.dir_y, "0"):
				host.dir_y = MIN_TERRAIN_RICOCHET_AMOUNT
	else:
		if host.ricochet:
			host.ricochet = false
		if reset_hitbox_cooldown <= 0:
#			queue_state_change("Default")
			for hitbox in [front_hitbox, middle_hitbox, trail_hitbox]:
#				hitbox.reset_hit_objects()
#				host.get_opponent().parried_hitboxes.erase(hitbox.name)
				queue_state_change("Default")

	host.speed = fixed.mul(host.speed, AIR_DRAG_MOD)

	if bounced_off_foresight_timer <= 0:
		bounce_off_foresight()

	if fixed.lt(host.speed, MIN_SPEED):
		host.disable()
	if host.no_draw_ticks > 0:
		host.no_draw_ticks -= 1

func on_bounce(di_influence=true, lerp_amount=TERRAIN_DI_AMOUNT):
	if bounce_lag_ticks > 0:
		return
	if !temporal:
		host.damages_own_team = true
	bounces_left -= 1
	if bounces_left == 0:
		host.disable()
	host.ricochet = true
	host.last_pos_visual_ricochet = host.last_pos_visual
	host.speed = fixed.mul(host.speed, RICOCHET_SPEED_MOD)
#	reset_hitbox_cooldown = RESET_HITBOX_TICKS
	host.rng.randomize()
	host.play_sound("Ricochet" + str(host.rng.randi_range(1, NUM_RICOCHET_SOUNDS + 1)))
	host.play_sound("RicochetNoise")

	if bounce_lag_ticks <= 0:
		bounce_scale()

	for hitbox in [front_hitbox, middle_hitbox, trail_hitbox]:
#		hitbox.chip_damage_modifier = "0.50"
		hitbox.chip_damage_modifier = "0.60"
		hitbox.reset_hit_objects()
		host.get_opponent().parried_hitboxes.erase(hitbox.name)
	
	bounce_lag_ticks += BOUNCE_HITLAG
	reset_hitbox_cooldown = RESET_HITBOX_TICKS
	if di_influence:
		var fighter = host.get_owned_fighter()
		if fighter and fighter.is_in_group("Fighter"):
			var di = fighter.current_di
			if di.x != 0 or di.y != 0:
				var dir = fixed.normalized_vec(str(di.x), str(di.y))
				var bounce_dir_x = fixed.lerp_string(host.dir_x, str(dir.x), lerp_amount)
				var bounce_dir_y = fixed.lerp_string(host.dir_y, str(dir.y), lerp_amount)
				host.dir_x = bounce_dir_x
				host.dir_y = bounce_dir_y

func bounce_scale():
	for hitbox in [front_hitbox, middle_hitbox, trail_hitbox]:
		hitbox.damage = fixed.round(fixed.mul(str(hitbox.damage), BOUNCE_DAMAGE_SCALE))
		hitbox.damage_in_combo = fixed.round(fixed.mul(str(hitbox.damage_in_combo), BOUNCE_DAMAGE_SCALE))
		hitbox.minimum_damage = fixed.round(fixed.mul(str(hitbox.minimum_damage), BOUNCE_DAMAGE_SCALE))
		hitbox.hitstun_ticks = fixed.round(fixed.mul(str(hitbox.hitstun_ticks), BOUNCE_HITSTUN_SCALE))
