extends Control

class_name Window

var drag_position

onready var window_contents = $VBoxContainer/Contents

export var static_ = false

func _ready():
	hint_tooltip = name
	connect("gui_input", self, "_on_gui_input")
	connect("draw", self, "snap_to_boundaries")

func _on_gui_input(event: InputEvent):
	if static_:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			drag_position = get_global_mouse_position() - rect_global_position
			raise()
		else:
			drag_position = null
	if event is InputEventMouseMotion and drag_position:
		rect_global_position = get_global_mouse_position() - drag_position
	snap_to_boundaries()

func snap_to_boundaries():
	var viewport_size = get_viewport_rect().size
	if rect_global_position.x < 0:
		rect_global_position.x = 0
	if rect_global_position.y < 0:
		rect_global_position.y = 0
	if rect_global_position.x + rect_size.x > viewport_size.x:
		rect_global_position.x = viewport_size.x - rect_size.x
	if rect_global_position.y + rect_size.y > viewport_size.y:
		rect_global_position.y = viewport_size.y - rect_size.y
