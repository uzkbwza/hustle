extends RollDodge

const DOWN_ROLL_SPEED = "10"

var down = false

func _enter():
	._enter()
	down = false
	land_cancel = false
	if data.y > 0:
		host.apply_force("0", DOWN_ROLL_SPEED)
		land_cancel = true
		down = true
		
func _frame_6():
	if down:
		host.end_invulnerability()
		host.end_throw_invulnerability()
		host.end_projectile_invulnerability()
