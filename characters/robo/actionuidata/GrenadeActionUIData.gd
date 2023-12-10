extends ActionUIData
onready var trajectory = $Trajectory

func fighter_update():
	trajectory.limit_symmetrical = !fighter.is_grounded()
