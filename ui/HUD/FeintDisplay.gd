extends Control

const texture = preload("res://ui/HUD/feint.png")
const CIRCLE_RADIUS = 6
const CIRCLE_DIST = 14

export var circle_color: Color = Color.white
export var player_id = 1

var fighter: Fighter

func _process(_delta):
	update()

func _draw():
	if is_instance_valid(fighter):
		var y = rect_size.y / 2
		var x_start = CIRCLE_RADIUS if player_id == 1 else rect_size.x - CIRCLE_RADIUS
		var x_dist = CIRCLE_DIST if player_id == 1 else -CIRCLE_DIST
		for i in range(fighter.feints):
			var offs_x = texture.get_width() / 2
			var offs_y = texture.get_height() / 2
			draw_texture(texture, Vector2(x_start + x_dist * i - offs_x, y - offs_y), circle_color)
