extends ObjectState

const LOCK_DISTANCE = "8"
const CHARACTER_LOCK_DISTANCE = "16"

func _frame_0():
	host.play_sound("HookSound")

func _tick():
	host.update_rotation()
	host.apply_grav_custom(host.gravity, "1000000000000")
	host.apply_forces_no_limit()
	if host.is_grounded():
#		host.disable()
		lock()
	if Utils.int_abs(Utils.int_abs(host.get_pos().x) - host.stage_width) < 2:
		lock()
	for obj_name in host.objs_map:
		var obj = host.objs_map[obj_name]
		if obj != null:
			if !obj.disabled and obj != host and obj != host.creator:
				var obj_pos = host.obj_local_center(obj)
				if fixed.lt(fixed.vec_len(str(obj_pos.x), str(obj_pos.y)), LOCK_DISTANCE if !obj.is_in_group("Fighter") else CHARACTER_LOCK_DISTANCE):
					lock(obj)
					break

func _on_hit_something(obj, hitbox):
	lock(obj)

func _ready():
	pass

func lock(obj=null):
	queue_state_change("Locked")
	host.attached_to = obj.obj_name if obj else null
	host.is_locked = true
