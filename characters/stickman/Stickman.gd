extends Fighter
var can_summon = true
var bomb_thrown = false
var bomb_projectile = null
var storing_momentum = false
var stored_momentum_x = ""
var stored_momentum_y = ""
var sticky_bombs_left = 3


func explode_sticky_bomb():
	if bomb_thrown and bomb_projectile:
		objs_map[bomb_projectile].explode()

func _ready():
	pass

func _tick():
	pass

func process_extra(extra):
	.process_extra(extra)
	if extra.has("explode"):
		if extra["explode"]:
			explode_sticky_bomb()

func on_got_hit():
	if bomb_projectile or bomb_thrown:
		bomb_thrown = false
		if objs_map.has(bomb_projectile):
			objs_map[bomb_projectile].disable()
			bomb_projectile = null
