extends BeastState


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _tick():
	if current_tick > 4 and current_tick < 12:
		host.move_directly_relative(3, 0)
		
