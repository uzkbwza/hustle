extends Node2D

class_name ParticleEffect

const FPS = 60

export var free=true
export var one_shot = true
export var lifetime = 1.0
var tick = 0

onready var tick_timer = $Timer

func _ready():
	for child in get_children():
		if child is Particles2D:
			child.one_shot = one_shot
			child.emitting = true
		if child is CPUParticles2D:
			child.one_shot = one_shot
			child.emitting = true
	set_enabled(false)
	tick_timer.connect("timeout", self, "on_tick_timer_timeout")

func on_tick_timer_timeout():
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



func set_enabled(on):
	set_process_internal(on)
	for child in get_children():
		if child is CPUParticles2D or child is Particles2D:
			child.set_process_internal(on)
