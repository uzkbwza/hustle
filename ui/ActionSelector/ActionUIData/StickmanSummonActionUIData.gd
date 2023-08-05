extends ActionUIData

onready var direction = $Direction

func fighter_update():
	direction.set_NE(true)
	direction.set_E(true)
	direction.set_SE(true)
	direction.set_S(true)
	if !fighter.can_summon_kunai:
		direction.set_NE(false)
		direction.set_E(false)
		direction.set_SE(false)
		if fighter.can_summon_kick:
			direction.set_dir("S")
	if !fighter.can_summon_kick:
		direction.set_S(false)
		if fighter.can_summon_kunai:
			direction.set_dir("E")
