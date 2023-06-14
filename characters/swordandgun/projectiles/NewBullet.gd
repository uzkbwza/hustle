extends BaseProjectile

const SPEED = "40" 

var dir_x = 0
var dir_y = 0

var last_pos_visual = Vector2()
var last_pos_visual_ricochet = Vector2()

var ricochet = false
var speed = SPEED

func init(pos=null):
	.init(pos)
	last_pos_visual = get_pos_visual()

func tick():
	last_pos_visual = get_pos_visual()
	.tick()
	pass

func _draw():
	if !disabled:
		draw_line(to_local(last_pos_visual), Vector2(), Color("f2ff31"), 4.0)
		if to_local(last_pos_visual) == Vector2():
			draw_circle(Vector2(), 6.0, Color("f2ff31"))
