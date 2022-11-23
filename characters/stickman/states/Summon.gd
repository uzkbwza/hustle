extends CharacterState

const KUNAI_SUMMON_SCENE = preload("res://characters/stickman/projectiles/StickmanSummonKunai.tscn")
const SLIDE_SUMMON_SCENE = preload("res://characters/stickman/projectiles/StickmanSummonSlide.tscn")
const SPAWN_X = 2
const SPAWN_Y = -16

func _tick():
	host.apply_fric()
	host.apply_forces()

func _frame_4():
#	host.update_facing()
	var pos = host.get_pos()
	if data.x != 0:
		var object = host.spawn_object(KUNAI_SUMMON_SCENE, SPAWN_X, SPAWN_Y, true, data.duplicate())
		object.set_facing(host.get_facing_int())
	else:
		var object = host.spawn_object(SLIDE_SUMMON_SCENE, SPAWN_X, SPAWN_Y)
		object.set_facing(host.get_facing_int())
#	var obj_state = object.state_machine.get_state("Default")
	host.can_summon = false
	
func is_usable():
	return .is_usable() and host.can_summon
