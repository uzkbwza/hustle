extends SuperMove

const VERTICAL_FORCE = "-3"
const HORIZ_FORCES = ["5", "9", "14"]

const OBJ_POS_X = 5
const OBJ_POS_Y = -16


func _frame_6():
	for i in range(3):
		var obj = host.spawn_object(preload("res://characters/stickman/projectiles/Caltrops.tscn"), OBJ_POS_X, OBJ_POS_Y)
		obj.apply_force_relative(HORIZ_FORCES[i], VERTICAL_FORCE)
	pass
