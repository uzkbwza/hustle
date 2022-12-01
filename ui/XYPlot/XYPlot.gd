extends Control
onready var panel = $"%PlotPanel"

class_name XYPlot

signal data_changed()

export var normalize_display = true

export var min_length = 0.0
export var always_max = false
export var limit_angle = false
export var limit_range_degrees = 90.0
export var limit_center_degrees = 0.0
export var limit_symmetrical = false
export var snap = true
export var snap_radius = 0.0

export var default_value = Vector2(1, 0)


var limit_center setget ,get_limit_center
var limit_range setget ,get_limit_range

var facing = 1

func get_default_value():
	var d = default_value
	d.x *= facing
	return d.normalized()

func get_limit_center():
	return (Utils.ang2vec(deg2rad(limit_center_degrees)) * Vector2(facing, 1)).angle()

func get_limit_range():
	return deg2rad(limit_range_degrees)

var range_ = 100

func _ready():
	$"%Label".text = name
	panel.connect("data_changed", self, "emit_signal", ["data_changed"])
	panel.parent = self

func get_value():
	return panel.get_value()

func get_value_float():
	return panel.get_value_float()

func get_data():
	return get_value()

func init():
	panel.init()
