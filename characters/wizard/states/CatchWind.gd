extends WizardState

const PULL_SPEED = "-5"
const MAX_EXTRA_PULL_DIST = "200"
const MAX_EXTRA_PULL = "-10"
const PULL_FORCE = "-1"
const FIGHTER_PULL_SPEED = "-2"
 

onready var windbox = $WindBox
onready var bigger_windbox = $WindBox2
onready var throwbox = $ThrowBox

func _tick():
	$"%WindParticle".stop_emitting()
	if throwbox.active and throwbox.enabled:
		var wb = windbox if !host.initiative else bigger_windbox
		$"%WindParticle".start_emitting()
		var windbox_hitting = []
		wb.facing = host.get_facing()
		var pos = host.get_pos()
		wb.update_position(pos.x, pos.y)
		for obj in host.objs_map.values():
			if obj is BaseObj and !obj == host and !obj.is_grounded() and obj.current_state().state_name != "Burst" and wb.overlaps(obj.hurtbox):
				if obj is BaseProjectile:
					if obj.disabled:
						continue
					if !obj.movable:
						continue
				windbox_hitting.append(obj)
		for obj in windbox_hitting:
			pull_object(obj)

func _exit():
	$"%WindParticle".stop_emitting()
	host.release_opponent()


func pull_object(obj):
	var throw_pos = throwbox.get_absolute_position()
	var obj_pos = obj.get_pos()
	var diff = fixed.vec_sub(str(obj_pos.x), str(obj_pos.y), str(throw_pos.x), str(throw_pos.y))
	var length = fixed.vec_len(diff.x, diff.y)
	if obj is Fighter:
		var dir = fixed.normalized_vec_times(diff.x, diff.y, PULL_FORCE)
		obj.apply_force(dir.x, dir.y)

	var dist_ratio = fixed.div(length, MAX_EXTRA_PULL_DIST)
	if fixed.gt(dist_ratio, "1.0"):
		dist_ratio = "1.0"
	
	var extra_pull = fixed.mul(fixed.sub("1.0", dist_ratio), MAX_EXTRA_PULL)
	var total_pull
	if !obj is Fighter:
		total_pull = fixed.add(PULL_SPEED, extra_pull)
	else:
		total_pull = FIGHTER_PULL_SPEED
	if fixed.gt(total_pull, length):
		total_pull = length
	
	var dir = fixed.normalized_vec_times(diff.x, diff.y, total_pull)
	obj.move_directly(dir.x, dir.y)
