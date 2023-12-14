extends Node

export var button_containers: Array
export var click_sound = true

export var hover_sound: AudioStream
export var select_sound: AudioStream

export var hover_db = -20
export var select_db = -8

var connected_buttons = {}

func _ready():
	yield(get_tree(), "idle_frame")
	setup()

func setup():
	if hover_sound:
		$Hover.stream = hover_sound
	if select_sound:
		$Select.stream = select_sound
	$Hover.volume_db = hover_db
	$Select.volume_db = select_db
	for button_container in button_containers:
		for button in get_node(button_container).get_children():
			if button is BaseButton:
				if connected_buttons.has(button):
					continue
				button.connect("focus_entered", self, "_button_focused")
				button.connect("mouse_entered", self, "_button_focused")
				if click_sound:
					button.connect("pressed", self, "_button_selected")
				connected_buttons[button] = true
	button_containers.clear()

func add_container(container: Node):
	button_containers.append(container.get_path())
	setup()

func _button_focused():
	$Hover.play()

func _button_selected():
	$Select.play()
