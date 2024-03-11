extends WizardState

const SPEED = "15.0"
const SPARK_SPEED = "20.0"
const HITBOX_OFFSET = "-28.0"
const MAX_DOWN_SPEED = "10"
const FAST_FALL_REDUCTION = 200
const LAND_CANCEL_DAMAGE = 5

onready var hitbox = $Hitbox
onready var hitbox2 = $Hitbox2
var particle_x
var particle_y

func _frame_0():
	land_cancel = false
	if host.fast_falling:
		host.hover_left -= FAST_FALL_REDUCTION
	hitbox2.plus_frames = 2
	landing_recovery = 6
	
func _frame_6():
	host.reset_momentum()
#	host.move_directly(0, -1)
	var dir = xy_to_dir(data.x, data.y, SPEED)
	if host.spark_speed_frames > 0:
		dir.x = fixed.mul(dir.x, "1.75")

	if host.combo_count <= 0 and fixed.sign(dir.x) != host.get_facing_int():
		host.add_penalty(20, true)
	var hitbox_offs = fixed.normalized_vec_times(dir.x, dir.y, HITBOX_OFFSET)
	var center = host.get_hurtbox_center()
	hitbox.dir_x = fixed.mul(hitbox_offs.x, str(host.get_facing_int()))
	hitbox.dir_y = hitbox_offs.y
	particle_x = hitbox_offs.x
	particle_y = hitbox_offs.y
	hitbox.x = fixed.round(hitbox_offs.x) * host.get_facing_int()
	hitbox.y = fixed.round(hitbox_offs.y) - 16


	host.apply_force(dir.x, dir.y if !host.fast_falling else fixed.mul(dir.y, "0.25"))
	spawn_particle_relative(preload("res://characters/wizard/projectiles/CombustionEffect.tscn"), Vector2(particle_x, float(particle_y) - 16))
	host.sprite.hide()
	host.liftoff_sprite.show()
	host.liftoff_sprite.rotation = float(fixed.vec_to_angle(fixed.mul(dir.x, str(host.get_facing_int())), dir.y)) + TAU/4
#	$"%LiftoffParticles".set_enabled(true)
	land_cancel = true
	host.play_sound("HitBass")
	host.screen_bump(Vector2(), 3, 0.15)
	host.colliding_with_opponent = false

func _tick():
	if host.spark_speed_frames > 0:
		hitbox2.plus_frames = 3
#	if host.spark_speed_frames <= 0:
#		var vel = host.get_vel()
#		if fixed.gt(vel.y, MAX_DOWN_SPEED):
#			host.set_vel(vel.x, MAX_DOWN_SPEED)

	host.apply_forces_no_limit()
	var vel = host.get_vel()
	if current_tick > 7:
		if host.is_grounded():
			
			var landing_lag = 4
			if !fixed.eq(vel.x, "0"):
				if fixed.sign(vel.x) != host.get_facing_int():
					landing_lag = 12
			queue_state_change("Landing", landing_lag)

func _exit():
	if queued_state == "Landing":
#		host.take_damage(LAND_CANCEL_DAMAGE)
		if host.combo_count <= 0:
			var vel = host.get_vel()
			host.set_vel(vel.x, fixed.mul(vel.y, "0.75"))
		

	host.liftoff_sprite.hide()
	host.sprite.show()
#	$"%LiftoffParticles".set_enabled(false)
