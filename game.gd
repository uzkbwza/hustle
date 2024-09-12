extends Node2D

class_name Game

const GHOST_FRAMES = 90
const SUPER_FREEZE_TICKS = 20
const GHOST_ACTIONABLE_FREEZE_TICKS = 10
const CAMERA_MAX_Y_DIST = 210
const QUITTER_FOCUS_TICKS = 60
const CLASH_DAMAGE_DIFF = 25
const CAMERA_PADDING = 20

export(int) var char_distance = 200
export(int) var stage_width = 1100
export(int) var max_char_distance = 600
export(int) var time = 3000

signal player_actionable()
signal player_actionable_network()
signal simulation_continue()
signal playback_requested()
signal game_ended()
signal game_won(winner)
signal ghost_finished()
signal make_afterimage()
signal ghost_my_turn()
signal forfeit_started(id)
signal actions_submitted()
signal turn_started()
signal zoom_changed()

var p1_data
var p2_data

var p1_turn = false
var p2_turn = false

onready var camera: GoodCamera = $Camera2D
onready var objects_node = $Objects
onready var fx_node = $Fx

var mouse_pressed = false

var current_tick = -1
var max_replay_tick = 0
var game_started = false
var undoing = false
var singleplayer = false
var parry_freeze = false
var clashing_enabled = false

var game_paused = false

var buffer_playback = false
var buffer_edit = false

var game_end_tick = 0

var frame_passed = false

var game_finished = false

var ghost_cleaned = true

var asymmetrical_clashing = false

var forfeit = false

var quitter_focus = false
var quitter_focus_ticks = 0

var advance_frame_input = false

var frame_by_frame = false

var network_simulate_ready = true

var gravity_enabled = true

var is_ghost = false
var is_afterimage = false
var ghost_hidden = false
var ghost_game
var ghost_speed = 3
var ghost_tick = 0
var forfeit_player = null

var match_data = null
var simulated_once = false
var started_multiplayer = false
var prediction_enabled = true

var p1 = null
var p2 = null

var p1_username = null
var p2_username = null
var my_id = 1

var draw_stage = true

var snapping_camera = false 
var waiting_for_player_prev = false
var spectate_tick = -1
var global_gravity_modifier = "1.0"

var camera_snap_position = Vector2()

var objects: Array = []
var objs_map = {
	
}
var effects: Array = []

var drag_position = null

var real_tick = 0
var super_freeze_ticks = 0
var super_active = false
var prediction_effect = false
var p1_super = false
var p2_super = false
var hit_freeze = false
var ghost_freeze = false
var player_actionable = true
var network_sync_tick = -100
var ceiling_height = 400
var has_ceiling = true
var mouse_position = Vector2()

var ghost_simulated_ticks = 0

var is_in_replay = false

var ghost_actionable_freeze_ticks = 0
var ghost_p1_actionable = false
var ghost_p2_actionable = false
var made_afterimage = false

var p1_ghost_ready_tick
var p2_ghost_ready_tick

var spectating = false

var ghost_time = 0.0

var camera_zoom = 1.0

#var has_ghost_frozen_yet = false

func get_ticks_left():
	return time - Utils.int_min(current_tick, time)

func _ready():
	
	if is_ghost:
		hide()
		for object in objects_node.get_children():
			object.free()
		for fx in fx_node.get_children():
			fx.free()
		$GhostStartTimer.start()
		ghost_time = Time.get_unix_time_from_system()
	else:
		emit_signal("simulation_continue")

func _spawn_particle_effect(particle_effect: PackedScene, pos: Vector2, dir= Vector2.RIGHT):
	var obj = particle_effect.instance()
	add_child(obj)
	obj.tick()
	var facing = -1 if dir.x < 0 else 1
	obj.position = pos
	if facing < 0:
		obj.rotation = (dir * Vector2(-1, -1)).angle()
	else:
		obj.rotation = dir.angle()
	obj.scale.x = facing
	remove_child(obj)
	on_particle_effect_spawned(obj)

func connect_signals(object):
	object.connect("object_spawned", self, "on_object_spawned")
	object.connect("particle_effect_spawned", self, "on_particle_effect_spawned")

func copy_to(game: Game):
	if !game_started:
		return
#	var p1_pos = p1.get_pos()
#	var p2_pos = p2.get_pos()
#	print(p1_pos)
#	print(p2_pos)
#	game.p1.set_pos(p1_pos.x, p1_pos.y)
#	game.p2.set_pos(p2_pos.x, p2_pos.y)
	p1.chara.copy_to(game.p1.chara)
	p2.chara.copy_to(game.p2.chara)
	game.p1.update_data()
	game.p2.update_data()
	p1.copy_to(game.p1)
	p2.copy_to(game.p2)
	game.p1.hp = p1.hp
	game.p2.hp = p2.hp
	clean_objects()
	for object in game.objects:
		object.free()
	for fx in game.effects:
		fx.free()
	for object in objects:
		if is_instance_valid(object):
			if !object.disabled:
				var new_obj = load(object.filename).instance()
				game.on_object_spawned(new_obj)
				object.copy_to(new_obj)
			else:
				game.objs_map[str(game.objs_map.size() + 1)] = null
	game.camera.limit_left = camera.limit_left
	game.camera.limit_right = camera.limit_right


func _on_super_started(ticks, player):
	if is_ghost:
		return
	if ticks == 0:
		ticks = 0
		var state = player.current_state()
		if state.get("super_freeze_ticks") != null:
			if state.super_freeze_ticks > ticks:
				ticks = state.super_freeze_ticks
	super_freeze_ticks = ticks
	
	super_active = true
	if player == p1:
		p1_super = true
	if player == p2:
		p2_super = true

func get_screen_position(player_id):
	var screen_center = camera.get_camera_screen_center()
	var player_position = get_player(player_id).get_center_position_float()
	var result = player_position - screen_center
	return result / camera.zoom.x

func get_player(id) -> Fighter:
	if id == 1:
		return p1
	if id == 2:
		return p2
	return null

func on_particle_effect_spawned(fx: ParticleEffect):
	if ReplayManager.resimulating:
		fx.queue_free()
		return
	effects.append(fx)
	fx_node.add_child(fx)
	fx.connect("tree_exited", self, "_on_fx_exit_tree", [fx])
	
func on_object_spawned(obj: BaseObj):
	objects.append(obj)
	objects_node.add_child(obj)
	obj.has_ceiling = has_ceiling
	obj.ceiling_height = ceiling_height
	obj.obj_name = str(objs_map.size() + 1)
	obj.logic_rng = BetterRng.new()
	obj.logic_rng_static = BetterRng.new()
	var seed_ = hash(match_data.seed + (objs_map.size() + 1))
	obj.logic_rng.seed = seed_
	obj.logic_rng_seed = seed_
	obj.logic_rng_static.seed = match_data.seed
	obj.logic_rng_static_seed = match_data.seed
	objs_map[obj.obj_name if obj.obj_name else obj.name] = obj
	obj.objs_map = objs_map
	obj.connect("tree_exited", self, "_on_obj_exit_tree", [obj])
	obj.connect("hitbox_refreshed", self, "on_hitbox_refreshed")
	obj.connect("global_hitlag", self, "on_global_hitlag")
	obj.gravity_enabled = gravity_enabled
	obj.set_gravity_modifier(global_gravity_modifier)
	obj.fighter_owner = get_player(obj.id)
	obj.update_data()
	for particle in obj.particles.get_children():
		effects.append(particle)
	connect_signals(obj)

func _on_fx_exit_tree(fx):
	effects.erase(fx)

func _on_obj_exit_tree(obj):
	objects.erase(obj)

func on_hitbox_refreshed(hitbox_name):
	p1.parried_hitboxes.erase(hitbox_name)
	p2.parried_hitboxes.erase(hitbox_name)
	pass

func on_clash():
	super_freeze_ticks = 5
	parry_freeze = true
	pass

func on_parry():
	super_freeze_ticks = 10 
	parry_freeze = true

func on_block():
	super_freeze_ticks = 7 
	parry_freeze = true

func on_global_hitlag(amount):
	if is_ghost:
		return
	super_freeze_ticks = amount
	parry_freeze = true
	hit_freeze = true

func forfeit(id):
	if forfeit:
		return
	forfeit = true
	get_player(id).forfeit()
	get_player((id % 2) + 1).on_action_selected("Continue", null, null)
	emit_signal("forfeit_started", id)
	quitter_focus = true
	forfeit_player = get_player(id)
	quitter_focus_ticks = QUITTER_FOCUS_TICKS

func start_game(singleplayer: bool, match_data: Dictionary):
	self.match_data = match_data
	
	if match_data.has("spectating"):
		spectating = match_data.spectating
		if is_ghost:
			spectating = false
	if Global.name_paths.has(match_data.selected_characters[1]["name"]):
		p1 = load(Global.name_paths[match_data.selected_characters[1]["name"]]).instance()
	else:
		return false
	if Global.name_paths.has(match_data.selected_characters[2]["name"]):
		p2 = load(Global.name_paths[match_data.selected_characters[2]["name"]]).instance()
	else:
		return false
	
	p1.connect("parried", self, "on_parry")
	p2.connect("parried", self, "on_parry")
	p1.connect("clashed", self, "on_clash")
	p2.connect("clashed", self, "on_clash")
#	p1.connect("blocked", self, "on_block")
#	p2.connect("blocked", self, "on_block")
	p1.connect("predicted", self, "on_prediction", [p1])
	p2.connect("predicted", self, "on_prediction", [p2])
	stage_width = Utils.int_clamp(match_data.stage_width, 100, 50000)
	if match_data.has("game_length"):
		time = match_data["game_length"]
	if match_data.has("frame_by_frame"):
		frame_by_frame = match_data.frame_by_frame
	if match_data.has("char_distance"):
		char_distance = match_data["char_distance"]
	if match_data.has("clashing_enabled"):
		clashing_enabled = match_data["clashing_enabled"]
	if match_data.has("asymmetrical_clashing"):
		asymmetrical_clashing = match_data["asymmetrical_clashing"]
	if match_data.has("global_gravity_modifier"):
		global_gravity_modifier = match_data["global_gravity_modifier"]
	if match_data.has("has_ceiling"):
		has_ceiling = match_data["has_ceiling"]
	if match_data.has("ceiling_height"):
		ceiling_height = match_data["ceiling_height"]
	if match_data.has("prediction_enabled"):
		prediction_enabled = match_data["prediction_enabled"]
	p1.has_ceiling = has_ceiling
	p2.has_ceiling = has_ceiling
	p1.ceiling_height = ceiling_height
	p2.ceiling_height = ceiling_height

#	if !is_ghost:
#		print("seed: ", match_data.seed)

	p1.name = "P1"
	p2.name = "P2"
	p1.logic_rng = BetterRng.new()
	p2.logic_rng = BetterRng.new()
	p1.logic_rng_static = BetterRng.new()
	p2.logic_rng_static = BetterRng.new()
	p1.logic_rng.seed = hash(match_data.seed)
	p1.logic_rng_seed = hash(match_data.seed)
	p2.logic_rng.seed = hash(match_data.seed + 1)
	p2.logic_rng_seed = hash(match_data.seed + 1)
	p1.logic_rng_static.seed =  hash(match_data.seed)
	p1.logic_rng_static_seed =  hash(match_data.seed)
	p2.logic_rng_static.seed =  hash(match_data.seed + 1)
	p2.logic_rng_static_seed =  hash(match_data.seed + 1)

	p2.id = 2
	p1.is_ghost = is_ghost
	p2.is_ghost = is_ghost
	p1.set_gravity_modifier(global_gravity_modifier)
	p2.set_gravity_modifier(global_gravity_modifier)
	if !is_ghost:
		Global.current_game = self
	for value in match_data:
		for player in [p1, p2]:
			if player.get(value) != null:
				player.set(value, match_data[value])

	$Players.add_child(p1)
	$Players.add_child(p2)
	p1.set_color(Color("aca2ff"))
	p2.set_color(Color("ff7a81"))
	p1.init()
	p2.init()

	if match_data.has("selected_styles"):
		var style1 = match_data.selected_styles[1]
		var style2 = match_data.selected_styles[2]
#		if Custom.can_use_style(1, style1):
		if is_ghost or Custom.can_use_style(1, style1):
			p1.apply_style(style1)
		
#		if Custom.can_use_style(2, style1):
		if is_ghost or Custom.can_use_style(2, style1):
			p2.apply_style(style2)

	if match_data.has("gravity_enabled"):
		gravity_enabled = match_data.gravity_enabled
		p1.gravity_enabled = match_data.gravity_enabled
		p2.gravity_enabled = match_data.gravity_enabled
	
	
	
	p1.connect("undo", self, "set", ["undoing", true])
	p2.connect("undo", self, "set", ["undoing", true])
	p1.connect("super_started", self, "_on_super_started", [p1])
	p2.connect("super_started", self, "_on_super_started", [p2])
	p1.connect("global_hitlag", self, "on_global_hitlag")
	p2.connect("global_hitlag", self, "on_global_hitlag")
	connect_signals(p1)
	connect_signals(p2)
	objs_map = {
		"P1": p1,
		"P2": p2,
	}
	p1.objs_map = objs_map
	p2.objs_map = objs_map
	snapping_camera = true
	self.singleplayer = singleplayer
	if singleplayer:
		if match_data["p2_dummy"]:
			p2.dummy = true
		pass
	elif !is_ghost:
		Network.game = self
	if !singleplayer:
		started_multiplayer = true
		if Network.multiplayer_active:
			p1_username = Network.pid_to_username(1)
			p2_username = Network.pid_to_username(2)

			my_id = Network.player_id
	current_tick = -1
	if !is_ghost:
		if ReplayManager.playback:
			get_max_replay_tick()
		elif !match_data.has("replay"):
			ReplayManager.init()
		else:
			get_max_replay_tick()
			if ReplayManager.frames[1].size() > 0 or ReplayManager.frames[2].size() > 0:
				ReplayManager.playback = true

	var height = 0
	if match_data.has("char_height"):
		height = -match_data.char_height

	p1.set_pos(-char_distance, height)
	p2.set_pos(char_distance, height)

	
	p1.stage_width = stage_width
	p2.stage_width = stage_width
	if stage_width >= 320:
		camera.limit_left = -stage_width - CAMERA_PADDING
		camera.limit_right = stage_width + CAMERA_PADDING
	
#	p1.set_pos(0, 0)
#	p2.set_pos(0, -100)
	p1.opponent = p2
	p2.opponent = p1
	p2.set_facing(-1)
	p1.update_data()
	p2.update_data()
	p1_data = p1.data
	p2_data = p2.data
	apply_hitboxes([p1,p2])
	if !ReplayManager.resimulating:
		show_state()
	if ReplayManager.playback and !ReplayManager.resimulating and !is_ghost:
		yield(get_tree().create_timer(0.5 if !ReplayManager.replaying_ingame else 0.25), "timeout")
	game_started = true
	if !is_ghost:
		if SteamLobby.is_fighting():
			SteamLobby.on_match_started()

	if match_data.has("starting_meter"):
		var meter_amount = p1.fixed.round(p1.fixed.mul(str(Fighter.MAX_SUPER_METER), match_data.starting_meter))
		p1.gain_super_meter(meter_amount)
		p2.gain_super_meter(meter_amount)

func on_prediction(ticks=7, player=null):
	_on_super_started(ticks, player)
	prediction_effect = true
	pass

func update_data():
	p1.update_data()
	p2.update_data()
	p1_data = p1.data
	p2_data = p2.data

func get_max_replay_tick():
#	if spectating:
#		max_replay_tick = spectate_tick
#		if max_replay_tick >= current_tick:
#			ReplayManager.playback = true
#		return
	max_replay_tick = 0
	for tick in ReplayManager.frames[1].keys():
		if tick > max_replay_tick:
			max_replay_tick = tick
	for tick in ReplayManager.frames[2].keys():
		if tick > max_replay_tick:
			max_replay_tick = tick
	return max_replay_tick

func clean_objects():
	var invalid_objects = []
	for object in objects:
		if !is_instance_valid(object):
			invalid_objects.append(object)
	for object in invalid_objects:
		objects.erase(object)

func initialize_objects():
	for object in objects:
		if !object.initialized:
			object.init()

func process_fx():
	for fx in effects:
		if is_instance_valid(fx):
			fx.tick()

func tick():
	if is_ghost and not prediction_enabled:
		return 
	if quitter_focus and quitter_focus_ticks > 0:
		if (QUITTER_FOCUS_TICKS - quitter_focus_ticks) % 10 == 0:
			if forfeit_player:
				forfeit_player.toggle_quit_graphic()
		quitter_focus_ticks -= 1
		return 
	else :
		if forfeit_player:
			forfeit_player.toggle_quit_graphic(false)
		quitter_focus = false
	frame_passed = true
	if not singleplayer:
		if not is_ghost:
			Network.reset_action_inputs()

	clean_objects()
	for object in objects:
		if object.disabled:
			continue
		if not object.initialized:
			object.init()
		
		object.tick()
		var pos = object.get_pos()
		if pos.x < - stage_width:
			object.set_pos( - stage_width, pos.y)
		elif pos.x > stage_width:
			object.set_pos(stage_width, pos.y)
		if has_ceiling and pos.y <= - ceiling_height:
			object.set_y( - ceiling_height)
			object.on_hit_ceiling()

	process_fx()
	current_tick += 1
	
	p1.current_tick = current_tick
	p2.current_tick = current_tick


	p1.lowest_tick = - 1
	p2.lowest_tick = - 1
	var players = resolve_port_priority()
	
	players[0].tick_before()
	players[1].tick_before()
	players[0].update_advantage()
	players[1].update_advantage()
	players[0].tick()
	players[1].tick()

	resolve_same_x_coordinate()
	initialize_objects()
	p1_data = p1.data
	p2_data = p2.data
	resolve_collisions(players[0], players[1])
	apply_hitboxes(players)
	p1_data = p1.data
	p2_data = p2.data

	if (p1.state_interruptable or p1.dummy_interruptable) and not p1.busy_interrupt:
		p2.reset_combo()
		
	if (p2.state_interruptable or p2.dummy_interruptable) and not p2.busy_interrupt:
		p1.reset_combo()

	
	if is_ghost:
		if not ghost_hidden:
			if not visible and current_tick >= 0:
				show()
		return 

	if not game_finished:
		if ReplayManager.playback:
			if not ReplayManager.resimulating:
				is_in_replay = true
				if current_tick > max_replay_tick and not (ReplayManager.frames.has("finished") and ReplayManager.frames.finished):
					ReplayManager.set_deferred("playback", false)
			else :
				if current_tick > (ReplayManager.resim_tick if ReplayManager.resim_tick >= 0 else max_replay_tick - 2):
					if not Network.multiplayer_active:
						ReplayManager.playback = false
					ReplayManager.resimulating = false
					camera.reset_shake()
	else :
		ReplayManager.frames.finished = true
	if should_game_end():
		if started_multiplayer:
			if not ReplayManager.playback:
				Network.autosave_match_replay(match_data, p1_username, p2_username)
		end_game()

var priorities = [
	funcref(self,"state_priority"),
	funcref(self,"comboing"),
	funcref(self,"attacks"),
	funcref(self,"lower_sadness"),
	funcref(self,"forward_movement"),
	funcref(self,"lower_health")
]

func resolve_port_priority(id=false):
	var priority = 0
	var p1_state = p1.current_state()
	var p2_state = p2.current_state()
	for p in priorities:
		priority = p.call_func(p1_state,p2_state)
		if(priority>0):
			break
	priority = max(1,priority)
	return ([p1,p2] if priority==1 else [p2,p1]) if !id else id

func state_priority(p1_state, p2_state):
	if p1_state.tick_priority < p2_state.tick_priority:
		return 1
	if p2_state.tick_priority < p1_state.tick_priority:
		return 2
	return 0

func comboing(p1_state,p2_state):
	if(p1_state.is_hurt_state):
		return 2
	if(p2_state.is_hurt_state):
		return 1
	return 0

func attacks(p1_state,p2_state):
	var p1_hitboxes = []
	var p2_hitboxes = []
	for c in p1_state.get_children():
		if(c is Hitbox):
			p1_hitboxes.append(c)
	for c in p2_state.get_children():
		if(c is Hitbox):
			p2_hitboxes.append(c)
	if(p1_hitboxes.size()==0 and p2_hitboxes.size()==0):
		return 0
	if(p1_hitboxes.size()==0):
		return 2
	if(p2_hitboxes.size()==0):
		return 1
	var p1_start_tick = 999
	var p2_start_tick = 999
	var p1_damage = 0
	var p2_damage = 0
	for h in p1_hitboxes:
		if(h.start_tick<p1_start_tick):
			p1_start_tick = h.start_tick
			p1_damage = h.damage
	for h in p2_hitboxes:
		if(h.start_tick<p2_start_tick):
			p2_start_tick = h.start_tick
			p2_damage = h.damage
	if(p1_start_tick!=p2_start_tick):
		return 1 if p1_start_tick>p2_start_tick else 2
	if(p1_damage!=p2_damage):
		return 1 if p1_damage>p2_damage else 2
	return 0

func lower_sadness(_1,_2):
	if(abs(p1.penalty-p2.penalty)<10):
		return 0
	return 1 if p1.penalty<p2.penalty else 2

func forward_movement(p1_state,p2_state):
	if(p1_state.beats_backdash and !p2_state.beats_backdash):
		return 1
	elif(p1_state.beats_backdash):
		pass
	elif(p2_state.beats_backdash):
		return 2
	return 0

func lower_health(_1,_2):
	var p1_hp = p1.hp/p1.MAX_HEALTH
	var p2_hp = p2.hp/p2.MAX_HEALTH
	if(p1_hp==p2_hp):
		return 0
	return 1 if p1_hp<p2_hp else 2

func int_abs(n: int):
	if n < 0:
		n *= -1
	return n

func int_clamp(n: int, min_: int, max_: int):
	if n > min_ and n < max_:
		return n
	if n <= min_:
		return min_
	if n >= max_:
		return max_

func should_game_end():
	return (current_tick > time or p1.hp <= 0 or p2.hp <= 0)

func resolve_same_x_coordinate():
	# prevent both players occupying the same x coordinate
	var p1_pos = p1.get_pos()
	var p2_pos = p2.get_pos()
	if p1_pos.x == p2_pos.x:
		var player_to_move = p1 if current_tick % 2 == 0 else p2
		var direction_to_move = 1 if current_tick % 2 == 0 else -1
		var x = p1_pos.x
		if x < 0:
			direction_to_move = 1
			if p1.get_facing_int() == -1:
				player_to_move = p1
			elif p2.get_facing_int() == -1:
				player_to_move = p2
		elif x > 0:
			direction_to_move = -1
			if p1.get_facing_int() == 1:
				player_to_move = p1
			elif p2.get_facing_int() == 1:
				player_to_move = p2
		player_to_move.set_x(player_to_move.get_pos().x + direction_to_move)
		player_to_move.update_data()

func resolve_collisions(p1, p2, step=0):
	p1.update_collision_boxes()
	p2.update_collision_boxes()
	var x_pos = p1.data.object_data.position_x
	var opp_x_pos = p2.data.object_data.position_x
	var p1_right_edge = (x_pos + p1.collision_box.width + p1.collision_box.x)
	var p1_left_edge = (x_pos - p1.collision_box.width + p1.collision_box.x)
	var p2_right_edge = (opp_x_pos + p2.collision_box.width + p2.collision_box.x)
	var p2_left_edge = (opp_x_pos - p2.collision_box.width + p2.collision_box.x)
	var edge_distance
	if x_pos < opp_x_pos:
		edge_distance = int_abs(p2_right_edge - p1_left_edge)
	else:
		edge_distance = int_abs(p1_right_edge - p2_left_edge)

	if p1.is_colliding_with_opponent() and p2.is_colliding_with_opponent() and p1.collision_box.overlaps(p2.collision_box):
		var push_p1_left = (p1.get_facing_int() == 1)
		if p1.reverse_state:
			push_p1_left = !push_p1_left
		var push_p2_left = (p1.get_facing_int() == -1)
		if p2.reverse_state:
			push_p2_left = !push_p2_left
		if push_p1_left:
			var edge = p1_right_edge
			var opp_edge = p2_left_edge
			if opp_edge < edge:
				var overlap = int_abs(opp_edge - edge)
				p1.set_x(x_pos - overlap / 2)
				p2.set_x(opp_x_pos + (overlap / 2))
			
		elif push_p2_left:
			var edge = p1_left_edge
			var opp_edge = p2_right_edge
			if opp_edge > edge:
				var overlap = int_abs(opp_edge - edge)
				p1.set_x(x_pos + overlap / 2)
				p2.set_x(opp_x_pos - (overlap / 2))

	if edge_distance > max_char_distance:
		var midpoint = (x_pos + opp_x_pos) / 2
		var left = int_clamp(midpoint - max_char_distance / 2, -stage_width, stage_width)
		var right = int_clamp(midpoint + max_char_distance / 2, -stage_width, stage_width)
		p1.set_x(int_clamp(x_pos, left + (p1.collision_box.width + p1.collision_box.x), right + (-p1.collision_box.width + p1.collision_box.x)))
		p2.set_x(int_clamp(opp_x_pos, left + (p2.collision_box.width + p2.collision_box.x), right + (-p2.collision_box.width + p2.collision_box.x)))
		$Camera2D.reset_smoothing()

	var p1_y_pos = p1.data.object_data.position_y
	var p2_y_pos = p2.data.object_data.position_y
	
	if has_ceiling:
		if p1_y_pos - p1.collision_box.height * 2 < -ceiling_height:
			p1.set_y(-ceiling_height + p1.collision_box.height * 2)
			var vel = p1.get_vel()
			p1.set_vel(vel.x, "0")
		
		if p2_y_pos - p2.collision_box.height * 2 < -ceiling_height:
			p2.set_y(-ceiling_height + p2.collision_box.height * 2)
			var vel = p2.get_vel()
			p2.set_vel(vel.x, "0")
			
	if step < 5:
		if !p1.clipping_wall and x_pos - p1.collision_box.width < -stage_width:
			p1.set_x(-stage_width + p1.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(p1, p2, step+1)
			
		elif !p1.clipping_wall and x_pos + p1.collision_box.width > stage_width:
			p1.set_x(stage_width - p1.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(p1, p2, step+1)
			
		if !p2.clipping_wall and opp_x_pos - p2.collision_box.width < -stage_width:
			p2.set_x(-stage_width + p2.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(p1, p2, step+1)
			
		elif !p2.clipping_wall and opp_x_pos + p2.collision_box.width > stage_width:
			p2.set_x(stage_width - p2.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(p1, p2, step+1)
		
		if p1.is_colliding_with_opponent() and p2.is_colliding_with_opponent() and p1.collision_box.overlaps(p2.collision_box):
			p1.update_data()
			p2.update_data()
			return resolve_collisions(p1, p2, step+1)

func apply_hitboxes(players):
	var px1 = players[0]
	var px2 = players[1]

	var p1_hitboxes = px1.get_active_hitboxes()
	var p2_hitboxes = px2.get_active_hitboxes()

	var p1_pos = px1.get_pos()
	var p2_pos = px2.get_pos()
	
	for hitbox in p1_hitboxes:
		hitbox.update_position(p1_pos.x, p1_pos.y)
	for hitbox in p2_hitboxes:
		hitbox.update_position(p2_pos.x, p2_pos.y)

	var p2_hit_by = get_colliding_hitbox(p1_hitboxes, px2.hurtbox) if not px2.invulnerable else null
	var p1_hit_by = get_colliding_hitbox(p2_hitboxes, px1.hurtbox) if not px1.invulnerable else null
	var p1_hit = false
	var p2_hit = false
	var p1_throwing = false
	var p2_throwing = false

	if p1_hit_by:
		if not (p1_hit_by is ThrowBox):
			p1_hit = true
		else:
			p2_throwing = true

	if p2_hit_by:
		if not (p2_hit_by is ThrowBox):
			p2_hit = true
		else:
			p1_throwing = true

	var clash_position = Vector2()
	var clashed = false
	if clashing_enabled:
		for p1_hitbox in p1_hitboxes:
			if p1_hitbox is ThrowBox:
				continue
			if not p1_hitbox.can_clash:
				continue
			var p2_hitbox = get_colliding_hitbox(p2_hitboxes, p1_hitbox)
			if p2_hitbox:
				if p2_hitbox is ThrowBox:
					continue
				if not p2_hitbox.can_clash:
					continue
				var valid_clash = false
				
				

				if asymmetrical_clashing:
					if p1_hit and not p2_hit:
						if p1_hitbox.damage - p2_hitbox.damage < CLASH_DAMAGE_DIFF:
							valid_clash = true

					if p2_hit and not p1_hit:
						if p2_hitbox.damage - p1_hitbox.damage < CLASH_DAMAGE_DIFF:
							valid_clash = true

				if ( not p1_hit and not p2_hit) or (p1_hit and p2_hit):
					if Utils.int_abs(p2_hitbox.damage - p1_hitbox.damage) < CLASH_DAMAGE_DIFF:
						valid_clash = true
					elif p1_hitbox.damage > p2_hitbox.damage:
						p1_hit = false
						clash_position = p2_hitbox.get_center_float()
						_spawn_particle_effect(preload("res://fx/ClashEffect.tscn"), clash_position)
					elif p1_hitbox.damage < p2_hitbox.damage:
						clash_position = p1_hitbox.get_center_float()
						_spawn_particle_effect(preload("res://fx/ClashEffect.tscn"), clash_position)
						p2_hit = false
				
				if valid_clash:
					clashed = true
					clash_position = p2_hitbox.get_overlap_center_float(p1_hitbox)
					
					break

	if clashed:
		px1.clash()
		px2.clash()
		px1.add_penalty(-25)
		px2.add_penalty(-25)
		_spawn_particle_effect(preload("res://fx/ClashEffect.tscn"), clash_position)
	else:
		if p1_hit:
				if !(p1_throwing and !p1_hit_by.beats_grab):
					p1_hit_by.hit(px1)
				else:
					p1_hit = false
		if p2_hit:
				if !(p2_throwing and !p2_hit_by.beats_grab):
					p2_hit_by.hit(px2)
				else:
					p2_hit = false

	var players_hittable = true
	
	if not p2_hit and not p1_hit:
		if p2_throwing and p1_throwing and px1.current_state().throw_techable and px2.current_state().throw_techable:
				px1.state_machine.queue_state("ThrowTech")
				px2.state_machine.queue_state("ThrowTech")
				players_hittable = false
				
		elif p2_throwing and p1_throwing and not px1.current_state().throw_techable and not px2.current_state().throw_techable:
			players_hittable = false

		elif p1_throwing:
			if px1.current_state().throw_techable and px2.current_state().throw_techable:
				px1.state_machine.queue_state("ThrowTech")
				px2.state_machine.queue_state("ThrowTech")
				players_hittable = false

			var can_hit = true
			if px2.is_grounded() and not p2_hit_by.hits_vs_grounded:
				can_hit = false
			if not px2.is_grounded() and not p2_hit_by.hits_vs_aerial:
				can_hit = false
			if !players_hittable:
				can_hit = false
#			if px2.is_bracing() and px2.current_state().counter_type == CounterAttack.CounterType.Grab:
#				can_hit = false
#				px1.state_machine.queue_state("ThrowTech")
#				px2.state_machine.queue_state("ThrowTech")
#				return
			if can_hit:
				p2_hit_by.hit(px2)
				if p2_hit_by.throw_state:
					px1.state_machine.queue_state(p2_hit_by.throw_state)
				players_hittable = false

		elif p2_throwing:
			if px1.current_state().throw_techable and px2.current_state().throw_techable:
				px1.state_machine.queue_state("ThrowTech")
				px2.state_machine.queue_state("ThrowTech")
				players_hittable = false

			var can_hit = true
			if px1.is_grounded() and not p1_hit_by.hits_vs_grounded:
				can_hit = false
			if not px1.is_grounded() and not p1_hit_by.hits_vs_aerial:
				can_hit = false
			if !players_hittable:
				can_hit = false
#			if px1.is_bracing() and px1.current_state().counter_type == CounterAttack.CounterType.Grab:
#				can_hit = false
#				px1.state_machine.queue_state("ThrowTech")
#				px2.state_machine.queue_state("ThrowTech")
#				return
			if can_hit:
				p1_hit_by.hit(px1)
				if p1_hit_by.throw_state:
					px2.state_machine.queue_state(p1_hit_by.throw_state)
				players_hittable = false

	var objects_to_hit = []
	var objects_hit_each_other = false
	var player_hit_object = false
	var players_to_hit = []
	var objects_hit_player = false
	
	for object in objects:
		if object.disabled:
			continue
		
		# ty wuffie
		var o_hitboxes = object.get_active_hitboxes()

		var o_pos = object.get_pos()

		for hitbox in o_hitboxes:
			hitbox.update_position(o_pos.x, o_pos.y)

		if players_hittable:
			for p in [px1, px2]:
				var p_hit_by
				if p == p1:
					if object.id == 1 and not object.damages_own_team:
						continue
				if p == p2:
					if object.id == 2 and not object.damages_own_team:
						continue
					
				var can_be_hit_by_melee = object.get("can_be_hit_by_melee")
			
				if p:
					var obj_hit_by = get_colliding_hitbox(p.get_active_hitboxes(), object.hurtbox)
					if obj_hit_by and (can_be_hit_by_melee or obj_hit_by.hitbox_type == Hitbox.HitboxType.Detect):
						player_hit_object = true
						objects_to_hit.append([obj_hit_by, object])

					if p.projectile_invulnerable and object.get("immunity_susceptible"):
						continue

					var hitboxes = object.get_active_hitboxes()
					p_hit_by = get_colliding_hitbox(hitboxes, p.hurtbox)
					if p_hit_by:
						players_to_hit.append([p_hit_by, p])
						objects_hit_player = true

		var opp_objects = []
		var opp_id = (object.id % 2) + 1

		for opp_object in objects:
			if opp_object.disabled:
				continue
			if opp_object.id==opp_id or (object.hit_by_self_projectiles and opp_object!=object):
				opp_objects.append(opp_object)

		if !object.projectile_immune:
			for opp_object in opp_objects:
				var obj_hit_by
				var obj_hitboxes = opp_object.get_active_hitboxes()
				obj_hit_by = get_colliding_hitbox(obj_hitboxes, object.hurtbox)
				if obj_hit_by:
					objects_hit_each_other = true
					objects_to_hit.append([obj_hit_by, object])
		
	if objects_hit_each_other or player_hit_object:
		for pair in objects_to_hit:
			pair[0].hit(pair[1])
	if objects_hit_player:
		for pair in players_to_hit:
			pair[0].hit(pair[1])

func get_colliding_hitbox(hitboxes, hurtbox) -> Hitbox:
	var hit_by = null
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			var host = hurtbox.get_parent()
			if host is ObjectState:
				host = host.host
			var attacker = hitbox.host
			var grounded = (host.is_grounded() if !(hurtbox is Hitbox) else true)
			var otg = (host.is_otg() if !(hurtbox is Hitbox) else false)
			if !hitbox.overlaps(hurtbox):
				var any_collisions = false
				if host and host.current_state():
					for hurtbox_ in host.current_state().get_active_hurtboxes():
						if hitbox.overlaps(hurtbox_):
							any_collisions = true
							break
				if !any_collisions:
					continue
			
			if hitbox is ThrowBox:
				if !host.can_be_thrown():
					if host.is_in_group("Fighter") and host.blockstun_ticks > 0:
						hitbox.save_hit_object(host)
					continue
				if host.is_in_group("Fighter"):
					if host.wakeup_throw_immunity_ticks > 0:
						continue
			if (!hitbox.hits_vs_aerial and !grounded) or (!hitbox.hits_vs_grounded and grounded):
				continue
			if !otg and !hitbox.hits_vs_standing:
				continue
			if otg and not hitbox.hits_otg:
				continue
			if !host.is_in_group("Fighter") and !hitbox.hits_projectiles:
				continue
			if hitbox.already_hit_object(host):
				continue
			if attacker:
				if !attacker.is_grounded():
					if host.aerial_attack_immune:
						continue
				else:
					if host.grounded_attack_immune:
						continue
				if attacker.id == host.id and !hitbox.allowed_to_hit_own_team:
					continue
			hit_by = hitbox

	return hit_by

func is_waiting_on_player():
	if forfeit_player != null:
		return false
	if !game_started:
		return false
	return (p1.state_interruptable or p2.state_interruptable)

func simulate_until_ready():
	while !is_waiting_on_player():
		tick()
	show_state()

func simulate_one_tick():
	tick()

	show_state()

func resimulate():
	while ReplayManager.resimulating:
		tick()
		show_state()
	show_state()
	if Network.multiplayer_active:
		Network.undo_finished()
#		yield(get_tree().create_timer(1.0), "timeout")

func undo(cut=true):
	ReplayManager.undo(cut)
	game_started = false
	start_playback()

func start_playback():
	ReplayManager.replaying_ingame = true
#	ReplayManager.resimulating = true
	emit_signal("playback_requested")

func end_game():
	if game_finished:
		return
	game_end_tick = current_tick
	game_finished = true
	p1.game_over = true
	p2.game_over = true

	if !is_ghost:
		if !ReplayManager.playback and !ReplayManager.replaying_ingame and !is_in_replay:
			if !Network.multiplayer_active and !SteamLobby.SPECTATING:
				SteamHustle.unlock_achievement("ACH_CHESS")
		ReplayManager.play_full = true
	var winner = 0
	if p2.hp > p1.hp:
		winner = 2
	elif p1.hp > p2.hp:
		winner = 1
	
	var loser = 1
	if winner == 1:
		loser = 2
	if get_player(loser).had_sadness:
		if Network.multiplayer_active and winner == Network.player_id:
			SteamHustle.unlock_achievement("ACH_WIN_VS_SADNESS")
	
	emit_signal("game_ended")

	emit_signal("game_won", winner)

func negative_on_hit(player):
	return player.current_state().started_during_combo and !player.opponent.current_state().started_during_combo

func process_tick():
#	super_active = super_freeze_ticks > 0
	if super_freeze_ticks > 0:
		if hit_freeze:
			process_fx()
#		super_freeze_ticks -= 1
#		if super_freeze_ticks == 0:
#			super_active = false
#			p1_super = false
#			p2_super = false
#			parry_freeze = false
		return

	var can_tick = !Global.frame_advance or (advance_frame_input)
	if can_tick:
		advance_frame_input = false
	if !Global.frame_advance:
		if Global.playback_speed_mod > 0:
			can_tick = real_tick % Global.playback_speed_mod == 0
	if (Network.multiplayer_active) and !ghost_tick and !spectating:
		can_tick = network_simulate_ready
	if ReplayManager.resimulating:
		ReplayManager.playback = true
		can_tick = true
#	if Network.player_id == 2:
#		can_tick = can_tick and (real_tick % 8 == 0)

	if !ReplayManager.playback:
		if !is_waiting_on_player():
				if can_tick:
#				if Input.is_action_just_pressed("frame_advance"):
					if !Global.frame_advance:
						snapping_camera = true
					call_deferred("simulate_one_tick")
#					if p1_turn or p2_turn:
#						call_deferred("_on_turn_started")
					p1_turn = false
					p2_turn = false
					if game_paused:
						if Network.multiplayer_active:
							Network.can_open_action_buttons = false
					game_paused = false
		else:
			ReplayManager.frames.finished = false
			game_paused = true
			var someones_turn = false
			if p1.state_interruptable and !p1_turn:
				p2.busy_interrupt = (!p2.state_interruptable and !(p2.current_state().interruptible_on_opponent_turn or p2.feinting or negative_on_hit(p2)))
				if !p2.busy_interrupt:
					p2.current_state().on_interrupt()
				p2.state_interruptable = true
				p1.show_you_label()
				p1_turn = true
#				p1.update_advantage()
#				p2.update_advantage()
				if singleplayer:
					emit_signal("player_actionable")
				elif !is_ghost:
					someones_turn = true
				player_actionable = true

			elif p2.state_interruptable and !p2_turn:
				someones_turn = true
				p1.busy_interrupt = (!p1.state_interruptable and !(p1.current_state().interruptible_on_opponent_turn or p1.feinting or negative_on_hit(p1)))
				if !p1.busy_interrupt:
					p1.current_state().on_interrupt()
				p1.state_interruptable = true
				p2.show_you_label()
				p2_turn = true
#				p1.update_advantage()
#				p2.update_advantage()
				if singleplayer:
					emit_signal("player_actionable")
				elif !is_ghost:
					someones_turn = true
				player_actionable = true

			if someones_turn:
				ReplayManager.replaying_ingame = false
				if Network.multiplayer_active:
					if network_sync_tick != current_tick:
						Network.rpc_("end_turn_simulation", [current_tick, Network.player_id])
						network_sync_tick = current_tick
						network_simulate_ready = false
						Network.sync_unlock_turn()
						Network.on_turn_started()

#						SteamLobby.update_spectator_tick(current_tick)
	else:
		if ReplayManager.resimulating:
			snapping_camera = true
			call_deferred("resimulate")
			yield(get_tree(), "idle_frame")
			game_paused = false
		else:
			if buffer_edit:
				ReplayManager.playback = false
				ReplayManager.cut_replay(current_tick)
				buffer_edit = false
			if can_tick:
				call_deferred("simulate_one_tick")

func _process(delta):
	update()
	super_dim()
	
	if camera.global_position.y > camera.limit_bottom - get_viewport_rect().size.y/2:
		camera.global_position.y = camera.limit_bottom - get_viewport_rect().size.y/2
	if camera.global_position.x > camera.limit_right - get_viewport_rect().size.x/2:
		camera.global_position.x = camera.limit_right - get_viewport_rect().size.x/2
	if camera.global_position.x < camera.limit_left + get_viewport_rect().size.x/2:
		camera.global_position.x = camera.limit_left + get_viewport_rect().size.x/2
	
	if is_instance_valid(ghost_game):
		ghost_game.camera_zoom = camera_zoom
		ghost_game.update_camera_limits()

	if game_started and !is_ghost:
		camera.zoom = Vector2.ONE
		var dist = p1.get_hurtbox_center().y - p2.get_hurtbox_center().y
		if abs(p1.get_hurtbox_center().y - p2.get_hurtbox_center().y) > CAMERA_MAX_Y_DIST:
			var dist_ratio = abs(dist) / float(CAMERA_MAX_Y_DIST)
			camera.zoom = Vector2.ONE * dist_ratio
		camera.zoom *= camera_zoom
	if is_instance_valid(ghost_game):
		ghost_game.camera.zoom = camera.zoom
		ghost_game.camera.position = camera.position
		ghost_game.camera.position = camera.position

	camera_snap_position = camera.position

	if is_ghost and Global.ghost_speed > 2:
		var current_time = Time.get_unix_time_from_system()
		var ghost_delta = current_time - ghost_time
		var fps = 60
		var fixed_delta = 1.0 / fps
		var min_delta = fixed_delta * (1.0 / Global.get_ghost_speed_modifier())
		if ghost_delta >= min_delta:
			ghost_time = current_time
			if ghost_actionable_freeze_ticks > 0:
				pass
			else:
				for i in range(floor(ghost_delta / min_delta)):
					call_deferred("ghost_tick")
		

func _physics_process(_delta):
	if forfeit:
		game_paused = false
		game_finished = true
	camera.tick()
	real_tick += 1
	if !$GhostStartTimer.is_stopped():
		return
	if undoing:
		undo()
		return
	if !game_started:
		return

	if !is_ghost:
		if !game_finished:
			if ReplayManager.playback:
				for i in range(1):
					process_tick()
			else:
				process_tick()
		else:
			call_deferred("simulate_one_tick")
			if current_tick >= game_end_tick + 120:
				start_playback()
	else:
		if ghost_actionable_freeze_ticks > 0:
			ghost_actionable_freeze_ticks -= 1
			if ghost_actionable_freeze_ticks == 0:
				emit_signal("make_afterimage")
		elif Global.ghost_speed <= 2:
			call_deferred("ghost_tick")

	super_active = super_freeze_ticks > 0
	if super_active:
		super_freeze_ticks -= 1
		if super_freeze_ticks == 0:
			super_active = false
			p1_super = false
			p2_super = false
			parry_freeze = false
			prediction_effect = false
			hit_freeze = false


	if !is_waiting_on_player():
		emit_signal("simulation_continue")
		if player_actionable and !is_ghost and Network.multiplayer_active:
			Network.sync_tick()
		player_actionable = false
	
	if !is_ghost:
		if snapping_camera:
			var target = (p1.global_position + p2.global_position) / 2
			if forfeit_player:
				target = forfeit_player.global_position
			if camera.focused_object:
				target = camera.focused_object.get_center_position_float()
			if camera.global_position.distance_squared_to(target) > 10:
				camera.global_position = lerp(camera.global_position, target, 0.28)
	if is_instance_valid(ghost_game):
		ghost_game.camera.global_position = camera.global_position
	#		undo()
	waiting_for_player_prev = is_waiting_on_player()
	
	if !is_ghost and buffer_playback:
		ReplayManager.resimulating = false
		game_finished = false
		emit_signal("simulation_continue")
		start_playback()

	if spectating and !is_ghost and !ReplayManager.play_full:
		for id in [1, 2]:
			for input_tick in ReplayManager.frames[id].keys():
				if current_tick == input_tick - 1:
	#					ReplayManager.playback = true
	#				if game.current_tick == input_tick:
					var input = ReplayManager.frames[id][input_tick]
					get_player(id).on_action_selected(input.action, input.data, input.extra)

func ghost_tick():
#	p1.actionable_label.hide()
#	p2.actionable_label.hide()
	var simulate_frames = 1
	if ghost_speed == 1:
		simulate_frames = 1 if ghost_tick % 4 == 0 else 0
	ghost_tick += 1

#	var ghost_multiplier = 1
#	if ghost_speed == 1:
#		ghost_multiplier = 4

#	ghost_advantage_tick /= ghost_multiplier
	p1.grounded_indicator.hide()
	p2.grounded_indicator.hide()
	for i in range(simulate_frames):
		if ghost_actionable_freeze_ticks == 0:
			ghost_simulated_ticks += 1
			simulate_one_tick()
		if current_tick > GHOST_FRAMES:
			emit_signal("ghost_finished")

		if p1.ghost_blocked_melee_attack > 0 and !p1.block_frame_label.visible:
			p1.block_frame_label.show()
			p1.block_frame_label.text = "Parry %s @ %sf" % [p1.ghost_wrong_block, p1.ghost_blocked_melee_attack]
		
		if p2.ghost_blocked_melee_attack > 0 and !p2.block_frame_label.visible:
			p2.block_frame_label.show()
			p2.block_frame_label.text = "Parry %s @ %sf" % [p2.ghost_wrong_block, p2.ghost_blocked_melee_attack]
	
		var p1_tick = ghost_simulated_ticks+(p1.hitlag_ticks if !ghost_p2_actionable else 0)
		if (p1.state_interruptable or p1.dummy_interruptable or p1.state_hit_cancellable) and not ghost_p1_actionable:
			p1_ghost_ready_tick = p1_tick
#			p1_ghost_ready_tick = ghost_advantage_tick+(p1.hitlag_ticks*ghost_multiplier if !ghost_p2_actionable else 0)
		else:
			p1_ghost_ready_tick = null
		if p1.ghost_got_hit and !p1.hit_frame_label.visible:
			p1.hit_frame_label.show()
			p1.hit_frame_label.text = "Hit @ %sf" % p1.turn_frames
		if(ghost_simulated_ticks==p1_ghost_ready_tick):
#		if(ghost_tick/ghost_multiplier==p1_ghost_ready_tick):
			p1.ghost_ready_tick = p1_ghost_ready_tick
			p1_ghost_ready_tick = null
			ghost_p1_actionable = true
			p1.set_ghost_colors()
			if ghost_freeze:
				ghost_actionable_freeze_ticks = GHOST_ACTIONABLE_FREEZE_TICKS
			else:
				ghost_actionable_freeze_ticks = 1
			if !p1.actionable_label.visible:
				p1.actionable_label.show()
				p1.actionable_label.text = "Ready\nin %sf" % p1.turn_frames
				p1.grounded_indicator.visible = p1.is_grounded() and p1.ghost_was_in_air
#				p2.grounded_indicator.visible = p2.is_grounded()
			emit_signal("ghost_my_turn")
			if p2.current_state().interruptible_on_opponent_turn or p2.feinting or negative_on_hit(p2):
				if !p2.actionable_label.visible:
					p2.actionable_label.show()
					if p2.current_state().anim_length == p2.current_state().current_tick + 1 or p2.current_state().iasa_at == p2.current_state().current_tick:
						p2.actionable_label.text = "Ready\nin %sf" % p2.turn_frames
					else:
						p2.actionable_label.text = "Interrupt\nin %sf" % p2.turn_frames
#					p1.grounded_indicator.visible = p1.is_grounded()
					p2.grounded_indicator.visible = p2.is_grounded() and p2.ghost_was_in_air
				ghost_p2_actionable = true
				
#			else:
#				ghost_actionable_freeze_ticks = 1
		var p2_tick = ghost_simulated_ticks+(p2.hitlag_ticks if !ghost_p1_actionable else 0)
		if (p2.state_interruptable or p2.dummy_interruptable or p2.state_hit_cancellable) and not ghost_p2_actionable:
			p2_ghost_ready_tick = p2_tick
#			p2_ghost_ready_tick = ghost_advantage_tick+(p2.hitlag_ticks*ghost_multiplier if !ghost_p1_actionable else 0)
		else:
			p2_ghost_ready_tick = null
		if p2.ghost_got_hit and !p2.hit_frame_label.visible:
			p2.hit_frame_label.show()
			p2.hit_frame_label.text = "Hit @ %sf" % p2.turn_frames
		if(ghost_simulated_ticks==p2_ghost_ready_tick):
			p2.ghost_ready_tick = p2_ghost_ready_tick
			p2_ghost_ready_tick = null
			ghost_p2_actionable = true
			p2.set_ghost_colors()
			if ghost_freeze:
				ghost_actionable_freeze_ticks = GHOST_ACTIONABLE_FREEZE_TICKS
			else:
				ghost_actionable_freeze_ticks = 1
			if !p2.actionable_label.visible:
				p2.actionable_label.show()
				p2.actionable_label.text = "Ready\nin %sf" % p2.turn_frames
#				p1.grounded_indicator.visible = p1.is_grounded()
				p2.grounded_indicator.visible = p2.is_grounded() and p2.ghost_was_in_air
			emit_signal("ghost_my_turn")
			if p1.current_state().interruptible_on_opponent_turn or p1.feinting or negative_on_hit(p1):
				ghost_p1_actionable = true
				if !p1.actionable_label.visible:
					p1.actionable_label.show()
					if p1.current_state().anim_length == p1.current_state().current_tick + 1 or p1.current_state().iasa_at == p1.current_state().current_tick:
						p1.actionable_label.text = "Ready\nin %sf" % p1.turn_frames
					else:
						p1.actionable_label.text = "Interrupt\nin %sf" % p1.turn_frames
					p1.grounded_indicator.visible = p1.is_grounded() and p1.ghost_was_in_air
#					p2.grounded_indicator.visible = p2.is_grounded()
				
#			else:
#				ghost_actionable_freeze_ticks = 1

func super_dim():
	pass

func update_mouse_world_position():
	Global.mouse_world_position = Global.screen_to_world(get_local_mouse_position())
	pass

func _unhandled_input(event: InputEvent):
	if is_afterimage:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			drag_position = camera.get_local_mouse_position()
			mouse_pressed = true
			raise()
		else:
			mouse_pressed = false
			drag_position = null
	if event is InputEventMouseMotion:
		if drag_position and ((is_waiting_on_player() and !ReplayManager.playback) or Global.frame_advance):
			camera.global_position -= event.relative
			snapping_camera = false
		
	if !is_ghost and singleplayer:
			if event.is_action_pressed("playback"):
				if !game_finished and !ReplayManager.playback:
					if is_waiting_on_player() and current_tick > 0:
						buffer_playback = true
			if event.is_action_pressed("edit_replay"):
				if ReplayManager.playback:
					buffer_edit = true
					ReplayManager.play_full = false
	if !is_ghost:
		if event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					zoom_in()
				if event.button_index == BUTTON_WHEEL_DOWN:
					zoom_out()
	update_mouse_world_position()

func update_camera_limits():
	if camera_zoom == 1.0 and stage_width > 320:
		camera.limit_left = -stage_width - CAMERA_PADDING
		camera.limit_right = stage_width + CAMERA_PADDING
	else:
		camera.limit_left = -10000000
		camera.limit_right = 10000000
	if is_instance_valid(ghost_game):
		ghost_game.update_camera_limits()
		

func zoom_in():
	emit_signal("zoom_changed")
	camera_zoom -= 0.1
	if camera_zoom < 0.2:
		camera_zoom = 0.2
	update_camera_limits()


func zoom_out():
	emit_signal("zoom_changed")
	camera_zoom += 0.1
	if camera_zoom > 3.0:
		camera_zoom = 3.0
	update_camera_limits()

func reset_zoom():
	camera_zoom = 1.0
	emit_signal("zoom_changed")
	update_camera_limits()

func _draw():
	if is_ghost:
		return
	if !snapping_camera and mouse_pressed:
		draw_circle(camera.position, 3, Color.white * 0.5)
	if draw_stage:
		var line_color = Color.white
		var ceiling_draw_height = -100000 if !has_ceiling else -ceiling_height 
		draw_line(Vector2(-stage_width, 0), Vector2(stage_width, 0), line_color, 2.0)
	#	if stage_width < 320 or camera_zoom != 1.0:
		draw_line(Vector2(-stage_width, 0), Vector2(-stage_width, ceiling_draw_height), line_color, 2.0)
		draw_line(Vector2(stage_width, 0), Vector2(stage_width, ceiling_draw_height), line_color, 2.0)
		if has_ceiling:
			draw_line(Vector2(-stage_width, ceiling_draw_height), Vector2(stage_width, ceiling_draw_height), line_color, 2.0)
		var line_dist = 50
		var small_line_dist = 10
		var num_lines = stage_width * 2 / line_dist
		for i in range(num_lines):
			var x = i * (((stage_width * 2)) / float(num_lines)) - stage_width
			draw_line(Vector2(x, 0), Vector2(x, 10), line_color, 2.0)
		num_lines = stage_width * 2 / small_line_dist
#		for i in range(num_lines):
#			var c = line_color
#			c.a = 0.25
#			var x = i * (((stage_width * 2)) / float(num_lines)) - stage_width
#			draw_line(Vector2(x, 0), Vector2(x, 5), c, 2.0)
		draw_line(Vector2(stage_width, 0), Vector2(stage_width, 10), line_color, 2.0)
	
#	draw_circle(to_local(Global.mouse_world_position), 5, Color.white)
#	draw_circle(get_local_mouse_position(), 5, Color.blue)
	custom_draw_func()

func custom_draw_func():
	pass

func show_state():
	p1.position = p1.get_pos_visual()
	p2.position = p2.get_pos_visual()
	p1.update()
	p2.update()
	for object in objects:
		object.position = object.get_pos_visual()
		object.update()
	
