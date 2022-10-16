extends Node

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



signal game_started()
func _ready():
	ui_layer.connect("singleplayer_started", self, "_on_singleplayer_started")
	connect("game_started", ui_layer, "on_game_started")
	Network.connect("start_game", self, "_on_multiplayer_started")
	$"%P1ActionButtons".connect("action_clicked", self, "on_action_clicked", [1])
	$"%P2ActionButtons".connect("action_clicked", self, "on_action_clicked", [2])
	$"%GhostButton".connect("toggled", self, "_on_ghost_button_toggled")

func _on_singleplayer_started():
	singleplayer = true
	setup_game(singleplayer)
	emit_signal("game_started")

func _on_multiplayer_started():
	singleplayer = false
	ReplayManager.playback = false
	setup_game(singleplayer)
	emit_signal("game_started")

func show_lobby():
	$"%Lobby".show()

func setup_game(singleplayer):
	hide_main_menu()
	if game:
		game.queue_free()
	call_deferred("setup_game_deferred", singleplayer)

func hide_main_menu():
	$"%MainMenu".hide()

func setup_game_deferred(singleplayer):
	game = preload("res://Game.tscn").instance()
	game_layer.add_child(game)
	game.connect("simulation_continue", self, "_on_simulation_continue")
	game.connect("player_actionable", self, "_on_player_actionable")
	game.connect("playback_requested", self, "_on_playback_requested")
	ui_layer.init(game)
	game.start_game(singleplayer)
	hud_layer.init(game)
	var p1 = game.get_player(1)
	var p2 = game.get_player(2)
	p1.debug_label = $"%DebugLabelP1"
	p2.debug_label = $"%DebugLabelP2"
	
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
	ghost_game.start_game(true)
	ghost_game.connect("ghost_finished", self, "start_ghost")
	game.call_deferred("copy_to", ghost_game)
	game.ghost_game = ghost_game
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
#	yield(get_tree(), "idle_frame")

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

func _on_playback_requested():
	ReplayManager.playback = true
	setup_game(singleplayer)
