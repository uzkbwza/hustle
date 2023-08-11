extends ActionUIData

onready var direction = $Direction

func fighter_update():
	direction.set_NE(false)
	direction.set_E(false)
	direction.set_SE(false)
	direction.set_S(false)
	direction.set_NW(false)
	direction.set_W(false)
	direction.set_SW(false)

	if fighter.get_facing_int() == 1:
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
	else:
		direction.set_NW(true)
		direction.set_W(true)
		direction.set_SW(true)
		direction.set_S(true)
		if !fighter.can_summon_kunai:
			direction.set_NW(false)
			direction.set_W(false)
			direction.set_SW(false)
			if fighter.can_summon_kick:
				direction.set_dir("S")
		if !fighter.can_summon_kick:
			direction.set_S(false)
			if fighter.can_summon_kunai:
				direction.set_dir("E")
