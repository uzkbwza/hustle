extends ObjectState

var dir_x
var dir_y

func _frame_0():
	host.set_pos(data["x"], data["y"])

func _frame_5():
	terminate_hitboxes()
	host.sprite.hide()
	host.stop_particles()
	host.disabled = true
