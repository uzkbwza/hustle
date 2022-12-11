extends WizardState

const PUSH_SPEED = "5"
const MAX_EXTRA_PUSH_DIST = "200"
const MAX_EXTRA_PUSH = "10"
const PUSH_FORCE = "3"
const FIGHTER_PUSH_SPEED = "4"
 

onready var windbox = $WindBox
#onready var throwbox = $ThrowBox

func _tick():
	$"%SandstormParticle".stop_emitting()
#	if throwbox.active and throwbox.enabled:
	if current_tick < iasa_at and current_tick > 2:
		var wb = windbox
		$"%SandstormParticle".start_emitting()
		var windbox_hitting = []
		wb.facing = host.get_facing()
		var pos = host.get_pos()
		wb.update_position(pos.x, pos.y)
		for obj in host.objs_map.values():
			if obj is BaseObj and !obj == host and (obj.is_grounded() or !obj.is_in_group("Fighter")) and obj.current_state().state_name != "Burst" and wb.overlaps(obj.hurtbox):
					windbox_hitting.append(obj)
		for obj in windbox_hitting:
			push_object(obj)

func _exit():
	$"%SandstormParticle".stop_emitting()
	host.release_opponent()


func push_object(obj):
	var obj_pos = obj.get_pos()
	var pos = host.get_pos()
	var diff = fixed.vec_sub(str(obj_pos.x), "0", str(pos.x), "0")
	var length = fixed.vec_len(diff.x, diff.y)
	if obj is Fighter:
		if obj.hitlag_ticks == 0:
			var dir = fixed.normalized_vec_times(diff.x, diff.y, PUSH_FORCE)
			obj.apply_force(dir.x, dir.y)

	var dist_ratio = fixed.div(length, MAX_EXTRA_PUSH_DIST)
	if fixed.gt(dist_ratio, "1.0"):
		dist_ratio = "1.0"
	
	var extra_pull = fixed.mul(fixed.sub("1.0", dist_ratio), MAX_EXTRA_PUSH)
	var total_pull
	if !obj is Fighter:
		total_pull = fixed.add(PUSH_SPEED, extra_pull)
	else:
		total_pull = FIGHTER_PUSH_SPEED
	if fixed.gt(total_pull, length):
		total_pull = length
	
	var dir = fixed.normalized_vec_times(diff.x, diff.y, total_pull)
	obj.move_directly(dir.x, dir.y)
