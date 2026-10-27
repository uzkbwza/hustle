extends "res://bordermanager/FullArtManager.gd"



onready var sfx_nodes = {
	1: [$"%LeftSFX1", $"%LeftSFX2"],
	2: [$"%RightSFX1", $"%RightSFX2"],
}

# currently unused, planned for use
var swap_sides = false



func _ready():
	for player_id in sfx_nodes:
		for node in sfx_nodes[player_id]:
			node.get_node("Timer").connect("timeout", node, "play")
	reset()



func reset():
	$"%LeftAnimPlayer".play("RESET")
	$"%RightAnimPlayer".play("RESET")
	$"%LeftLoadingAnimPlayer".play("RESET")
	$"%RightLoadingAnimPlayer".play("RESET")
	
	set_style_params(1, null)
	set_style_params(2, null)
	apply_style(1, null)
	apply_style(2, null)
	
	for player_id in sfx_nodes:
		for node in sfx_nodes[player_id]:
			node.stop()
			node.get_node("Timer").stop()



func animate_reveal(id :int):
	var anim_player = $"%LeftAnimPlayer" if id == 1 else $"%RightAnimPlayer"
	anim_player.play("reveal")
	BorderManager.set_border_color(id, BorderManager.dark_color)



func animate_unreveal(id :int):
	var anim_player = $"%LeftAnimPlayer" if id == 1 else $"%RightAnimPlayer"
	anim_player.play("RESET")
	BorderManager.set_border_color(id, BorderManager.menu_color)



func animate_load_started(id :int):
	var anim_player = $"%LeftLoadingAnimPlayer" if id == 1 else $"%RightLoadingAnimPlayer"
	anim_player.play("loop")



func animate_load_done(id :int):
	var anim_player = $"%LeftLoadingAnimPlayer" if id == 1 else $"%RightLoadingAnimPlayer"
	anim_player.play("load_done")



func set_sfx_data(id, sfx_data : Array):
	if not sfx_nodes.has(id):
		return
	var side_sfx_nodes = sfx_nodes[id]
	var sound_num = 0
	for entry in sfx_data:
		if not (entry is Dictionary):
			continue
		var used_sfx_node = side_sfx_nodes[sound_num]
		var sfx_timer :Timer = used_sfx_node.get_node("Timer")
		
		used_sfx_node.pitch_scale = entry.get("base_pitch", 0.0)
		used_sfx_node.pitch_scale_ = used_sfx_node.pitch_scale
		used_sfx_node.pitch_variation = entry.get("pitch_variation", 0.1)
		used_sfx_node.stream = entry.get("sfx", null)
		used_sfx_node.volume_db = entry.get("volume_db", -10)
		sfx_timer.wait_time = max(entry.get("delay", 0), 0.00001)
		sfx_timer.start()
		
		sound_num += 1
		if sound_num >= 2: # max sounds
			break

