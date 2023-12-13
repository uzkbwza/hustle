extends RobotState

onready var wind_box = $WindBox

const PULL_FORCE = "0.45"

func _frame_12():
#	host.screen_bump(Vector2(), 5, 0.25)
	pass

func _tick():
	wind_box.hide()
	wind_box.facing = host.get_facing()
	
	var pos = host.get_pos()
	
	wind_box.update_position(pos.x, pos.y)
	
	if current_tick <= 15:
		if (host.opponent.hurtbox.overlaps(wind_box)):
			var force_x = fixed.mul(str(host.opponent.get_opponent_dir()), PULL_FORCE)
			host.opponent.apply_force(force_x, "0")
		wind_box.show()

func _exit():
	wind_box.hide()
