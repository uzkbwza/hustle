extends ActionUIData
onready var direction = $Direction

func fighter_update():
	direction.limit_angle = fighter.combo_count <= 0
	direction.limit_range_degrees = 150
	direction.limit_center_degrees = 30
	if fighter.is_grounded():
		direction.limit_range_degrees = 210
		direction.limit_center_degrees = 0
	direction.update_value(direction.get_default_value())
