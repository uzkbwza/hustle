extends Control
onready var panel = $"%PlotPanel"

export var normalize_display = true

export var min_length = 0.0
export var always_max = false
export var limit_angle = false
export var limit_range_degrees = 90.0
export var limit_center_degrees = 0.0
export var limit_symmetrical = false

var limit_center setget ,get_limit_center
var limit_range setget ,get_limit_range

func get_limit_center():
	return deg2rad(limit_center_degrees)

func get_limit_range():
	return deg2rad(limit_range_degrees)

var range_ = 100

func _ready():
	$"%Label".text = name
	panel.parent = self

func get_value():
	return panel.get_value()

func get_data():
	return get_value()
