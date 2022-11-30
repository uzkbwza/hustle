extends Fighter

const MAX_ARMOR_PIPS = 1

var armor_pips = 1

func _ready():
	pass

func init(pos=null):
	.init(pos)
	armor_pips = 1

func on_got_hit():
	if armor_pips > 0:
		armor_pips -= 1

func has_armor():
	return armor_pips > 0

func incr_combo():
	if combo_count == 0:
		armor_pips += 1
		if armor_pips > MAX_ARMOR_PIPS:
			armor_pips = MAX_ARMOR_PIPS
	.incr_combo()
	pass

#func launched_by(hitbox):
#	if armor_pips > 0:
#		hitlag_ticks = hitbox.victim_hitlag + (COUNTER_HIT_ADDITIONAL_HITLAG_FRAMES if hitbox.counter_hit else 0)
#		hitlag_applied = hitlag_ticks
#		if hitbox.rumble:
#			rumble(hitbox.screenshake_amount, hitbox.victim_hitlag if hitbox.screenshake_frames < 0 else hitbox.screenshake_frames)
#
#		emit_signal("got_hit")
#		take_damage(hitbox.damage, hitbox.minimum_damage)
#		armor_pips -= 1
#	else:
#		.launched_by(hitbox)
