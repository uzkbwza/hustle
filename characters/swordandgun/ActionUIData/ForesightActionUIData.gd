extends ActionUIData


func fighter_update():
	$Direction.limit_angle = fighter.combo_count <= 0
