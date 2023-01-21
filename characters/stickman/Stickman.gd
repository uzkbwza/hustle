extends Fighter
var can_summon = true
var bomb_thrown = false
var bomb_projectile = null
var storing_momentum = false
var stored_momentum_x = ""
var stored_momentum_y = ""
var sticky_bombs_left = 3
var quick_slash_start_pos_x = 0
var quick_slash_start_pos_y = 0
var quick_slash_move_dir_x = "0"
var quick_slash_move_dir_y = "0"

func explode_sticky_bomb():
	if bomb_thrown and bomb_projectile:
		objs_map[bomb_projectile].explode()

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

func stack_move_in_combo(move_name):
	.stack_move_in_combo(move_name)
	if combo_moves_used.has("PalmStrike") and combo_moves_used["PalmStrike"] >= 3:
		unlock_achievement("ACH_STERNUM_EXPLODER")
