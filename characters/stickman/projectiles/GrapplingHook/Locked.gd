extends ObjectState

var was_attached = false

func _frame_0():
	was_attached = false
	pass

func _tick():
	host.update_rotation()
	var attached_to = host.obj_from_name(host.attached_to)
	if attached_to != null:
		if attached_to.disabled:
			host.unlock()
#			host.attached_to = null
		else:
			was_attached = true
			var pos = attached_to.get_hurtbox_center()
			host.set_pos(pos.x, pos.y)
	else:
		if was_attached:
			host.unlock()

func _exit():
	was_attached = false
