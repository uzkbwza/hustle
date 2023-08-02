extends ObjectState

const ACTIVE_FRAMES = 40

func create_particle():
	spawn_particle_relative(preload("res://characters/stickman/projectiles/SummonParticle.tscn"))

func finished():
	create_particle()
	terminate_hitboxes()
	host.sprite.hide()
	host.stop_particles()
	host.disabled = true
	if host.creator:
		host.creator.can_summon_kick = true

func _tick():
	if host.disabled:
		return
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	if current_tick > ACTIVE_FRAMES:
		finished()
