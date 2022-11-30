extends "res://ObjectState.gd"

#This is an export variable so when the scene is saved it can stay changed
export var pitch_var = 0.1
export var pitch_scale = 1

#This is a modified version of the original setup function
func setup_audio():
	if enter_sfx:
		enter_sfx_player = VariableSound2D.new()
		add_child(enter_sfx_player)
		enter_sfx_player.bus = "Fx"
		enter_sfx_player.stream = enter_sfx
		enter_sfx_player.volume_db = enter_sfx_volume
		enter_sfx_player.pitch_variation = pitch_var #Here is where the pitch_variation is set for enter_sfx

	if sfx:
		sfx_player = VariableSound2D.new()
		add_child(sfx_player)
		sfx_player.bus = "Fx"
		sfx_player.stream = sfx
		sfx_player.volume_db = sfx_volume
		sfx_player.pitch_variation = pitch_var #Here is where the varitation is set for sfx
		sfx_player.pitch_scale_ = pitch_scale
