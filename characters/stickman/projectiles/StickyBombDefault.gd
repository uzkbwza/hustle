extends DefaultFireball
const ATTACH_DISTANCE = "16"

var attached = false

func _frame_0():
	attached = false

func _tick():
	if attached:
		host.set_facing(host.creator.opponent.get_facing_int())
		var pos = host.creator.opponent.get_hurtbox_center()
		host.set_pos(pos.x, pos.y)
	else:
		host.update_grounded()
		var pos = host.get_pos()
		var opp_pos = host.creator.opponent.get_hurtbox_center()
		var opp: Fighter = host.creator.opponent
		if fixed.lt(fixed.vec_dist(str(pos.x), str(pos.y), str(opp_pos.x), str(opp_pos.y)), ATTACH_DISTANCE):
			if !opp.invulnerable and !opp.projectile_invulnerable:
				attached = true
