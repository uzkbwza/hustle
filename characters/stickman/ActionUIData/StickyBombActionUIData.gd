extends ActionUIData
onready var jump = $Jump

func fighter_update():
	jump.visible = !fighter.is_grounded()

func get_data():
	if fighter.is_grounded():
		return true
	else:
		return .get_data()
