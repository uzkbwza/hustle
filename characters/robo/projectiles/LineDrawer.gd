extends Node2D

export var color: Color
var width = 1

func _process(_delta):
	update()

func _draw():
	if width:
		draw_line(Vector2(), Vector2(0, -2000), color, width)
