extends Node2D

class_name Game

const GHOST_FRAMES = 90
const SUPER_FREEZE_TICKS = 20
const GHOST_ACTIONABLE_FREEZE_TICKS = 10

const CAMERA_MAX_Y_DIST = 210

export(int) var char_distance = 200
export(int) var stage_width = 2000
export(int) var max_char_distance = 640
export(int) var time = 3000

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal player_actionable()
signal simulation_continue()
signal playback_requested()
signal game_ended()
signal game_won(winner)
signal ghost_finished()
signal make_afterimage()
signal ghost_my_turn()

var p1_data
var p2_data

var p1_turn = false
var p2_turn = false

onready var camera = $Camera2D
onready var objects_node = $Objects
onready var fx_node = $Fx

var current_tick = -1
var max_replay_tick = 0
var game_started = false
var undoing = false
var singleplayer = false
var parry_freeze = true

var game_paused = false

var buffer_playback = false
var buffer_edit = false

var game_end_tick = 0

var frame_passed = false

var game_finished = false

var ghost_cleaned = true

var advance_frame_input = false

var frame_by_frame = false

var is_ghost = false
var is_afterimage = false
var ghost_hidden = false
var ghost_game
var ghost_speed = 3
var ghost_tick = 0

var match_data = null
var simulated_once = false

var p1 = null
var p2 = null

var snapping_camera = false 
var waiting_for_player_prev = false

var camera_snap_position = Vector2()

var objects: Array = []
var objs_map = {
	
}
var effects: Array = []

var drag_position = null

var real_tick = 0
var super_freeze_ticks = 0
var super_active = false
var p1_super = false
var p2_super = false
var ghost_freeze = false
var player_actionable = true
var network_sync_tick = -100

var ghost_actionable_freeze_ticks = 0
var ghost_p1_actionable = false
var ghost_p2_actionable = false
var made_afterimage = false
#var has_ghost_frozen_yet = false

func get_ticks_left():
	return time - Utils.int_min(current_tick, time)

func _ready():
	camera.limit_left = -stage_width - 20
	camera.limit_right = stage_width + 20
	if is_ghost:
		hide()
		for object in objects_node.get_children():
			object.free()
		for fx in fx_node.get_children():
			fx.free()
		$GhostStartTimer.start()
	else:
		emit_signal("simulation_continue")

func connect_signals(object):
	object.connect("object_spawned", self, "on_object_spawned")
	object.connect("particle_effect_spawned", self, "on_particle_effect_spawned")

func copy_to(game: Game):
	if !game_started:
		return
	p1.copy_to(game.p1)
	p2.copy_to(game.p2)
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
				game.objs_map[game.objs_map.size() + 1] = null

func _on_super_started(player):
	if is_ghost:
		return
	var state = player.current_state()
	if state.get("super_freeze_ticks") != null:
		if state.super_freeze_ticks > super_freeze_ticks:
			super_freeze_ticks = state.super_freeze_ticks
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

func get_player(id):
	if id == 1:
		return p1
	if id == 2:
		return p2

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
	for particle in obj.particles.get_children():
		effects.append(particle)
	connect_signals(obj)

func _on_fx_exit_tree(fx):
	effects.erase(fx)

func _on_obj_exit_tree(obj):
	objects.erase(obj)

func on_parry():
	super_freeze_ticks = 10 
	parry_freeze = true

func start_game(singleplayer: bool, match_data: Dictionary):
	self.match_data = match_data
	p1 = load(Global.name_paths[match_data.selected_characters[1]["name"]]).instance()
	p2 = load(Global.name_paths[match_data.selected_characters[2]["name"]]).instance()
	p1.connect("parried", self, "on_parry")
	p2.connect("parried", self, "on_parry")
	stage_width = Utils.int_clamp(match_data.stage_width, 100, 50000)
	if match_data.has("game_length"):
		time = match_data["game_length"]
	if match_data.has("frame_by_frame"):
		frame_by_frame = match_data.frame_by_frame
	p1.name = "P1"
	p2.name = "P2"
	p2.id = 2
	p1.is_ghost = is_ghost
	p2.is_ghost = is_ghost
	if !is_ghost:
		Global.current_game = self
	for value in match_data:
		for player in [p1, p2]:
			if player.get(value) != null:
				player.set(value, match_data[value])

#	if match_data.has("infinite_resources"):
#		p1.infinite_resources = match_data["infinite_resources"]
#		p2.infinite_resources = match_data["infinite_resources"]
#
#	if match_data.has("turbo_mode"):
#		p1.turbo_mode = match_data["turbo_mode"]
#		p2.turbo_mode = match_data["turbo_mode"]
#
#	if match_data.has("one_hit_ko"):
#		p1.one_hit_ko = match_data["one_hit_ko"]
#		p2.one_hit_ko = match_data["one_hit_ko"]
	$Players.add_child(p1)
	$Players.add_child(p2)
	p1.set_color(Color("aca2ff"))
	p2.set_color(Color("ff7a81"))
	p1.init()
	p2.init()
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
	current_tick = -1
	if !is_ghost:
		if ReplayManager.playback:
			get_max_replay_tick()
		elif !match_data.has("replay"):
			ReplayManager.init()
		else:
			get_max_replay_tick()
			ReplayManager.playback = true
	if singleplayer:
		if match_data["p2_dummy"]:
			p2.dummy = true
		pass
	elif !is_ghost:
		Network.game = self
	p1.set_pos(-char_distance, 0)
	p2.set_pos(char_distance, 0)
	
	p1.stage_width = stage_width
	p2.stage_width = stage_width
#	p1.set_pos(0, 0)
#	p2.set_pos(0, -100)
	p1.opponent = p2
	p2.opponent = p1
	p2.set_facing(-1)
	p1.update_data()
	p2.update_data()
	p1_data = p1.data
	p2_data = p2.data
	if !ReplayManager.resimulating:
		show_state()
	if ReplayManager.playback and !ReplayManager.resimulating:
		yield(get_tree().create_timer(0.33), "timeout")
	game_started = true
#	if is_afterimage:
#		show_state()

func update_data():
	p1.update_data()
	p2.update_data()
	p1_data = p1.data
	p2_data = p2.data

func get_max_replay_tick():
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

	for fx in effects:
		fx.tick()
	current_tick += 1
	p1.current_tick = current_tick
	p2.current_tick = current_tick
	p1.tick()
	p2.tick()
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
				if current_tick > max_replay_tick:
					ReplayManager.set_deferred("playback", false)
			else:
				if current_tick > ReplayManager.resim_tick:
					ReplayManager.playback = false
					ReplayManager.resimulating = false
					camera.reset_shake()
	if should_game_end():
		if Network.multiplayer_active:
			if !ReplayManager.playback:
				Network.autosave_match_replay(match_data)
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
	return current_tick > time or p1.hp <= 0 or p2.hp <= 0

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
		if x_pos < opp_x_pos or p1.get_facing() == "Right":
			var edge = p1_right_edge
			var opp_edge = p2_left_edge
			if opp_edge < edge:
				var overlap = int_abs(opp_edge - edge)
				p1.set_x(x_pos - overlap / 2)
				p2.set_x(opp_x_pos + (overlap / 2))
			
		elif x_pos > opp_x_pos or p1.get_facing() == "Left":
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

	if step < 5:
		if x_pos - p1.collision_box.width < -stage_width:
			p1.set_x(-stage_width + p1.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
			
		elif x_pos + p1.collision_box.width > stage_width:
			p1.set_x(stage_width - p1.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
			
		if opp_x_pos - p2.collision_box.width < -stage_width:
			p2.set_x(-stage_width + p2.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
			
		elif opp_x_pos + p2.collision_box.width > stage_width:
			p2.set_x(stage_width - p2.collision_box.width)
			p1.update_data()
			p2.update_data()
			return resolve_collisions(step+1)
		
		if p1.collision_box.overlaps(p2.collision_box):
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
			p1_hit_by.hit(p1)
			p1_hit = true
		else:
			p2_throwing = true
	if p2_hit_by:
		if !(p2_hit_by is ThrowBox):
			p2_hit_by.hit(p2)
			p2_hit = true
		else:
			p1_throwing = true
	
	if !p2_hit and !p1_hit:
		if p2_throwing and p1_throwing:
			p1.state_machine.queue_state("ThrowTech")
			p2.state_machine.queue_state("ThrowTech")

		elif p1_throwing:
			if p1.current_state().throw_techable and p2.current_state().throw_techable:
				p1.state_machine.queue_state("ThrowTech")
				p2.state_machine.queue_state("ThrowTech")
				return
			var can_hit = true
			if p2.is_grounded() and !p2_hit_by.hits_grounded:
				can_hit = false
			if !p2.is_grounded() and !p2_hit_by.hits_aerial:
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
			if p1.is_grounded() and !p1_hit_by.hits_grounded:
				can_hit = false
			if !p1.is_grounded() and !p1_hit_by.hits_aerial:
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
			if hitbox.overlaps(hurtbox):
				hit_by = hitbox
	return hit_by

func is_waiting_on_player():
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

func undo():
	ReplayManager.undo()
	game_started = false
	start_playback()

func start_playback():
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
	if Network.multiplayer_active:
		can_tick = true
	
	if !ReplayManager.playback:
		if !is_waiting_on_player():
				if can_tick:
#				if Input.is_action_just_pressed("frame_advance"):
					snapping_camera = true
					call_deferred("simulate_one_tick")
					p1_turn = false
					p2_turn = false
					game_paused = false
					
		else:
			game_paused = true
			var someones_turn = false
			if p1.state_interruptable and !p1_turn:
				p2.busy_interrupt = (!p2.state_interruptable and !p2.current_state().interruptible_on_opponent_turn)
				p2.state_interruptable = true
				p1.show_you_label()
				p1_turn = true
				if singleplayer:
					emit_signal("player_actionable")
				elif !is_ghost:
					someones_turn = true
				player_actionable = true
			elif p2.state_interruptable and !p2_turn:
				someones_turn = true
				p1.busy_interrupt = (!p1.state_interruptable and !p1.current_state().interruptible_on_opponent_turn)
				p1.state_interruptable = true
				p2.show_you_label()
				p2_turn = true
				if singleplayer:
					emit_signal("player_actionable")
				elif !is_ghost:
					someones_turn = true
				player_actionable = true

			if someones_turn:
				if network_sync_tick != current_tick:
#					yield(get_tree().create_timer(2.0), "timeout")
					Network.rpc_("end_turn_simulation", [current_tick, Network.player_id])
					network_sync_tick = current_tick
	else:
		if ReplayManager.resimulating:
			snapping_camera = true
			call_deferred("resimulate")
			yield(get_tree(), "idle_frame")
			game_paused = false
#				camera.reset_smoothing()
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
	
	if game_started and !is_ghost:
		camera.zoom = Vector2.ONE
		var dist = p1.get_hurtbox_center().y - p2.get_hurtbox_center().y
		if abs(p1.get_hurtbox_center().y - p2.get_hurtbox_center().y) > CAMERA_MAX_Y_DIST:
			var dist_ratio = abs(dist) / float(CAMERA_MAX_Y_DIST)
			camera.zoom = Vector2.ONE * dist_ratio
	if is_instance_valid(ghost_game):
		ghost_game.camera.zoom = camera.zoom
	camera_snap_position = camera.position
	

func _physics_process(_delta):
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
		player_actionable = false
	
	if !is_ghost:
		if snapping_camera:
			var target = (p1.global_position + p2.global_position) / 2
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


func ghost_tick():
	p1.actionable_label.hide()
	p2.actionable_label.hide()
	var simulate_frames = 1
	if ghost_speed == 1:
		simulate_frames = 1 if ghost_tick % 4 == 0 else 0
#	if ghost_speed == 3:
#		simulate_frames = 4
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
				if p2.current_state().interruptible_on_opponent_turn:
					p2.actionable_label.show()
					ghost_p2_actionable = true
			else:
				ghost_actionable_freeze_ticks = 1
#				emit_signal("ghost_my_turn")
#					if !made_afterimage:
#						made_afterimage = true
		if (p2.state_interruptable or p2.dummy_interruptable) and !ghost_p2_actionable:
			ghost_p2_actionable = true
			if ghost_freeze:
				ghost_actionable_freeze_ticks = GHOST_ACTIONABLE_FREEZE_TICKS
				p2.actionable_label.show()
				emit_signal("ghost_my_turn")
				if p1.current_state().interruptible_on_opponent_turn:
					ghost_p1_actionable = true
					p1.actionable_label.show()
			else:
				ghost_actionable_freeze_ticks = 1
#				emit_signal("ghost_my_turn")
#					if !made_afterimage:
#						made_afterimage = true

func super_dim():
#	var arr = objects + effects
	pass
func _unhandled_input(event: InputEvent):
	if is_afterimage:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			drag_position = camera.get_local_mouse_position()
			raise()
		else:
			drag_position = null
	if event is InputEventMouseMotion and drag_position and is_waiting_on_player() and !ReplayManager.playback:
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

func _draw():
	if is_ghost:
		return
	if !snapping_camera:
		draw_circle(camera.position, 3, Color.white * 0.5)
	var line_color = Color.white
	draw_line(Vector2(-stage_width, 0), Vector2(stage_width, 0), line_color, 2.0)
	draw_line(Vector2(-stage_width, 0), Vector2(-stage_width, -10000), line_color, 2.0)
	draw_line(Vector2(stage_width, 0), Vector2(stage_width, -10000), line_color, 2.0)
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
	
