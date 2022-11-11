extends Node

signal game_started()

onready var ui_layer = $UILayer
onready var game_layer = $GameLayer
onready var hud_layer = $HudLayer

var singleplayer = false
var game
var ghost_game

var afterimages = []

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
	$"%GhostWaitTimer".connect("timeout", self, "_on_ghost_wait_timer_timeout")
	$"%FreezeOnMyTurn".connect("pressed", self, "start_ghost")
	$"%FreezeOnMyTurn".connect("toggled", Global, "save_option", ["freeze_ghost_prediction"])
	$"%AfterimageButton".connect("pressed", self, "start_ghost")
	$"%AfterimageButton".connect("toggled", Global, "save_option", ["ghost_afterimages"])
	$"%GameUI".hide()
	$"%MainMenu".show()
	ReplayManager.play_full = false
	if Network.multiplayer_active:
		Network.stop_multiplayer()
	Network.connect("player_disconnected", self, "_on_player_disconnected")
	$"%FreezeOnMyTurn".set_pressed_no_signal(Global.freeze_ghost_prediction)
	$"%AfterimageButton".set_pressed_no_signal(Global.ghost_afterimages)
func _on_player_disconnected():
	$"%OpponentDisconnectedLabel".show()

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

func _on_ghost_wait_timer_timeout():
	if is_instance_valid(game):
		start_ghost()

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
	if data.has("turn_time"):
		ui_layer.set_turn_time(data.turn_time)
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
	$"%GhostWaitTimer".start()
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
	$"%AdvantageLabel".text = ""
	pass

func start_ghost():
	call_deferred("_start_ghost")

func _process(_delta):
	align_afterimages()
	if is_instance_valid(game):
		$"%SpeedLines".set_direction(game.camera.current_direction)
		$"%SpeedLines".set_speed(game.camera.current_speed / game.camera.zoom.x)
		$"%SpeedLines".tick = game.current_tick
		$"%SpeedLines".on = !game.is_waiting_on_player()

func align_afterimages():
	if is_instance_valid(game):
		var center = -game.camera_snap_position / game.camera.zoom.x
#		center.y = min(center.y, ghost_game.camera.limit_bottom)
		for image in $"%Afterimages".get_children():
			image.rect_position = center + image.start_position / game.camera.zoom.x + game.camera.offset / game.camera.zoom.x
			image.visible = $"%AfterimageButton".pressed

func _start_ghost():
	if !$"%GhostWaitTimer".is_stopped():
		yield($"%GhostWaitTimer", "timeout")
		return
	stop_ghost()
	for child in $"%GhostViewport".get_children():
		child.queue_free()
	afterimages = []
	$"%AfterImage1".texture = null
	$"%AfterImage2".texture = null
	if !$"%GhostButton".pressed:
		return
	if ReplayManager.playback:
		return
	if !is_instance_valid(game):
		return
	
	ghost_game = preload("res://Game.tscn").instance()
	ghost_game.is_ghost = true
	$"%GhostViewport".add_child(ghost_game)
	ghost_game.start_game(true, match_data)
	ghost_game.connect("ghost_finished", self, "ghost_finished")
	ghost_game.connect("make_afterimage", self, "make_afterimage", [], CONNECT_DEFERRED)
	ghost_game.connect("ghost_my_turn", self, "ghost_my_turn", [], CONNECT_DEFERRED)
	ghost_game.ghost_speed = $"%GhostSpeed".get_speed()
	ghost_game.ghost_freeze = $"%FreezeOnMyTurn".pressed
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
	call_deferred("fix_ghost_objects", ghost_game)

func ghost_my_turn():
	$GhostMyTurnSound.play()

func make_afterimage():
	if !$"%AfterimageButton".pressed:
		return
	var img = $"%GhostViewport".get_texture().get_data()
	
	var img_dest = Image.new()
	img_dest.create(img.get_width(), img.get_height(), false, img.get_format())
	img_dest.blit_rect(img, Rect2(Vector2(), Vector2(img.get_width(), img.get_height())), Vector2.ZERO)
	img_dest.flip_y()
	# Create a texture for it.
	var tex = ImageTexture.new()
	tex.create_from_image(img_dest)
	
	var texture_rect = $"%AfterImage1" if $"%AfterImage1".texture == null else $"%AfterImage2"
	texture_rect.start_position = game.camera_snap_position
	texture_rect.texture = tex

func ghost_finished():
#	yield(get_tree(), "idle_frame")
	start_ghost()

func fix_ghost_objects(ghost_game_):
	for obj_name in ghost_game_.objs_map:
		var object = ghost_game_.objs_map[obj_name]
		if object:
			object.is_ghost = true

func stop_ghost():
	if game:
		game.ghost_game = null
	for child in $"%GhostViewport".get_children():
		child.hide()
		child.ghost_hidden = true
	for child in $"%Afterimages".get_children():
		child.texture = null

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
