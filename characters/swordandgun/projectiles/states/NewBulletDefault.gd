extends ObjectState


const AIR_DRAG_MOD = "0.95"
const RICOCHET_SPEED_MOD = "0.5"
const MIN_SPEED = "4.0"
const BOUNCES = 5
const FORESIGHT_DIST = "20"
const KNOCKBACK = "12"
const RESET_HITBOX_TICKS = 2
const NUM_RICOCHET_SOUNDS = 3
const BOUNCE_HITLAG = 3
const TERRAIN_DI_AMOUNT = "0.35"

onready var front_hitbox = $Hitbox
onready var trail_hitbox = $Hitbox2

var bounces_left = BOUNCES
var reset_hitbox_cooldown = 0
var bounced_off_foresight = false

var bounce_lag_ticks = 0


func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	if obj.is_in_group("Fighter"):
		reset_hitbox_cooldown = RESET_HITBOX_TICKS

func bounce_off_foresight():
	if bounce_lag_ticks > 0:
		return
	var creator = host.creator
	if creator is Cowboy:
		var after_image = host.obj_from_name(creator.after_image_object)
		if after_image:
			var diff = host.obj_local_center(after_image)
			var dist = fixed.vec_len(str(diff.x), str(diff.y))
			if fixed.lt(dist, FORESIGHT_DIST):
#				after_image.disable()
				var di = creator.current_di
				if di.x != 0 or di.y != 0:
					var dir = fixed.normalized_vec(str(di.x), str(di.y))
					host.dir_x = str(dir.x)
					host.dir_y = str(dir.y)
					bounced_off_foresight = true
					on_bounce(false)

func _enter():
	host.set_facing(1) 

func _tick():

	var move_vec = fixed.vec_mul(host.dir_x, host.dir_y, host.speed)
	trail_hitbox.x = fixed.round(fixed.mul(move_vec.x, "-1.0"))
	trail_hitbox.y = fixed.round(fixed.mul(move_vec.y, "-1.0"))
	if current_tick == 0:
		trail_hitbox.x = 0
		trail_hitbox.y = 0

	for hitbox in [front_hitbox, trail_hitbox]:
		hitbox.dir_x = host.dir_x
		hitbox.dir_y = host.dir_y
		hitbox.knockback = fixed.mul(KNOCKBACK, fixed.div(host.speed, host.SPEED))
	
	if reset_hitbox_cooldown > 0:
		reset_hitbox_cooldown -= 1

	
	if bounce_lag_ticks > 0:
		bounce_lag_ticks -= 1
		return

	host.move_directly(move_vec.x, move_vec.y)
	var pos = host.get_pos()

	if !host.ricochet:
		if pos.y >= 0:
			host.dir_y = fixed.mul(host.dir_y, "-1")
			on_bounce()
		if Utils.int_abs(pos.x) >= host.stage_width:
			host.dir_x = fixed.mul(host.dir_x, "-1")
			on_bounce()
		if host.has_ceiling and pos.y <= -host.ceiling_height:
			host.set_y(-host.ceiling_height)
			host.dir_y = fixed.mul(host.dir_y, "-1")
			on_bounce()
	else:
		if host.ricochet:
			host.ricochet = false
		if reset_hitbox_cooldown <= 0:
			queue_state_change("Default")


	host.speed = fixed.mul(host.speed, AIR_DRAG_MOD)

	if !bounced_off_foresight:
		bounce_off_foresight()

	if fixed.lt(host.speed, MIN_SPEED):
		host.disable()

func on_bounce(di_influence=true):
	if bounce_lag_ticks > 0:
		return
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
	bounce_lag_ticks += BOUNCE_HITLAG
	reset_hitbox_cooldown = RESET_HITBOX_TICKS
	if di_influence:
		var creator = host.creator
		if creator.is_in_group("Fighter"):
			var di = creator.current_di
			if di.x != 0 or di.y != 0:
				var dir = fixed.normalized_vec(str(di.x), str(di.y))
				var bounce_dir_x = fixed.lerp_string(host.dir_x, str(dir.x), TERRAIN_DI_AMOUNT)
				var bounce_dir_y = fixed.lerp_string(host.dir_y, str(dir.y), TERRAIN_DI_AMOUNT)
				var bounce_dir = fixed.normalized_vec(bounce_dir_x, bounce_dir_y)
				host.dir_x = bounce_dir_x
				host.dir_y = bounce_dir_y
