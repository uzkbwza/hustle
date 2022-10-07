extends Node2D

class_name Game

export(int) var char_distance = 200
export(int) var stage_width = 2000
export(int) var max_char_distance = 640
export(int) var time = 3000

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal player_actionable()
signal playback_requested()
signal game_ended()

var p1_data
var p2_data

var p1_turn = false
var p2_turn = false

onready var p1 = $"%P1"
onready var p2 = $"%P2"
onready var camera = $Camera2D
onready var objects_node = $Objects
onready var fx_node = $Fx

var current_tick = -1
var max_replay_tick = 0
var game_started = false
var undoing = false
var singleplayer = false

var game_end_tick = 0

var game_finished = false

var snapping_camera = false 

var objects = []
var effects = []

var drag_position = null

func get_ticks_left():
	return time - min(current_tick, time)

func _ready():
	p1.connect("undo", self, "set", ["undoing", true])
	p2.connect("undo", self, "set", ["undoing", true])
	connect_signals(p1)
	connect_signals(p2)
	camera.limit_left = -stage_width - 20
	camera.limit_right = stage_width + 20

func connect_signals(object):
	object.connect("object_spawned", self, "on_object_spawned")
	object.connect("particle_effect_spawned", self, "on_particle_effect_spawned")

func get_screen_position(player_id):
	var screen_center = camera.get_camera_screen_center()
	var player_position = get_player(player_id).get_center_position_float()
	var result = player_position - screen_center
	return result

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
	obj.connect("tree_exited", self, "_on_obj_exit_tree", [obj])
	connect_signals(obj)

func _on_fx_exit_tree(fx):
	effects.erase(fx)

func _on_obj_exit_tree(obj):
	objects.erase(obj)

func start_game(singleplayer: bool):
	snapping_camera = true
	self.singleplayer = singleplayer
	game_started = true
	current_tick = -1
	if ReplayManager.playback:
		get_max_replay_tick()
	else:
		ReplayManager.init()
	if singleplayer:
		p2.dummy = true
		pass
	else:
		Network.game = self
	p1.init()
	p2.init()
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

func tick():
	if !singleplayer:
		Network.reset_action_inputs()
	clean_objects()
	for object in objects:
		object.tick()
	for fx in effects:
		fx.tick()
	current_tick += 1
	p1.current_tick = current_tick
	p2.current_tick = current_tick
	p1.tick()
	p2.tick()
	p1_data = p1.data
	p2_data = p2.data
	resolve_collisions()
	apply_hitboxes()
	p1_data = p1.data
	p2_data = p2.data
	if !game_finished:
		if ReplayManager.playback:
			if !ReplayManager.resimulating:
				if current_tick > max_replay_tick:
					ReplayManager.playback = false
			else:
				if current_tick > ReplayManager.resim_tick:
					ReplayManager.playback = false
					ReplayManager.resimulating = false
					camera.reset_shake()
	if should_game_end():
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
	var p1_hitboxes = p1.get_active_hitboxes()
	var p2_hitboxes = p2.get_active_hitboxes()
	var p2_hit_by = get_colliding_hitbox(p1_hitboxes, p2.hurtbox)
	var p1_hit_by = get_colliding_hitbox(p2_hitboxes, p1.hurtbox)
	if p1_hit_by:
		p1_hit_by.hit(p1)
	if p2_hit_by:
		p2_hit_by.hit(p2)

	for object in objects:
		var p
		var p_hit_by
		if object.id == 1:
			p = p2
		elif object.id == 2:
			p = p1

		if p:
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
				obj_hit_by.hit(object)

func get_colliding_hitbox(hitboxes, hurtbox) -> Hitbox:
	var hit_by = null
	for hitbox in hitboxes:
		if hitbox is Hitbox:
			if hitbox.overlaps(hurtbox):
				hit_by = hitbox
	return hit_by

func is_waiting_on_player():
	return p1.state_interruptable or p2.state_interruptable

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
	if ReplayManager.resimulating:
		return
	var last_frame = 0
	var last_id = 1
	for id in ReplayManager.frames.keys():
		for frame in ReplayManager.frames[id].keys():
			if frame > last_frame:
				last_frame = frame
				last_id = id
	var other_id = 1 if last_id == 2 else 2
	ReplayManager.frames[last_id].erase(last_frame)
	ReplayManager.frames[other_id].erase(last_frame)
	ReplayManager.resimulating = true
	ReplayManager.playback = true
	ReplayManager.resim_tick = last_frame - 2
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
	emit_signal("game_ended")

func _process(delta):
	update()


func _physics_process(_delta):
	if undoing:
		undo()
	if !game_started:
		return
	if !game_finished:
		if !ReplayManager.playback:
			if !is_waiting_on_player():
					snapping_camera = true
					call_deferred("simulate_one_tick")
					p1_turn = false
					p2_turn = false
			else:
				if p1.state_interruptable and !p1_turn:
					p2.busy_interrupt = !p2.state_interruptable
					p2.state_interruptable = true
					p1.show_you_label()
					p1_turn = true
					if singleplayer:
						emit_signal("player_actionable")
					else:
						Network.rpc("end_turn_simulation", current_tick, Network.player_id)

				elif p2.state_interruptable and !p2_turn:
					p1.busy_interrupt = !p1.state_interruptable
					p1.state_interruptable = true
					p2.show_you_label()
					p2_turn = true
					if singleplayer:
						emit_signal("player_actionable")
					else:
						Network.rpc("end_turn_simulation", current_tick, Network.player_id)
		else:
			if ReplayManager.resimulating:
				snapping_camera = true
				call_deferred("resimulate")
				yield(get_tree(), "idle_frame")
#				camera.reset_smoothing()
			else:
				call_deferred("simulate_one_tick")
	else:
		call_deferred("simulate_one_tick")
		if current_tick >= game_end_tick + 120:
			start_playback()

	if snapping_camera:
		var target = (p1.global_position + p2.global_position) / 2 - Vector2(0, 50)
		if camera.global_position.distance_squared_to(target) > 10:
			camera.global_position = lerp(camera.global_position, target, 0.28)
	

	if !game_finished and singleplayer and Input.is_action_just_pressed("playback") and !ReplayManager.playback:
		if p1_turn or p2_turn:
			ReplayManager.resimulating = false
			game_finished = false
			start_playback()
#		undo()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			drag_position = camera.get_local_mouse_position()
			raise()
		else:
			drag_position = null
	if event is InputEventMouseMotion and drag_position and is_waiting_on_player():
		camera.global_position -= event.relative
		snapping_camera = false
	if camera.global_position.y > camera.limit_bottom - get_viewport_rect().size.y/2:
		camera.global_position.y = camera.limit_bottom - get_viewport_rect().size.y/2
	if camera.global_position.x > camera.limit_right - get_viewport_rect().size.x/2:
		camera.global_position.x = camera.limit_right - get_viewport_rect().size.x/2
	if camera.global_position.x < camera.limit_left + get_viewport_rect().size.x/2:
		camera.global_position.x = camera.limit_left + get_viewport_rect().size.x/2


func _draw():
	if !snapping_camera:
		draw_circle(camera.position, 3, Color.white * 0.5)
	draw_line(Vector2(-stage_width, 0), Vector2(stage_width, 0), Color.black, 2.0)
	draw_line(Vector2(-stage_width, 0), Vector2(-stage_width, -10000), Color.black, 2.0)
	draw_line(Vector2(stage_width, 0), Vector2(stage_width, -10000), Color.black, 2.0)
	var line_dist = 100
	var num_lines = stage_width * 2 / line_dist
	for i in range(num_lines):
		var x = i * (((stage_width * 2)) / float(num_lines)) - stage_width
		draw_line(Vector2(x, 0), Vector2(x, 1000), Color.black, 2.0)
	draw_line(Vector2(stage_width, 0), Vector2(stage_width, 1000), Color.black, 2.0)

func show_state():
	p1.position = p1.get_pos_visual()
	p2.position = p2.get_pos_visual()
	for object in objects:
		object.position = object.get_pos_visual()
	
