extends Control

onready var action_data_container = $"%ActionDataContainer"
onready var action_data_panel_container = $"%ActionDataPanelContainer"

var label_text = ""
var selected_button_text = ""
var active_button = null

var game = null
var player_id = null

func _ready():
	connect("draw", self, "snap_to_boundaries")

func init(name):
	label_text = name
	$"%Label".text = label_text

#func _on_gui_input(event: InputEvent):
#	if event is InputEventMouseButton:
#		if event.pressed:
#			raise()
#	snap_to_boundaries()

func any_buttons_visible():
	for button in $"%ButtonContainer".get_children():
		if button.visible:
			return true
	return false

func _process(_delta):
#	if visible:
#		snap_to_boundaries()
	if action_data_panel_container.visible:
		var screen_pos = game.get_screen_position(player_id)
		var center_pos = get_viewport_rect().size/2 - action_data_panel_container.rect_size/2
		action_data_panel_container.rect_global_position = screen_pos + center_pos
		if active_button and active_button.data_node:
			action_data_panel_container.rect_global_position += active_button.data_node.display_offset
		action_data_panel_container.raise()
		pass

func add_button(button):
	$"%ButtonContainer".add_child(button)
	button.connect("mouse_entered", self, "on_button_mouse_entered", [button])
	button.connect("mouse_exited", self, "on_button_mouse_exited")
#	button.connect("toggled", self, "on_button_pressed", [button])

func refresh():
	for button in $"%ButtonContainer".get_children():
		if button.is_pressed():
			on_button_mouse_entered(button)
			$"%Label".modulate = Color.cyan
			active_button = button
			selected_button_text = button.action_title
			return
	$"%Label".text = label_text
	$"%Label".modulate = Color.darkgray


func on_button_mouse_entered(button):
	$"%Label".text = button.action_title
	if button.action_title == selected_button_text:
		return
	$"%Label".modulate = Color.green

func on_button_mouse_exited():
	refresh()

func show_data_container():
	$"%ActionDataPanelContainer".show()
#	yield(get_tree(), "idle_frame")
#	action_data_container.rect_size.y = min(action_data_container.container.rect_size.y, 80)
#	action_data_container.rect_position = Vector2(0, -action_data_container.rect_position.y - 1)
	
func hide_data_container():
	$"%ActionDataPanelContainer".hide()

func add_data_node(node):
	action_data_container.add_child(node)

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
