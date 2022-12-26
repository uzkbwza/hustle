extends ThrowState


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _enter():
	host.grab_camera_focus()
	host.opponent.z_index = -2

func _exit():
	host.release_camera_focus()

func _tick():
#	update_throw_position()
	host.apply_grav_custom("0.66", "20")
	if current_tick % 12 == 0:
		host.play_sound("ArmSpin")
	if host.is_grounded():
		host.throw_pos_x = release_throw_pos_x
		host.throw_pos_y = release_throw_pos_y
		var pos = host.get_global_throw_pos()
		host.opponent.set_pos(pos.x, pos.y)
		host.opponent.update_facing()
		return "KillProcessLanding"
