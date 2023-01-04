extends VBoxContainer

signal settings_changed(settings)

var start_color := Color.white
var end_color := Color.white

onready var settings_map = {
	$"%Particle Amount": "amount",
	$"%Particle Lifetime": "lifetime",
	$"%InFront": "in_front",
	$"%Local": "local_coords",
	$"%Shape": "shape",
	$"%Speed Scale": "speed_scale",
	$"%Explosiveness": "explosiveness",
	$"%Lifetime Randomness": "lifetime_randomness",
	$"%Direction": "direction",
	$"%Direction Spread": "spread",
	$"%Gravity X": "gravity_x",
	$"%Gravity Y": "gravity_y",
	$"%Rect Size X": "rect_size_x",
	$"%Rect Size Y": "rect_size_y",
	$"%Initial Velocity": "initial_velocity",
	$"%Initial Velocity Randomness": "initial_velocity_random", 
	$"%Linear Accel": "linear_accel",
	$"%Linear Accel Randomness": "linear_accel_random",
	$"%Radial Accel": "radial_accel",
	$"%Radial Accel Randomness": "radial_accel_random",
	$"%Tangential Accel": "tangential_accel",
	$"%Tangential Accel Randomness": "tangential_accel_random",
	$"%Orbit Velocity": "orbit_velocity",
	$"%Orbit Velocity Randomness": "orbit_velocity_random",
	$"%Explosiveness": "explosiveness",
	$"%Start Scale": "start_scale",
	$"%End Scale": "end_scale",
	$"%Scale Randomness": "scale_amount_random",
	$"%StartColor": "start_color",
	$"%EndColor": "end_color",
	$"%Start Alpha": "start_alpha",
	$"%End Alpha": "end_alpha",
	$"%X Offset": "x_offset",
	$"%Y Offset": "y_offset",
	$"%Angle": "angle",
	$"%Angle Randomness": "angle_random",
}

var nodes_map = {}

var shape_names = []

func load_settings(settings):
	for setting in settings:
		if setting in nodes_map:
			var node = nodes_map[setting]
			var value = settings[setting]
			if value is float and node is SettingsSlider:
				node.set_value(value)
			if value is bool and node is BaseButton:
				node.set_pressed(value)
			if value is Color and node is YomiColorPicker:
				node.set_color(value)
			if (value is int or value is float) and node is SpinBox:
				node.set_value(value)
			if value is Vector2 and node is XYPlot:
				node.set_value_float(value)
	if "shape" in settings:
		var shape = settings["shape"]
		for id in $"%Shape".get_item_count():
			if shape == $"%Shape".get_item_text(id):
				$"%Shape".selected = id
				break
#			yield(get_tree(), "idle_frame")

func _ready():
	var shapes = CustomTrailParticle.get_shapes()
	for shape_name in shapes:
		$"%Shape".add_item(shape_name)
		shape_names.append(shape_name)
	for node in settings_map:
		if node.has_signal("value_changed"):
			node.connect("value_changed", self, "_setting_value_changed")
		if node.has_signal("toggled"):
			node.connect("toggled", self, "_setting_value_changed")
		if node.has_signal("data_changed"):
			node.connect("data_changed", self, "_setting_value_changed")
		if node.has_signal("color_changed"):
			node.connect("color_changed", self, "_setting_value_changed")
		var setting = settings_map[node]
		nodes_map[setting] = node
	pass # Replace with function body.

func _setting_value_changed(_value=null):
	emit_signal("settings_changed", get_settings())

func set_start_color(start_color):
	self.start_color = start_color
	_setting_value_changed()

func set_end_color(end_color):
	self.end_color = end_color
	_setting_value_changed()

func get_settings():
	var map = {
		"start_color": $"%StartColor".current_color,
		"end_color": $"%EndColor".current_color,
		"shape": shape_names[$"%Shape".selected],
	}
#	print("getting all aura settings")
	for settings_node in settings_map:
		var value
		if settings_map[settings_node] in map:
			continue
		if settings_node is SettingsSlider:
			value = settings_node.get_data()
		elif settings_node is XYPlot:
			value = settings_node.get_value_float()
		elif settings_node.get("pressed") != null:
			value = settings_node.pressed
		elif settings_node is SpinBox:
			value = settings_node.value
		if value != null:
			map[settings_map[settings_node]] = value
	return map
