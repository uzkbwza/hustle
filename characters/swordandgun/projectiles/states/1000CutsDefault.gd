extends ObjectState

const LIFETIME = 150

func _tick():
	var creator_pos = host.creator.get_hurtbox_center()
	host.set_pos(creator_pos.x, creator_pos.y)
	if current_tick in [1, 9, 17]:
		host.set_facing(host.creator.get_facing_int())
	host.total_ticks += 1
	if host.total_ticks > LIFETIME:
		disable()


func disable():
	host.disable()
	terminate_hitboxes()
