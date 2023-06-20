extends RobotState

onready var hitbox_4 = $Hitbox4

func _frame_0():
	hitbox_4.active_ticks = 0 if host.used_earthquake_grab else 3
