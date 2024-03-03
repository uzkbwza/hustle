extends ObjectState

const GROUND_FIRE_DISTANCE = 64
var last_ground_fire = 0
const MOVE_SPEED = 3
const ACTIVE_TIME = 60
var active_time = ACTIVE_TIME
onready var hitbox = $Hitbox
onready var active_2 = $"../../Sounds/Active2"

func _enter():
	active_time = ACTIVE_TIME + host.aim_ticks * 2
	hitbox.active_ticks = active_time
	active_2.stream.loop = false
#	print(active_time)

func _frame_0():
	host.screen_bump(Vector2(), 20, 0.37)
	if host.creator:
		host.creator.loic_meter = 0
		host.creator.can_loic = false
		host.creator.loic_draining = false
#		print(Utils.int_abs(host.obj_local_center(host.creator).x) <= 20)
		if Utils.int_abs(host.obj_local_center(host.creator).x) <= 30:
			host.creator.add_armor_pip()
	last_ground_fire = host.get_pos().x
	host.line_drawer.z_index = 1000


func _frame_200():
	host.disable()

func _tick():
	if host.creator and host.creator.opponent:
		var target = host.creator if host.self_ else host.creator.opponent
		var dir = host.get_object_dir(target)
		var pos = host.obj_local_center(target)
		var t = fixed.mul(host.t, "0.65")
		host.set_pos(fixed.round(fixed.lerp_string(str(host.get_pos().x), str(host.get_pos().x + pos.x), t)), 0)
	if current_tick > 1 and current_tick < active_time:
		if Utils.int_abs(host.get_pos().x - last_ground_fire) > GROUND_FIRE_DISTANCE:
			host.spawn_object(projectile_scene, 0, 0)
			last_ground_fire = host.get_pos().x
		if current_tick % 15 == 0:
			host.play_sound("Active1")
			host.play_sound("Active2")
		if current_tick % 10 == 0:
			spawn_enter_particle()
#		if !active_2.playing:
			
	else:
		host.stop_sound("Active2")

	if current_tick == 2:
		host.play_sound("Active2")

	if host.creator:
		host.move_directly(host.creator.loic_dir * MOVE_SPEED, 0)

func _on_hit_something(obj, hitbox):
	._on_hit_something(obj, hitbox)
	host.screen_bump(Vector2(), 40, 0.35)
	if obj.is_in_group("Fighter"):
		current_tick = active_time
		terminate_hitboxes()
		host.play_sound("Hit")

func on_got_blocked():
	.on_got_blocked()
	current_tick = active_time
	terminate_hitboxes()
	host.play_sound("Hit")
