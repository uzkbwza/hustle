extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


var fighter

func _process(delta):
	if is_instance_valid(fighter):
		visible = Global.show_extra_info
#		var vel = fighter.get_vel()
#		text = ("speed: %0.2f\n" % float(fighter.fixed.vec_len(vel.x, vel.y))) + \
#		text = ("sad: %s\n" % fighter.penalty)
#		("x: %s\ny: %s\n" % [fighter.get_pos().x, fighter.get_pos().y])
