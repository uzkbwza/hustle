extends CharacterState

class_name Getup

const GROUND_FRIC = "0.125"

export var hard = false

func _frame_0():
#	host.start_invulnerability()
	var vel = host.get_vel()
	host.set_vel(vel.x, "0")
	host.set_grounded(true)
	host.set_pos(host.get_pos().x, 0)
	host.on_the_ground = true
	host.colliding_with_opponent = false
	host.play_sound("HitBass")
	if !host.is_ghost:
		var camera = get_tree().get_nodes_in_group("Camera")[0]
		if hard:
			camera.bump(Vector2.UP, 7, 0.35)
		else:
			camera.bump(Vector2.UP, 6, 0.25)

func _exit():
	host.on_the_ground = false
	host.colliding_with_opponent = true

func _tick():
	host.apply_x_fric(GROUND_FRIC)
#	host.apply_fric()
	host.apply_forces_no_limit()
	if host.hp <= 0:
		endless = true
