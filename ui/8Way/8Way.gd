tool
extends Control

signal data_changed()

export  var consider_facing = true
export var force_neutral_when_invisible = true

var facing = 1 setget set_facing
var pressed_button = null

export var NW = true setget set_NW
export var N = true setget set_N
export var NE = true setget set_NE
export var W = true setget set_W
export var Neutral = true setget set_Neutral
export var E = true setget set_E
export var SW = true setget set_SW
export var S = true setget set_S
export var SE = true setget set_SE

func set_facing(val):
	var old_facing = facing
	facing = val

	if not consider_facing: return
	if old_facing == facing: return

	var old_buttons = {}
	for dir in DIRS:
		old_buttons[dir] = get(dir)
	for dir in DIRS:
		set(reverse_dir(dir), old_buttons[dir])

	if not pressed_button: return
	
	pressed_button.set_pressed_no_signal(false)
	
	var new_pressed_button = get_node("%" + reverse_dir(pressed_button.name))
	new_pressed_button.set_pressed_no_signal(true)
	pressed_button = new_pressed_button

func set_NW(val):
	NW = val
	$"%NW".disabled = not val
	
func set_N(val):
	N = val
	$"%N".disabled = not val
	
func set_NE(val):
	NE = val
	$"%NE".disabled = not val
	
func set_W(val):
	W = val
	$"%W".disabled = not val
	
func set_Neutral(val):
	Neutral = val
	$"%Neutral".disabled = not val
	
func set_E(val):
	E = val
	$"%E".disabled = not val
	
func set_SW(val):
	SW = val
	$"%SW".disabled = not val
	
func set_S(val):
	S = val
	$"%S".disabled = not val
	
func set_SE(val):
	SE = val
	$"%SE".disabled = not val
 
func set_dir(dir, force_absolute = false):
	var updated_dir = dir_to_facing(dir) if (not force_absolute) and consider_facing else dir

	assert(updated_dir in DIRS, "attempt to set 8Way dir to unknown value '" + str(dir) + "'")

	var button = get_node("%" + updated_dir)
	if button == pressed_button:
		return 

	if button.disabled:
		set_sensible_default(updated_dir)
		return

	if pressed_button:
		pressed_button.pressed = false

	button.emit_signal("pressed")

func set_sensible_default(attempted_dir, emit_signal=true):
	var dirs_list = DIRS_LEFT if ('W' in attempted_dir) or (consider_facing and facing == -1 and not 'E' in attempted_dir) else DIRS
	for dir in dirs_list:
		var button = get_node("%" + dir)
		if button.disabled:
			continue

		if pressed_button:
			pressed_button.pressed = false


		if emit_signal:
			button.emit_signal("pressed")
		else:
			 _on_button_pressed_no_signal(button)
		return

	assert(false, "trying to update a completely disabled 8Way")

func set_dir_from_data(data):
	if data.x > 0:
		if   data.y > 0: set_dir("SE", true)
		elif data.y < 0: set_dir("NE", true)
		else:            set_dir("E",  true)
	elif data.x < 0:
		if   data.y > 0: set_dir("SW", true)
		elif data.y < 0: set_dir("NW", true)
		else:            set_dir("W",  true)
	else:
		set_dir("Neutral", true)

func get_dir():
	if pressed_button:
		return dir_to_facing(pressed_button.name) if consider_facing else pressed_button.name

func get_dir_name():
	return pressed_button.name

func get_button(button_name):
	for button in get_buttons():
		if button.name == button_name:
			return button

func get_buttons():
	var buttons = []
	buttons.append_array($"%Top".get_children())
	buttons.append_array($"%Middle".get_children())
	buttons.append_array($"%Bottom".get_children())
	return buttons

func get_value(dir):
	match dir:
		"NW":return get_vec_int( - 1, - 1)
		"N":return get_vec_int(0, - 1)
		"NE":return get_vec_int(1, - 1)
		"W":return get_vec_int( - 1, 0)
		"Neutral":return get_vec_int(0, 0)
		"E":return get_vec_int(1, 0)
		"SW":return get_vec_int( - 1, 1)
		"S":return get_vec_int(0, 1)
		"SE":return get_vec_int(1, 1)

func get_data():
	if not pressed_button: return "Neutral"

	if force_neutral_when_invisible and !pressed_button.is_visible_in_tree():
		return get_value("Neutral")
	# if consider_facing:
	# 	return get_value(dir_to_facing(pressed_button.name))
	# else:
	# 	return get_value(pressed_button.name)
	return get_value(pressed_button.name)

func get_vec_int(x:int, y:int):
	return {
		"x":x, 
		"y":y, 
	}

func try_hide_section(section):
	var hidden = true
	for button in section.get_children():
		if not button.disabled:
			hidden = false
	section.visible = !hidden

func reverse_dir(dir):
	match dir:
		"NW":return "NE"
		"NE":return "NW"
		"W":return "E"
		"E":return "W"
		"SW":return "SE"
		"SE":return "SW"
	return dir

func dir_to_facing(dir):
	if facing > 0:
		return dir
	else:
		return reverse_dir(dir)

func _on_button_pressed(button):
	emit_signal("data_changed")
	_on_button_pressed_no_signal(button)

func _on_button_pressed_no_signal(button):
	button.set_pressed_no_signal(true)
	pressed_button = button

# order of precedence for selection
const DIRS = ["Neutral", "E", "NE", "SE", "N", "S", "W", "NW", "SW"]
const DIRS_LEFT = ["Neutral", "W", "NW", "SW", "N", "S", "E", "NE", "SE"]

func _ready():
	if not Engine.editor_hint:
		for button in get_buttons():
			button.connect("pressed", self, "_on_button_pressed", [button])
		$Label.text = name
	_prepare()

func init():
	pass # so Wizard doesnt kill the game

func _prepare():
	for dir in DIRS:
		var button = get_node("%" + dir_to_facing(dir)) if consider_facing else get_node("%" + dir)
		button.disabled = get(dir) != true
			
		if Engine.editor_hint: continue
		
		if pressed_button == null and not button.disabled:
			button.pressed = true
			_on_button_pressed(button)
	
	$"%Top".show()
	$"%Middle".show()
	$"%Bottom".show()

	try_hide_sections()

func try_hide_sections():
	try_hide_section($"%Top")
	try_hide_section($"%Middle")
	try_hide_section($"%Bottom")
