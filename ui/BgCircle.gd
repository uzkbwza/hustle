extends Control

const SIZE = 70
const SIZE2 = 300
const SIZE3 = 350
const VARIANCE = 5
const VARIANCE2 = 8
const SPEED = 8.40
const SPEED2 = 9.40

var draw_bg_circle = false

func _process(delta):
	draw_bg_circle = !is_instance_valid(Global.current_game)
	update()

func _draw():
	if draw_bg_circle:
		var diff = Utils.wave(-VARIANCE, VARIANCE, SPEED)
		var diff2 = Utils.wave(-VARIANCE2, VARIANCE2, SPEED2)
		draw_arc(Vector2(), SIZE + diff, 0, TAU, 64, Color("04579a"), 2.0)
		draw_arc(Vector2(), SIZE2 + diff2, 0, TAU, 64, Color("0a1d3a"), 60.0)
		draw_arc(Vector2(), SIZE3 + diff2, 0, TAU, 64, Color("0a1d3a"), 160.0)
