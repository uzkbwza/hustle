extends Node2D

func _process(_delta):
	update()

func _draw():
	for hitbox in get_parent().get_active_hitboxes():
		box_draw(hitbox, Color.red)
	box_draw(get_parent().collision_box, Color.blue)
	box_draw(get_parent().hurtbox, Color.yellow if !get_parent().invulnerable else Color.green)

func box_draw(box, color: Color):
		var rect = box.get_rect_float()
		var fill = color
		var stroke = color
		fill.a = 0.25
		stroke.a = 0.5
		draw_rect(rect, fill, true)
		draw_rect(rect, stroke, false)
