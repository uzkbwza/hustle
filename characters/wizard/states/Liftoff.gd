extends WizardState

const SPEED = "11.0"
const HITBOX_OFFSET = "-28.0"

onready var hitbox = $Hitbox
var particle_x
var particle_y

func _frame_0():
	land_cancel = false




func _frame_3():
	host.reset_momentum()
#	host.move_directly(0, -1)
	var dir = xy_to_dir(data.x, data.y, SPEED)
	var hitbox_offs = fixed.normalized_vec_times(dir.x, dir.y, HITBOX_OFFSET)
	var center = host.get_hurtbox_center()
	hitbox.dir_x = fixed.mul(hitbox_offs.x, str(host.get_facing_int()))
	hitbox.dir_y = hitbox_offs.y
	particle_x = hitbox_offs.x
	particle_y = hitbox_offs.y
	hitbox.x = fixed.round(hitbox_offs.x) * host.get_facing_int()
	hitbox.y = fixed.round(hitbox_offs.y) - 16
	host.apply_force(dir.x, dir.y)
	spawn_particle_relative(preload("res://characters/wizard/projectiles/CombustionEffect.tscn"), Vector2(particle_x, float(particle_y) - 16))
	host.sprite.hide()
	host.liftoff_sprite.show()
	host.liftoff_sprite.rotation = float(fixed.vec_to_angle(fixed.mul(dir.x, str(host.get_facing_int())), dir.y)) + TAU/4
#	$"%LiftoffParticles".set_enabled(true)
	land_cancel = true
	
func _tick():
	host.apply_forces_no_limit()
	if current_tick > 4:
		if host.is_grounded():
			return "Landing"
	
func _exit():
	host.liftoff_sprite.hide()
	host.sprite.show()
#	$"%LiftoffParticles".set_enabled(false)
