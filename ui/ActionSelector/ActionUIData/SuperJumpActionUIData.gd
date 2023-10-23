extends ActionUIData

onready var jump_arc = $JumpArc

func fighter_update():
#	jump_arc.limit_range_degrees = 30
#	jump_arc.limit_center_degrees = -45
	jump_arc.hide()
#	var dir = fighter.get_opponent_dir_vec()

#	jump_arc.update_value(Vector2(fighter.get_facing_int() * float(dir.x), float(dir.y)).normalized())
	if fighter.combo_count > 0:
#		jump_arc.limit_range_degrees = 60
#		jump_arc.limit_center_degrees = -60
#		jump_arc.update_value(jump_arc.get_default_value())
		jump_arc.show()

func get_data():
	if fighter.combo_count > 0:
		return .get_data()
	else:
		return "homing"
