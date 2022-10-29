extends Node

signal game_started()

onready var ui_layer = $UILayer
onready var game_layer = $GameLayer
onready var hud_layer = $HudLayer

var singleplayer = false
var game
var ghost_game

var p1_ghost_action
var p1_ghost_data
var p1_ghost_extra

var p2_ghost_action
var p2_ghost_data
var p2_ghost_extra

var match_data = {}

func _ready():
	ui_layer.connect("singleplayer_started", self, "_on_game_started", [true])
	ui_layer.connect("loaded_replay", self, "_on_loaded_replay")
	connect("game_started", ui_layer, "on_game_started")
	Network.connect("start_game", self, "_on_game_started", [false])
	$"%P1ActionButtons".connect("action_clicked", self, "on_action_clicked", [1])
	$"%P2ActionButtons".connect("action_clicked", self, "on_action_clicked", [2])
	$"%GhostButton".connect("toggled", self, "_on_ghost_button_toggled")
	$"%SaveReplayButton".connect("pressed", self, "save_replay")
	$"%CharacterSelect".connect("match_ready", self, "_on_match_ready")
	$"%GhostSpeed".connect("value_changed", self, "_on_ghost_speed_changed")
	$"%GameUI".hide()
	$"%MainMenu".show()
	ReplayManager.play_full = false

func _on_game_started(singleplayer):
	if is_instance_valid(game):
		game.free()
		game = null
		stop_ghost()
	self.singleplayer = singleplayer
	Network.replay_saved = false
	hide_main_menu()
	$"%CharacterSelect".show()
	$"%CharacterSelect".init(singleplayer)
	$"%DirectConnectLobby".hide()
	$"%Lobby".hide()

func _on_loaded_replay(match_data):
	match_data["replay"] = true
	_on_match_ready(match_data)

func _on_match_ready(data):
	match_data = data
	singleplayer = true if match_data.has("replay") else data["singleplayer"]
	if !match_data.has("replay"):
		ReplayManager.playback = false
	setup_game(singleplayer, data)
	emit_signal("game_started")

func show_lobby():
	$"%DirectConnectLobby".show()
	$"%Lobby".show()

func setup_game(singleplayer, data):
	hide_main_menu()
	if game:
		game.queue_free()
	call_deferred("setup_game_deferred", singleplayer, data)

func save_replay():
	var filename = ReplayManager.save_replay(match_data, $"%ReplayName".text)
	$"%SaveReplayButton".disabled = true
	$"%SaveReplayButton".text = "saved"
	$"%SaveReplayLabel".text = "saved replay to " + filename

func hide_main_menu():
	$"%MainMenu".hide()

func setup_game_deferred(singleplayer, data):
	game = preload("res://Game.tscn").instance()
	game_layer.add_child(game)
	game.connect("simulation_continue", self, "_on_simulation_continue")
	game.connect("player_actionable", self, "_on_player_actionable")
	game.connect("playback_requested", self, "_on_playback_requested")
	game.start_game(singleplayer, data)
	ui_layer.init(game)
	hud_layer.init(game)
	var p1 = game.get_player(1)
	var p2 = game.get_player(2)
	p1.debug_label = $"%DebugLabelP1"
	p2.debug_label = $"%DebugLabelP2"
	var p1_info_scene = p1.player_info_scene.instance()
	var p2_info_scene = p2.player_info_scene.instance()
	p1_info_scene.set_fighter(p1)
	p2_info_scene.set_fighter(p2)
	if $"%P1InfoContainer".get_child(0) is PlayerInfo:
		$"%P1InfoContainer".remove_child($"%P1InfoContainer".get_child(0))
	if $"%P2InfoContainer".get_child(0) is PlayerInfo:
		$"%P2InfoContainer".remove_child($"%P2InfoContainer".get_child(0))
	$"%P1InfoContainer".add_child(p1_info_scene)
	$"%P1InfoContainer".move_child(p1_info_scene, 0)
	$"%P2InfoContainer".add_child(p2_info_scene)
	$"%P2InfoContainer".move_child(p2_info_scene, 0)
	
func _on_ghost_button_toggled(toggled):
	if toggled:
		start_ghost()
	else:
		stop_ghost()

func _on_player_actionable():
#	if singleplayer or Network.player_id == id:
	ui_layer.on_player_actionable()
	start_ghost()

func on_action_clicked(action, data, extra, player_id):
	if player_id == 1:
		p1_ghost_action = action
		p1_ghost_data = data
		p1_ghost_extra = extra
	else:
		p2_ghost_action = action
		p2_ghost_data = data
		p2_ghost_extra = extra
	start_ghost()
	pass

func start_ghost():
	call_deferred("_start_ghost")

func _start_ghost():
	stop_ghost()
	for child in $"%GhostViewport".get_children():
		child.queue_free()
	if !$"%GhostButton".pressed:
		return
	if ReplayManager.playback:
		return
	ghost_game = preload("res://Game.tscn").instance()
	ghost_game.is_ghost = true
	$"%GhostViewport".add_child(ghost_game)
	ghost_game.start_game(true, match_data)
	ghost_game.connect("ghost_finished", self, "start_ghost")
	game.call_deferred("copy_to", ghost_game)
	game.ghost_game = ghost_game
	ghost_game.ghost_speed = $"%GhostSpeed".get_speed()
	var p1 = ghost_game.get_player(1)
	var p2 = ghost_game.get_player(2)

	p1.queued_action = p1_ghost_action
	p1.queued_data = p1_ghost_data
	p1.queued_extra = p1_ghost_extra
	p1.is_ghost = true

	p2.queued_action = p2_ghost_action
	p2.queued_data = p2_ghost_data
	p2.queued_extra = p2_ghost_extra
	p2.is_ghost = true
	call_deferred("fix_ghost_objects")
#	yield(get_tree(), "idle_frame")

func fix_ghost_objects():
	for obj_name in ghost_game.objs_map:
		var object = ghost_game.objs_map[obj_name]
		if object:
			object.is_ghost = true

func stop_ghost():
	if game:
		game.ghost_game = null
	for child in $"%GhostViewport".get_children():
		child.hide()
		child.ghost_hidden = true
#		child.queue_free()

func _on_simulation_continue():
	p1_ghost_action = null
	p1_ghost_data = null
	p1_ghost_extra = null
	call_deferred("stop_ghost")

func _on_ghost_speed_changed(_value):
	if game:
		_start_ghost()

func _on_playback_requested():
	ReplayManager.playback = true
	setup_game(singleplayer, match_data)
