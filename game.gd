extends Node2D

class_name Game

const GHOST_FRAMES = 90
const SUPER_FREEZE_TICKS = 20
const GHOST_ACTIONABLE_FREEZE_TICKS = 10
const CAMERA_MAX_Y_DIST = 210
const QUITTER_FOCUS_TICKS = 60
const CLASH_DAMAGE_DIFF = 40
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

onready var camera = $Camera2D
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

var p1 = null
var p2 = null

var p1_username = null
var p2_username = null
var my_id = 1

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
var ghost_freeze = false
var player_actionable = true
var network_sync_tick = -100
var ceiling_height = 400
var has_ceiling = true

var ghost_actionable_freeze_ticks = 0
var ghost_p1_actionable = false
var ghost_p2_actionable = false
var made_afterimage = false

var spectating = false

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

func _on_super_started(player, ticks=null):
	if is_ghost:
		return
	if ticks == null:
		ticks = 0
		var state = player.current_state()
		if state.get("super_freeze_ticks") != null:
			if state.super_freeze_ticks > super_freeze_ticks:
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
	obj.obj_name = str(objs_map.size() + 1)
	objs_map[obj.obj_name if obj.obj_name else obj.name] = obj
	obj.objs_map = objs_map
	obj.connect("tree_exited", self, "_on_obj_exit_tree", [obj])
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

func on_clash():
	super_freeze_ticks = 5
	parry_freeze = true
	pass

func on_parry():
	super_freeze_ticks = 10 
	parry_freeze = true

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
	p1.name = "P1"
	p2.name = "P2"
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
	apply_hitboxes()
	if !ReplayManager.resimulating:
		show_state()
	if ReplayManager.playback and !ReplayManager.replaying_ingame and !ReplayManager.resimulating and !is_ghost:
		yield(get_tree().create_timer(0.5), "timeout")
	game_started = true
#	if is_afterimage:
#		show_state()

func on_prediction(player):
	_on_super_started(player, 10)
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

func tick():
	if quitter_focus and quitter_focus_ticks > 0:
		if (QUITTER_FOCUS_TICKS - quitter_focus_ticks) % 10 == 0:
			if forfeit_player:
				forfeit_player.toggle_quit_graphic()
		quitter_focus_ticks -= 1
		return
	else:
		if forfeit_player:
			forfeit_player.toggle_quit_graphic(false)
		quitter_focus = false
	frame_passed = true
	if !singleplayer:
		if !is_ghost:
			Network.reset_action_inputs()

	clean_objects()
	for object in objects:
		if object.disabled:
			continue
		if !object.initialized:
			object.init()
		
		object.tick()
		var pos = object.get_pos()
		if pos.x < -stage_width:
			object.set_pos(-stage_width, pos.y)
		elif pos.x > stage_width:
			object.set_pos(stage_width, pos.y)
		if has_ceiling and pos.y < -ceiling_height:
			object.set_y(-ceiling_height)

	for fx in effects:
		if is_instance_valid(fx):
			fx.tick()
	current_tick += 1
	
	p1.current_tick = current_tick
	p2.current_tick = current_tick
#	p1.initiative = (p1.current_state().current_tick > p2.current_state().current_tick) or p1.parried_last_state
#	p2.initiative = (p2.current_state().current_tick > p1.current_state().current_tick) or p2.parried_last_state
	p1.lowest_tick = -1
	p2.lowest_tick = -1
	p1.tick_before()
	p2.tick_before()
	p1.update_advantage()
	p2.update_advantage()
	p1.tick()
	p2.tick()
	
	resolve_same_x_coordinate()
	initialize_objects()
	p1_data = p1.data
	p2_data = p2.data
	resolve_collisions()
	apply_hitboxes()
	p1_data = p1.data
	p2_data = p2.data

	if (p1.state_interruptable or p1.dummy_interruptable) and !p1.busy_interrupt:
		p2.reset_combo()
		
	if (p2.state_interruptable or p2.dummy_interruptable) and !p2.busy_interrupt:
		p1.reset_combo()

	
	if is_ghost:
		if !ghost_hidden:
			if !visible and current_tick >= 0:
				show()
		return

	if !game_finished:
		if ReplayManager.playback:
			if !ReplayManager.resimulating:
				if current_tick > max_replay_tick and !(ReplayManager.frames.has("finished") and ReplayManager.frames.finished):
					ReplayManager.set_deferred("playback", false)
			else:
				if current_tick > (ReplayManager.resim_tick if ReplayManager.resim_tick >= 0 else max_replay_tick - 2):
					if !Network.multiplayer_active:
						ReplayManager.playback = false
					ReplayManager.resimulating = false
					camera.reset_shake()
	else:
		ReplayManager.frames.finished = true
	if should_game_end():
		if started_multiplayer:
			if !ReplayManager.playback:
				Network.autosave_match_replay(match_data, p1_username, p2_username)
		end_game()

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

func resolve_collisions(step=0):
	p1.update_collision_boxes()
	p2.update_collision_boxes()
	var x_pos = p1.data.object_data.position_x
	var opp_x_pos = p2.data.object_data.position_x
	var p1_right_edge = (x_pos + p1.collision_box.width + p1.collision_box.x)
	var p1_left_edge = (x_pos - p1.collision_box.width - p1.collision_box.x)
	var p2_right_edge = (opp_x_pos + p2.collision_box.width + p2.collision_box.x)
	var p2_left_edge = (opp_x_pos - p2.collision_box.width - p2.collision_box.x)
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
			return resolve_collisions(step+1)
			
		elif !p1.clipping_wall and x_pos + p1.collision_box.width > stage_width:
			p1.set_x(stage_width - p1.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
			
		if !p2.clipping_wall and opp_x_pos - p2.collision_box.width < -stage_width:
			p2.set_x(-stage_width + p2.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
			
		elif !p2.clipping_wall and opp_x_pos + p2.collision_box.width > stage_width:
			p2.set_x(stage_width - p2.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
		
		if p1.is_colliding_with_opponent() and p2.is_colliding_with_opponent() and p1.collision_box.overlaps(p2.collision_box):
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)

func apply_hitboxes():
	if !is_ghost:
		pass
	var p1_hitboxes = p1.get_active_hitboxes()
	var p2_hitboxes = p2.get_active_hitboxes()
	var p2_hit_by = get_colliding_hitbox(p1_hitboxes, p2.hurtbox) if !p2.invulnerable else null
	var p1_hit_by = get_colliding_hitbox(p2_hitboxes, p1.hurtbox) if !p1.invulnerable else null
	var p1_hit = false
	var p2_hit = false
	var p1_throwing = false
	var p2_throwing = false

	if p1_hit_by:
		if !(p1_hit_by is ThrowBox):
#			p1_hit_by.hit(p1)
			p1_hit = true
		else:
			p2_throwing = true
			if !p1_hit_by.hits_otg and p1.is_otg():
				p2_throwing = false
			if p1.throw_invulnerable:
				p2_throwing = false
	if p2_hit_by:
		if !(p2_hit_by is ThrowBox):
#			p2_hit_by.hit(p2)
			p2_hit = true
		else:
			p1_throwing = true
			if !p2_hit_by.hits_otg and p2.is_otg():
				p1_throwing = false
			if p2.throw_invulnerable:
				p1_throwing = false
#
#	if p1_hit and p2_hit:
	var clash_position = Vector2()
	var clashed = false
	if clashing_enabled:
		for p1_hitbox in p1_hitboxes:
			if p1_hitbox is ThrowBox:
				continue
			var p2_hitbox = get_colliding_hitbox(p2_hitboxes, p1_hitbox)
			if p2_hitbox:
				if p2_hitbox is ThrowBox:
					continue
				var valid_clash = false
				
#				if !p1_hit and !p2_hit:
#					valid_clash = true
				if asymmetrical_clashing:
					if p1_hit and !p2_hit:
						if p1_hitbox.damage - p2_hitbox.damage < CLASH_DAMAGE_DIFF:
							valid_clash = true

					if p2_hit and !p1_hit:
						if p2_hitbox.damage - p1_hitbox.damage < CLASH_DAMAGE_DIFF:
							valid_clash = true
	#
				if (!p1_hit and !p2_hit) or (p1_hit and p2_hit):
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
		p1.clash()
		p2.clash()
		_spawn_particle_effect(preload("res://fx/ClashEffect.tscn"), clash_position)
	else:
		if p1_hit:
			p1_hit_by.hit(p1)
		if p2_hit:
			p2_hit_by.hit(p2)

	if !p2_hit and !p1_hit:
		if p2_throwing and p1_throwing and p1.current_state().throw_techable and p2.current_state().throw_techable:
				p1.state_machine.queue_state("ThrowTech")
				p2.state_machine.queue_state("ThrowTech")
				
		elif p2_throwing and p1_throwing and !p1.current_state().throw_techable and !p2.current_state().throw_techable:
			return

		elif p1_throwing:
			if p1.current_state().throw_techable and p2.current_state().throw_techable:
				p1.state_machine.queue_state("ThrowTech")
				p2.state_machine.queue_state("ThrowTech")
				return
			var can_hit = true
			if p2.is_grounded() and !p2_hit_by.hits_vs_grounded:
				can_hit = false
			if !p2.is_grounded() and !p2_hit_by.hits_vs_aerial:
				can_hit = false
			if can_hit:
				p2_hit_by.hit(p2)
				if p2_hit_by.throw_state:
					p1.state_machine.queue_state(p2_hit_by.throw_state)
				return

		elif p2_throwing:
			if p1.current_state().throw_techable and p2.current_state().throw_techable:
				p1.state_machine.queue_state("ThrowTech")
				p2.state_machine.queue_state("ThrowTech")
				return
			var can_hit = true
			if p1.is_grounded() and !p1_hit_by.hits_vs_grounded:
				can_hit = false
			if !p1.is_grounded() and !p1_hit_by.hits_vs_aerial:
				can_hit = false
			if can_hit:
				p1_hit_by.hit(p1)
				if p1_hit_by.throw_state:
					p2.state_machine.queue_state(p1_hit_by.throw_state)
				return

	var objects_to_hit = []
	var objects_hit_each_other = false

	for object in objects:
		if object.disabled:
			continue
		for p in [p1, p2]:
			var p_hit_by
			if p == p1:
				if object.id == 1 and !object.damages_own_team:
					continue
			if p == p2:
				if object.id == 2 and !object.damages_own_team:
					continue

			if p:
				if p.projectile_invulnerable and object.get("immunity_susceptible"):
					continue
				var hitboxes = object.get_active_hitboxes()
				p_hit_by = get_colliding_hitbox(hitboxes, p.hurtbox)
				if p_hit_by:
					p_hit_by.hit(p)

			var opp_objects = []
			var opp_id = (object.id % 2) + 1

			for opp_object in objects:
				if opp_object.id == opp_id:
					opp_objects.append(opp_object)

			for opp_object in opp_objects:
				var obj_hit_by
				var obj_hitboxes = opp_object.get_active_hitboxes()
				obj_hit_by = get_colliding_hitbox(obj_hitboxes, object.hurtbox)
				if obj_hit_by:
					objects_hit_each_other = true
					objects_to_hit.append([obj_hit_by, object])
		
	if objects_hit_each_other:
		for pair in objects_to_hit:
			pair[0].hit(pair[1])

func get_colliding_hitbox(hitboxes, hurtbox) -> Hitbox:
	var hit_by = null
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			var grounded = (hurtbox.get_parent().is_grounded() if !(hurtbox is Hitbox) else true)
			if (!hitbox.hits_vs_aerial and !grounded) or (!hitbox.hits_vs_grounded and grounded):
				continue

			if hitbox.overlaps(hurtbox):
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
		ReplayManager.play_full = true
	var winner = 0
	if p2.hp > p1.hp:
		winner = 2
	elif p1.hp > p2.hp:
		winner = 1
	emit_signal("game_ended")
	emit_signal("game_won", winner)

func process_tick():
	
	super_active = super_freeze_ticks > 0
	if super_freeze_ticks > 0:
		super_freeze_ticks -= 1
		if super_freeze_ticks == 0:
			super_active = false
			p1_super = false
			p2_super = false
			parry_freeze = false
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
				p2.busy_interrupt = (!p2.state_interruptable and !(p2.current_state().interruptible_on_opponent_turn or p2.feinting))
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
				p1.busy_interrupt = (!p1.state_interruptable and !(p1.current_state().interruptible_on_opponent_turn or p1.feinting))
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
	camera_snap_position = camera.position

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
		else:
			call_deferred("ghost_tick")

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
	p1.actionable_label.hide()
	p2.actionable_label.hide()
	var simulate_frames = 1
	if ghost_speed == 1:
		simulate_frames = 1 if ghost_tick % 4 == 0 else 0
	ghost_tick += 1

	for i in range(simulate_frames):
		if ghost_actionable_freeze_ticks == 0:
			simulate_one_tick()
		if current_tick > GHOST_FRAMES:
			emit_signal("ghost_finished")
		p1.set_ghost_colors()
		p2.set_ghost_colors()

		if (p1.state_interruptable or p1.dummy_interruptable) and !ghost_p1_actionable:
			ghost_p1_actionable = true
			if ghost_freeze:
				ghost_actionable_freeze_ticks = GHOST_ACTIONABLE_FREEZE_TICKS
				p1.actionable_label.show()
				emit_signal("ghost_my_turn")
				if p2.current_state().interruptible_on_opponent_turn or p2.feinting:
					p2.actionable_label.show()
					ghost_p2_actionable = true
			else:
				ghost_actionable_freeze_ticks = 1

		if (p2.state_interruptable or p2.dummy_interruptable) and !ghost_p2_actionable:
			ghost_p2_actionable = true
			if ghost_freeze:
				ghost_actionable_freeze_ticks = GHOST_ACTIONABLE_FREEZE_TICKS
				p2.actionable_label.show()
				emit_signal("ghost_my_turn")
				if p1.current_state().interruptible_on_opponent_turn or p1.feinting:
					ghost_p1_actionable = true
					p1.actionable_label.show()
			else:
				ghost_actionable_freeze_ticks = 1

func super_dim():
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
	if event is InputEventMouseMotion and drag_position and ((is_waiting_on_player() and !ReplayManager.playback) or Global.frame_advance):
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
	if !is_ghost:
		if event is InputEventMouseButton:
			if event.pressed:
				if event.button_index == BUTTON_WHEEL_UP:
					zoom_in()
				if event.button_index == BUTTON_WHEEL_DOWN:
					zoom_out()

func update_camera_limits():
	if camera_zoom == 1.0:
		camera.limit_left = -stage_width - CAMERA_PADDING
		camera.limit_right = stage_width + CAMERA_PADDING
	else:
		camera.limit_left = -10000000
		camera.limit_right = 10000000

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
	var line_color = Color.white
	var ceiling_draw_height = -100000 if !has_ceiling else -ceiling_height 
	draw_line(Vector2(-stage_width, 0), Vector2(stage_width, 0), line_color, 2.0)
#	if stage_width < 320 or camera_zoom != 1.0:
	draw_line(Vector2(-stage_width, 0), Vector2(-stage_width, ceiling_draw_height), line_color, 2.0)
	draw_line(Vector2(stage_width, 0), Vector2(stage_width, ceiling_draw_height), line_color, 2.0)
	if has_ceiling:
		draw_line(Vector2(-stage_width, ceiling_draw_height), Vector2(stage_width, ceiling_draw_height), line_color, 2.0)
	var line_dist = 50
	var num_lines = stage_width * 2 / line_dist
	for i in range(num_lines):
		var x = i * (((stage_width * 2)) / float(num_lines)) - stage_width
		draw_line(Vector2(x, 0), Vector2(x, 10), line_color, 2.0)
	draw_line(Vector2(stage_width, 0), Vector2(stage_width, 10), line_color, 2.0)

func show_state():
	p1.position = p1.get_pos_visual()
	p2.position = p2.get_pos_visual()
	p1.update()
	p2.update()
	for object in objects:
		object.position = object.get_pos_visual()
		object.update()
	
