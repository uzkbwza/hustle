extends ParticleEffect

class_name CustomTrailParticle

var shape = preload("res://fx/particle_round_4x4.png")
var shape_num
var start_color
var end_color
var start_scale
var end_scale

onready var particles = $CPUParticles2D

var custom_set = {
	"shape": "set_shape",
	"start_color": "set_start_color",
	"end_color": "set_end_color",
	"start_scale": "set_start_scale",
	"end_scale": "set_end_scale",
	"in_front": "set_in_front",
}

static func get_shapes():
	return [
		preload("res://fx/particle_round_4x4.png"),
		preload("res://fx/particle_round_hollow_4x4.png"),
		preload("res://fx/particle_square_4x4.png"),
	]

static func get_default():
	{
		"in_front": false,
		"shape": 0,
		"local_coords": false,
		"speed_scale": 2.0,
		"explosiveness": 0.0,
		"lifetime_randomness": 0.5,
		"gravity": Vector2(0, 0),
		"emission_rect_extents": Vector2(4.0, 4.0),
		"direction": Vector2(0, -1),
		"spread": 0.0,
		"initial_velocity": 16.0,
		"initial_velocity_random": 16.0,
		"linear_accel": 0.0,
		"linear_accel_random": 0.0,
		"radial_accel": 0.0,
		"radial_accel_random": 0.0,
		"tangential_accel": 0.0,
		"tangential_accel_random": 0.0,
		"orbit_velocity": 0.0,
		"orbit_velocity_random": 0.0,
		"start_color": Color.white,
		"end_color": Color.white,
		"start_scale": 1.0,
		"end_scale": 1.0,
		"scale_amount_random": 0.0
	}

func get_data():
	pass

func set_shape(shape_num):
	var shape = get_shapes()[shape_num]
	particles.texture = shape
	shape_num = shape_num

func set_in_front(on):
	if on:
		particles.z_index = 1
	else:
		particles.z_index = -1

func set_start_color(color):
	start_color = color
	
func set_end_color(color):
	end_color = color

func set_start_scale(sc):
	start_scale = sc

func set_end_scale(sc):
	end_scale = sc

func set_parameter(param, value):
	if !(param in custom_set):
		particles.set(param, value)
	else:
		call(custom_set[param], value)

func load_defaults():
	load_data(get_default())

func load_data(data):
	pass

func _ready():
	load_defaults()
