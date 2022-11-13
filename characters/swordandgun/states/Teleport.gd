extends CharacterState

const MOVE_DIST = "200"

func _frame_4():
	host.start_invulnerability()
	host.colliding_with_opponent = false

func _frame_5():
	var dir = xy_to_dir(data.x, data.y, MOVE_DIST)
	
	host.move_directly(dir.x, dir.y)
	host.set_vel(host.get_vel().x, "0")
	host.update_data()


func _frame_6():
	host.update_facing()

func _frame_7():
	host.end_invulnerability()
	host.colliding_with_opponent = true

func _tick():
#	if current_tick > 5:
	host.apply_fric()
	host.apply_grav()
	host.apply_forces()
	host.set_grounded(host.get_pos().y == 0)

func is_usable():
	return .is_usable() and host.current_state().state_name != "WhiffInstantCancel"
