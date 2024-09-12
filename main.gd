extends Node

signal game_started()
signal game_setup()

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

var started_ghost_this_frame = false

var _Global = Network

func _ready():
	ui_layer.connect("singleplayer_started", self, "_on_game_started", [true])
	ui_layer.connect("loaded_replay", self, "_on_loaded_replay")
	connect("game_started", ui_layer, "on_game_started")
	Network.connect("start_game", self, "_on_game_started", [false])
	Network.connect("match_ready", self, "_on_match_ready")
	SteamLobby.connect("received_spectator_match_data", self, "_on_received_spectator_match_data")
	$"%P1ActionButtons".connect("action_clicked", self, "on_action_clicked", [1])
	$"%P2ActionButtons".connect("action_clicked", self, "on_action_clicked", [2])
	$"%GhostButton".connect("toggled", self, "_on_ghost_button_toggled")
	$"%SaveReplayButton".connect("pressed", self, "save_replay")
	$"%CharacterSelect".connect("match_ready", self, "_on_match_ready")
	$"%GhostSpeed".connect("value_changed", self, "_on_ghost_speed_changed")
	$"%GhostWaitTimer".connect("timeout", self, "_on_ghost_wait_timer_timeout")
	$"%FreezeOnMyTurn".connect("pressed", self, "start_ghost")
	$"%FreezeOnMyTurn".connect("toggled", Global, "save_option", ["freeze_ghost_prediction"])
	$"%FreezeSound".connect("toggled", Global, "save_option", ["freeze_ghost_sound"])
	$"%FreezeSound".connect("pressed", self, "start_ghost")
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
#	setup_main_menu_game()
	SteamLobby.SETTINGS_LOCKED = false
	randomize()
	$"%NagWindow".hide()
	$"%NagWindow".rect_position = Vector2(randi() % 640, randi() % 360)
	Global.connect("nag_window", $"%NagWindow", "show")
	SteamLobby._stop_spectating()
	SteamLobby.quit_match()
	$"%P1ShowStyle".connect("toggled", self, "_on_show_style_toggled", [1])
	$"%P2ShowStyle".connect("toggled", self, "_on_show_style_toggled", [2])
	ReplayManager.replaying_ingame = false
#	SteamHustle.print_all_achievements()

	########################### charloader
	var container = $"%OptionsContainer".get_node("VBoxContainer").get_node("Contents").get_node("VBoxContainer").get_node("VBoxContainer")

	if (container.get_node_or_null("LoadOnStart") == null):
		var btt = Button.new()
		btt.name = "DeleteCache"
		btt.text = "delete character cache"
		container.add_child(btt)
		container.move_child(btt, len(container.get_children()) - 4)
		btt.connect("pressed", self, "_delete_char_cache", [btt])
#
	var loaded_mods = false
	while !Global.mods_loaded:
		loaded_mods = true
		hide_main_menu(true)
		$"%LoadingCharactersLabel".show()
		$InputBlocker.show()
		$"%LoadingCharactersLabel2".show()
		$"%LoadingCharactersLabel2".text = Global.loading_character
		yield(get_tree(), "idle_frame")

	if loaded_mods:
		$"%MainMenu".show()
		$InputBlocker.hide()
		$"%LoadingCharactersLabel2".hide()
		$"%LoadingCharactersLabel".hide()

func _delete_char_cache(btt):
	var dir = Directory.new()
	_Global.css_instance.charPackages = {}
	for f in ModLoader._get_all_files("user://char_cache", "pck"):
		dir.remove(f)
	get_tree().quit()

func _on_show_style_toggled(on, player_id):
	if is_instance_valid(game):
		var player = game.get_player(player_id)
		if on:
			player.reapply_style()
		else:
			player.reset_style()

func _on_player_disconnected():
	$"%OpponentDisconnectedLabel".show()
#	ui_layer._on_forfeit_button_pressed()
	ui_layer._on_opponent_disconnected()
	
	if !is_instance_valid(game):
		Global.reload()

func _on_game_started(singleplayer):
	ui_layer.reset_ui()
	if is_instance_valid(game):
		game.free()
		game = null
		stop_ghost()
	self.singleplayer = singleplayer
	Network.replay_saved = false
	hide_main_menu(true)

	if $"%P1InfoContainer".get_child(0) is PlayerInfo:
		$"%P1InfoContainer".get_child(0).queue_free()
	if $"%P2InfoContainer".get_child(0) is PlayerInfo:
		$"%P2InfoContainer".get_child(0).queue_free()

	$"%CharacterSelect".show()
	$"%CharacterSelect".init(singleplayer)
	$"%DirectConnectLobby".hide()
	$"%Lobby".hide()
	$"%SteamLobby".hide()

func _on_ghost_wait_timer_timeout():
	if is_instance_valid(game):
		start_ghost()

func _on_loaded_replay(match_data):
#	match_data["replay"] = true
#	_on_match_ready(match_data)
	_Global.css_instance.net_loadReplayChars([match_data.selected_characters[1]["name"], match_data.selected_characters[2]["name"], match_data])
	match_data["replay"] = true
	_on_match_ready(match_data)

func _on_received_spectator_match_data(data):
#	data["spectating"] = true
#	_on_match_ready(data)
	if get_node("/root/SteamLobby/LoadingSpectator/Label"):
		get_node("/root/SteamLobby/LoadingSpectator/Label").text = "Spectating...\n(Loading Characters, this may take a while)"
	_Global.css_instance.net_loadReplayChars([data.selected_characters[1]["name"], data.selected_characters[2]["name"], data])
	data["spectating"] = true
	_on_match_ready(data)

func _on_match_ready(data):
	match_data = data
	singleplayer = true if match_data.has("replay") else data["singleplayer"]
	if !match_data.has("replay"):
		ReplayManager.playback = false
	SteamLobby.SETTINGS_LOCKED = false
	setup_game(singleplayer, data)
	emit_signal("game_started")


func show_lobby():
	$"%DirectConnectLobby".show()
	$"%Lobby".show()

func setup_game(singleplayer, data):
	hide_main_menu(true)
	if is_instance_valid(game):
		game.queue_free()
	call_deferred("setup_game_deferred", singleplayer, data)
	emit_signal("game_setup")

func setup_main_menu_game():
	game = preload("res://Game.tscn").instance()
	game_layer.add_child(game)

func save_replay():
	var filename = ReplayManager.save_replay(match_data, $"%ReplayName".text)
	$"%SaveReplayButton".disabled = true
	$"%SaveReplayButton".text = "saved"
	$"%SaveReplayLabel".text = "saved replay to " + filename

func hide_main_menu(all=false):
	ui_layer.hide_main_menu(all)

func _format_p2_name(p2_name: String):
	if p2_name.begins_with("F-") and "__" in p2_name and p2_name.split("__").size() > 1:
		return p2_name.split("__")[1]
	return p2_name

func setup_game_deferred(singleplayer, data):
	game = preload("res://Game.tscn").instance()
	game_layer.add_child(game)
	game.connect("simulation_continue", self, "_on_simulation_continue")
	game.connect("player_actionable", self, "_on_player_actionable")
	game.connect("playback_requested", self, "_on_playback_requested")
	game.connect("zoom_changed", self, "_on_zoom_changed")
	
	Network.game = game
	
	if !data.has("user_data"):
		if Network.multiplayer_active:
			data["user_data"] = {
				"p1": Network.pid_to_username(1),
				"p2": Network.pid_to_username(2),
			}
		else:
			data["user_data"] = {
				"p1": Global.get_player_data().username,
				"p2": _format_p2_name(data.selected_characters[2]["name"]),
			}
	
	if game.start_game(singleplayer, data) is bool:
		return
	if data.has("turn_time"):
		if !Network.undo or (data.has("chess_timer") and !data.chess_timer):
			ui_layer.set_turn_time(data.turn_time, (data.has("chess_timer") and data.chess_timer))
		else:
			ui_layer.start_timers()
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
#		$"%P1InfoContainer".remove_child($"%P1InfoContainer".get_child(0))
		$"%P1InfoContainer".get_child(0).queue_free()
	if $"%P2InfoContainer".get_child(0) is PlayerInfo:
#		$"%P2InfoContainer".remove_child($"%P2InfoContainer".get_child(0))
		$"%P2InfoContainer".get_child(0).queue_free()
	for child in $"%ActivePlayerInfoContainer".get_children():
		child.queue_free()

	$"%P1InfoContainer".add_child(p1_info_scene)
	$"%P1InfoContainer".move_child(p1_info_scene, 0)
	$"%P2InfoContainer".add_child(p2_info_scene)
	$"%P2InfoContainer".move_child(p2_info_scene, 0)
	ui_layer.p1_info_scene = p1_info_scene
	ui_layer.p2_info_scene = p2_info_scene

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

func _physics_process(delta):
	set_deferred("started_ghost_this_frame", false)

func align_afterimages():
	if is_instance_valid(game):
		var zoom = game.camera.zoom.x * game.camera_zoom
		var center = -game.camera_snap_position / zoom
#		center.y = min(center.y, ghost_game.camera.limit_bottom)
		for image in $"%Afterimages".get_children():
			image.rect_position = center + image.start_position / zoom + game.camera.offset / zoom
			image.visible = $"%AfterimageButton".pressed

func _start_ghost():
	if started_ghost_this_frame:
		return
	started_ghost_this_frame = true
#	print("starting ghost" + str(randi()))
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
	if !game.prediction_enabled:
		return
#
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
	if Global.freeze_ghost_sound:
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
	if is_instance_valid(game):
		game.ghost_game = null
	for child in $"%GhostViewport".get_children():
		child.hide()
		child.ghost_hidden = true
	for child in $"%Afterimages".get_children():
		child.texture = null

func _on_zoom_changed():
	for child in $"%Afterimages".get_children():
		child.texture = null

func _on_simulation_continue():
	p1_ghost_action = null
	p1_ghost_data = null
	p1_ghost_extra = null
	call_deferred("stop_ghost")

func _on_ghost_speed_changed(_value):
	if is_instance_valid(game):
		_start_ghost()

func _on_playback_requested():
	ReplayManager.playback = true
	setup_game(singleplayer, match_data)

func _on_ReplayName_text_entered(_new_text):
	save_replay()

