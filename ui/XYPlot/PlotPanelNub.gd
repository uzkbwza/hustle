tool
extends Control

var pos_data = Vector2()

onready var parent = get_parent()

func update_pos(pos):
	pos_data = pos
	update()

func _draw():
	var midpoint = parent.midpoint() # + Vector2(0, 1)
	draw_line(midpoint, pos_data, Color.white, 1.0)
	draw_circle(pos_data, 3, Color.white)
