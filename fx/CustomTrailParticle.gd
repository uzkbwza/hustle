extends ParticleEffect

class_name CustomTrailParticle

var shape = preload("res://fx/particle_round_4x4.png")
var shape_name = "circle"
var start_color = Color.white
var end_color = Color.white
var start_alpha = 1.0
var end_alpha = 1.0
var start_scale = 1.0
var end_scale = 1.0

var default_gravity_x = 0
var facing = 1
var default_angle = 0

onready var particles = $CPUParticles2D

var custom_set = {
	"shape": "set_shape",
	"start_color": "set_start_color",
	"end_color": "set_end_color",
	"start_scale": "set_start_scale",
	"end_scale": "set_end_scale",
	"in_front": "set_in_front",
	"rect_size_x": "set_rect_size_x",
	"rect_size_y": "set_rect_size_y",
	"gravity_x": "set_gravity_x",
	"gravity_y": "set_gravity_y",
	"start_alpha": "set_start_alpha",
	"end_alpha": "set_end_alpha",
	"x_offset": "set_x_offset",
	"y_offset": "set_y_offset",
	"lifetime": "set_lifetime",
	"angle": "set_angle",
}

static func get_shapes():
	return {
		"circle": preload("res://fx/particle_round_4x4.png"),
		"square": preload("res://fx/particle_square_4x4.png"),
		"triangle": preload("res://fx/TriUp.png"),
		"star": preload("res://fx/star.png"),
		"heart": preload("res://fx/heart.png"),
		"arrow": preload("res://fx/arrow.png"),
		"cross": preload("res://fx/cross.png"),
		"line": preload("res://fx/line.png"),
		"diamond": preload("res://fx/diamond.png"),
		"shine": preload("res://fx/four_point_star.png"),
		"elec": preload("res://fx/elec.png"),
		"hollow circle": preload("res://fx/particle_round_hollow_4x4.png"),
		"hollow square": preload("res://fx/particle_square_hollow_4x4.png"),
		"checkerboard 1": preload("res://fx/checkerboard_1.png"),
		"checkerboard 2": preload("res://fx/checkerboard_2.png"),
	}

static func get_default():
	{
		"in_front": false,
		"shape": "circle",
		"amount": 16,
		"alpha": 1.0,
		"local_coords": false,
		"speed_scale": 2.0,
		"explosiveness": 0.0,
		"lifetime_randomness": 0.5,
		"gravity_x": 0.0,
		"gravity_y": 0.0,
		"rect_size_x": 4.0,
		"rect_size_y": 4.0,
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
		"x_offset": 0.0,
		"y_offset": 0.0,
		"scale_amount_random": 0.0,
		"angle": 0.0,
		"angle_random": 0.0,
	}

static func get_setting_min(setting):
	var minimums = {
		"amount": 1,
		"lifetime": 0.064,
		"speed_scale": 0.0,
		"explosiveness": 0.0,
		"lifetime_randomness": 0.0,
		"gravity_x": -100.0,
		"gravity_y": -100.0,
		"rect_size_x": 0.0,
		"rect_size_y": 0.0,
		"spread": 0.0,
		"initial_velocity": -100.0,
		"initial_velocity_random": 0.0,
		"linear_accel": -100.0,
		"linear_accel_random": 0.0,
		"radial_accel": -100.0,
		"radial_accel_random": 0.0,
		"tangential_accel": -100.0,
		"tangential_accel_random": 0.0,
		"orbit_velocity": -100.0,
		"orbit_velocity_random": 0.0,
		"start_scale": 0.0,
		"end_scale": 0.0,
		"scale_amount_random": 0.0,
		"x_offset": -24.0,
		"y_offset": -24.0,
		"angle": -360.0,
		"angle_random": 0.0,
	}
	return minimums[setting] if minimums.has(setting) else null

static func get_setting_max(setting):
	var maximums = {
		"amount": 32,
		"lifetime": 2.0,
		"speed_scale": 10.0,
		"explosiveness": 1.0,
		"lifetime_randomness": 1.0,
		"gravity_x": 100.0,
		"gravity_y": 100.0,
		"rect_size_x": 32.0,
		"rect_size_y": 32.0,
		"spread": 180.0,
		"initial_velocity": 100.0,
		"initial_velocity_random": 1.0,
		"linear_accel": 100.0,
		"linear_accel_random": 1.0,
		"radial_accel": 100.0,
		"radial_accel_random": 1.0,
		"tangential_accel": 100.0,
		"tangential_accel_random": 1.0,
		"orbit_velocity": 100.0,
		"orbit_velocity_random": 1.0,
		"start_scale": 5.0,
		"end_scale": 5.0,
		"x_offset": 24.0,
		"y_offset": 24.0,
		"scale_amount_random": 1.0,
		"angle": 360.0,
		"angle_random": 1.0,
	}
	return maximums[setting] if maximums.has(setting) else null

func restart():
	$CPUParticles2D.restart()
	set_enabled(false)

func _ready():
	set_enabled(false)

func get_data():
	pass

func set_shape(shape_name):
	var shapes = get_shapes()
	if shape_name in shapes:
		var shape = shapes[shape_name]
		particles.texture = shape
		self.shape_name = shape_name

func set_in_front(on):
	if on:
		show_behind_parent = false
#		particles.z_index = 1
	else:
		show_behind_parent = true
#		particles.z_index = -1

func set_start_color(color):
	start_color = color
	update_color()
	
func set_end_color(color):
	end_color = color
	update_color()

func _physics_process(_delta):
	if !is_instance_valid(Global.current_game):
		if !enabled:
			start_emitting()
			set_enabled(true)
		tick()
	elif Global.current_game:
		if enabled:
			set_enabled(false)

func tick():
	.tick()
	particles.gravity.x = default_gravity_x * facing
	particles.angle = 360 - default_angle if facing == -1 else default_angle

func set_start_alpha(a):
#	particles.self_modulate.a = a
	start_color.a = a
	update_color()

func set_end_alpha(a):
	end_color.a = a
	update_color()

func update_color():
	var gradient = Gradient.new()
	gradient.set_color(0, start_color)
	gradient.set_color(1, end_color)
	particles.color_ramp = gradient

func set_start_scale(sc):
	start_scale = sc
	update_scale()

func set_end_scale(sc):
	end_scale = sc
	update_scale()

func update_scale():
	var curve = Curve.new()
	var max_ = max(start_scale, end_scale)
	var start = start_scale
	var end = end_scale
	if max_ > 0:
		start = start_scale / max_
		end = end_scale / max_
	particles.scale_amount = max_
	curve.add_point(Vector2(0, start))
	curve.add_point(Vector2(1, end))
	particles.scale_amount_curve = curve

func set_rect_size_x(x):
#	print("rect_x: " + str(x))
	particles.set_emission_rect_extents(Vector2(x, particles.get_emission_rect_extents().y))

func set_rect_size_y(y):
	particles.set_emission_rect_extents(Vector2(particles.get_emission_rect_extents().x, y))

func set_gravity_x(x):
	default_gravity_x = x
	particles.gravity.x = x

func set_gravity_y(y):
	particles.gravity.y = y

func set_x_offset(x):
	particles.position.x = x

func set_y_offset(y):
	particles.position.y = y

func set_lifetime(lifetime):
	particles.lifetime = lifetime
	particles.preprocess = lifetime

func set_angle(angle):
	default_angle = angle
	particles.angle = angle

func set_parameter(param, value):
	var max_value = get_setting_max(param)
	var min_value = get_setting_min(param)
	if max_value and value > max_value:
		value = max_value
	if min_value and value < min_value:
		value = min_value
	if !(param in custom_set):
		particles.set(param, value)
	else:
		call(custom_set[param], value)

func load_defaults():
	load_settings(get_default())

func load_settings(settings):
	if settings:
		for setting in settings:
			set_parameter(setting, settings[setting])
