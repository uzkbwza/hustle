extends Node

var game
var singleplayer = false
onready var ui_layer = $UILayer
onready var game_layer = $GameLayer
onready var hud_layer = $HudLayer

signal game_started()
func _ready():
	ui_layer.connect("singleplayer_started", self, "_on_singleplayer_started")
	connect("game_started", ui_layer, "on_game_started")
	Network.connect("start_game", self, "_on_multiplayer_started")

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
	game.connect("player_actionable", self, "_on_player_actionable")
	game.connect("playback_requested", self, "_on_playback_requested")
	ui_layer.init(game)
	game.start_game(singleplayer)
	hud_layer.init(game)
	var p1 = game.get_player(1)
	var p2 = game.get_player(2)
	p1.debug_label = $"%DebugLabelP1"
	p2.debug_label = $"%DebugLabelP2"
	
func _on_player_actionable():
#	if singleplayer or Network.player_id == id:
	ui_layer.on_player_actionable()

func _on_playback_requested():
	ReplayManager.playback = true
	setup_game(singleplayer)
