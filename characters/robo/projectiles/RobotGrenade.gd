extends BaseProjectile

const LIFETIME = 900
const ACTIVATE_TIME = 30
const EXPLOSION = preload("res://characters/robo/projectiles/NadeExplosion.tscn")
const DI_INFLUENCE = "5"
const DI_HORIZONTAL_MODIFIER = "0.85"
const DI_DEGRADATION_PER_HIT = "0.5"
const NUDGE_DISTANCE = 10
const ARM_TIME_REDUCTION_ON_HIT = 5
const ARM_TIME_ON_OPPONENT_HIT = 4

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
	disable()
	spawn_object(EXPLOSION, 0, -8)

func can_hit_cancel(fighter):
	if active:
		return hit_cancel_on_hit and fighter.id == id
	return hit_cancel_on_hit

func hit_by(hitbox):
	.hit_by(hitbox)
	if hitbox:
		if hitbox.hitbox_type == Hitbox.HitboxType.Flip:
			var vel = get_vel()
			set_vel(fixed.mul(vel.x, "-1"), vel.y)
		else:
			reset_momentum()
			var dir = fixed.normalized_vec_times(get_hitbox_x_dir(hitbox), hitbox.dir_y, fixed.mul(hitbox.knockback, "1.5"))
			if is_grounded() and fixed.gt(dir.y, "0"):
				dir.y = fixed.mul(dir.y, "-1")
			change_state("Active")
			apply_force(dir.x, dir.y)
			var nudge = fixed.normalized_vec_times(get_hitbox_x_dir(hitbox), hitbox.dir_y, str(NUDGE_DISTANCE))
			move_directly(nudge.x, nudge.y)
			var host = hitbox.host
			if host:
				my_hitbox.hit_objects.append(host)
			var host_object = obj_from_name(host)
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
					var di_amount = fixed.mul(fixed.sub("1.0", fixed.mul(DI_DEGRADATION_PER_HIT, str(hits_chained))), DI_INFLUENCE)
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
