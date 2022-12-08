tool

extends TextureRect

var throw_pos
var drawing_throw_pos = false

func reset():
	throw_pos = null
	drawing_throw_pos = false
	update()

func set_throw_pos(position):
	throw_pos = position
	drawing_throw_pos = true
	update()

func _draw():
	if drawing_throw_pos:
		draw_circle(throw_pos, 4, Color.black)
		draw_circle(throw_pos, 3, Color.red)
