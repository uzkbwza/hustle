extends WizardState

const DOT = 4
const PUSH_SPEED = "5"
const MAX_EXTRA_PUSH_DIST = "200"
const MAX_EXTRA_PUSH = "10"
const PUSH_FORCE = "2"
const FIGHTER_PUSH_SPEED = "1"
const PUSHBACK_SPEED_X = "0.25"
const PUSHBACK_SPEED_Y = "0.25"
const COMBO_REDUCTION = "0.85"

onready var windbox = $WindBox
#onready var throwbox = $ThrowBox

func _tick():
	$"%GustParticle".stop_emitting()
#	if throwbox.active and throwbox.enabled:
	if current_tick < 15 and current_tick > 1:
		var dir = xy_to_dir(data.x, data.y)
		var wb = windbox
		$"%GustParticle".start_emitting()
		var angle = float(fixed.vec_to_angle(fixed.mul(dir.x, str(host.get_facing_int())), dir.y))
		$"%GustParticle".rotation = angle
		var windbox_hitting = []
		wb.facing = host.get_facing()
		var pos = host.get_pos()
		wb.update_position(pos.x, pos.y)
		for obj in host.objs_map.values():
			if obj is BaseObj and !obj == host and (obj.current_state() and obj.current_state().state_name != "Burst" and wb.overlaps(obj.hurtbox)):
				if obj is BaseProjectile:
					if obj.disabled:
						continue
					if !obj.movable:
						continue
				windbox_hitting.append(obj)
		for obj in windbox_hitting:
			push_object(obj, dir)
		var pushback_dir = xy_to_dir(data.x, data.y, "-1")
		host.apply_force(fixed.mul(pushback_dir.x, PUSHBACK_SPEED_X), fixed.mul(pushback_dir.y, PUSHBACK_SPEED_Y) if (!host.is_grounded() or host.hovering) else "0")

func _exit():
	$"%GustParticle".stop_emitting()
	host.gusts_in_combo += 1

func push_object(obj, dir):
#	if obj.data.object_data == null:
#		return
	var obj_pos = obj.get_pos()
	var pos = host.get_pos()
	var diff = fixed.vec_sub(str(obj_pos.x), "0", str(pos.x), "0")
	var length = fixed.vec_len(diff.x, diff.y)
	var dist_ratio = fixed.div(length, MAX_EXTRA_PUSH_DIST)

	if fixed.gt(dist_ratio, "1.0"):
		dist_ratio = "1.0"

	if obj is Fighter:
		if obj.hitlag_ticks == 0:
			var force = fixed.normalized_vec_times(dir.x, "0" if obj.is_grounded() else dir.y, fixed.mul(FIGHTER_PUSH_SPEED, fixed.sub("1.0", dist_ratio)))
			force = fixed.vec_mul(force.x, force.y, fixed.powu(COMBO_REDUCTION, host.gusts_in_combo))
			obj.apply_force(force.x, force.y)
	else:
		
		var extra_pull = fixed.mul(fixed.sub("1.0", dist_ratio), MAX_EXTRA_PUSH)
		var total_pull
		total_pull = fixed.add(PUSH_SPEED, extra_pull)
		if fixed.gt(total_pull, length):
			total_pull = length
	
		var force = fixed.normalized_vec_times(dir.x, dir.y, total_pull)
		obj.move_directly(force.x, force.y)
