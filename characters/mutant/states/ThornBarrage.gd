extends BeastState

const ARC = "34"
const AIM = "45"
const NUM_PROJECTILES = 6
const PROJECTILES_PER_FRAME = 1
const PROJECTILE = preload("res://characters/mutant/projectiles/CausticThorn.tscn")
const JUMP_FORCE = -3
const GROUND_JUMP_FORCE = -6
const GROUND_JUMP_FORCE_HORIZ = -1

var projectiles_left = 0

export var air = false


func _frame_5():
	projectiles_left = NUM_PROJECTILES
	host.play_sound("HitBass")
	if air:
		if host.is_grounded():
			host.apply_force(GROUND_JUMP_FORCE_HORIZ, GROUND_JUMP_FORCE)
#		host.set_vel(host.get_vel().x, "0")
		else:
			host.apply_force(0, JUMP_FORCE)
#	host.add_juke_pips(-1)

func _tick():
	for j in range(PROJECTILES_PER_FRAME):
		if projectiles_left > 0:
			var i = (NUM_PROJECTILES - projectiles_left) if host.get_facing_int() > 0 else projectiles_left
#			var i = (NUM_PROJECTILES - projectiles_left)
			var r = fixed.div(str(i), str(NUM_PROJECTILES - 1))
			var arc = fixed.deg2rad(ARC)
			var angle = fixed.add(fixed.lerp_string(fixed.mul(arc, "0.5"), fixed.mul(arc, "-0.5"), r), fixed.mul(fixed.deg2rad(AIM), str(host.get_facing_int())))
			if air:
				angle = fixed.mul(angle, "-1")
#			angle = fixed.mul(angle, str(host.get_facing_int()))
	#		print(angle)
			var vec = fixed.rotate_vec("0", "-1" if !air else "1", angle)
			var projectile = PROJECTILE
			host.spawn_object(PROJECTILE, -8, -16 if !air else -32, true, {"dir": vec, "angle": angle})
			projectiles_left -= 1

#
#func is_usable():
#	return .is_usable() and host.juke_pips > 0
