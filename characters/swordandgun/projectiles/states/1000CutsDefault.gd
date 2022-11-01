extends ObjectState

const LIFETIME = 120

func _tick():
	var creator_pos = host.creator.get_hurtbox_center()
	host.set_pos(creator_pos.x, creator_pos.y)
	if current_tick in [1, 9, 17]:
		host.set_facing(host.creator.get_facing_int())
	host.total_ticks += 1
	if host.total_ticks > LIFETIME:
		host.disable()
		host.creator.cut_projectile = null

func disable():
	host.disable()
	terminate_hitboxes()
	host.creator.cut_projectile = null
