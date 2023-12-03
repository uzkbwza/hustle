extends Node2D

class_name ParticleEffect

const FPS = 60

export var free=true
export var one_shot = true
export var lifetime = 1.0
export var start_enabled = true

var emitting = true
var enabled = true
var tick = 0

var sounds_played = {
	
}

onready var tick_timer = $Timer

func _ready():
	emitting = start_enabled
	for child in get_children():
		if child is Particles2D:
			child.one_shot = one_shot
			child.emitting = start_enabled
		elif child is CPUParticles2D:
			child.one_shot = one_shot
			child.emitting = start_enabled
		elif child is AnimatedSprite:
			child.playing = false
			child.frame = 0
		elif child is AudioStreamPlayer2D:
			sounds_played[child] = false
#		if child is Node2D:
#			child.set_material(get_material())
	if !ReplayManager.playback:
		set_enabled(false)
		tick_timer.connect("timeout", self, "on_tick_timer_timeout")
	call_deferred("update_dir")

func update_dir():
	var timer = Timer.new()
	timer.wait_time = 0.016
	add_child(timer)
	timer.one_shot = true
	timer.pause_mode = Node.PAUSE_MODE_PROCESS
	timer.start()
	timer.connect("timeout", self, "on_update_timer_timeout")

func on_update_timer_timeout():
	for child in get_children():
		if child is CPUParticles2D:
			if scale.x < 0 or Utils.ang2vec(rotation).x < 0:
				child.gravity.x = -child.gravity.x

func set_speed_scale(speed):
	for child in get_children():
		if child.get("speed_scale") != null:
			child.speed_scale = speed

func on_tick_timer_timeout():
	if enabled:
		set_enabled(false)

func start_emitting():
	show()
	emitting = true
	set_enabled(true)
	for child in get_children():
		if child is Particles2D:
			child.emitting = true
			child.restart()
		if child is CPUParticles2D:
			child.emitting = true
			child.restart()
func start():
	start_emitting()
	for child in get_children():
		if child is AnimatedSprite:
			child.playing = false
			child.frame = 0


func stop_emitting():
#	emitting = false
	for child in get_children():
		if child is Particles2D:
			child.emitting = false
		if child is CPUParticles2D:
			child.emitting = false

func tick():
	set_enabled(true)
	tick_timer.start()
	tick += 1
	for child in get_children():
		if child is AnimatedSprite:
			if child.frames.get_frame_count(child.animation) > tick:
				child.frame = tick
			else:
				child.queue_free()
		if child is AudioStreamPlayer2D:
			if !child.playing and !sounds_played[child]:
				child.play()
				sounds_played[child] = true
	if free:
		if tick / 60.0 >= lifetime:
			queue_free()

func get_enabled():
	return enabled

func set_enabled(on):
	enabled = on
	set_process_internal(on)
	for child in get_children():
		if child is Particles2D:
			child.set_process_internal(on)
		elif child is CPUParticles2D:
			child.set_process_internal(on)
