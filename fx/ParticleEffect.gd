extends Node2D

class_name ParticleEffect

const FPS = 60


export var free=true
export var one_shot = true
export var lifetime = 1.0
export var start_enabled = true
var enabled = true
var tick = 0

onready var tick_timer = $Timer

func _ready():
	for child in get_children():
		if child is Particles2D:
			child.one_shot = one_shot
			child.emitting = start_enabled
		if child is CPUParticles2D:
			child.one_shot = one_shot
			child.emitting = start_enabled
		if child is AnimatedSprite:
			child.playing = false
			child.frame = 0
	if !ReplayManager.playback:
		set_enabled(false)
		tick_timer.connect("timeout", self, "on_tick_timer_timeout")

func on_tick_timer_timeout():
	if enabled:
		set_enabled(false)

func stop_emitting():
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
	if free:
		if tick / 60.0 >= lifetime:
			queue_free()

func get_enabled():
	return enabled

func set_enabled(on):
	enabled = on
	set_process_internal(on)
	for child in get_children():
		if child is CPUParticles2D or child is Particles2D:
			child.set_process_internal(on)
