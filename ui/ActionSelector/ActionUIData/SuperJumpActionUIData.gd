extends ActionUIData

onready var jump_arc = $JumpArc

func fighter_update():
	jump_arc.limit_range_degrees = 30
	jump_arc.limit_center_degrees = -45
	if fighter.combo_count > 0:
		jump_arc.limit_range_degrees = 60
		jump_arc.limit_center_degrees = -60
	jump_arc.update_value()
