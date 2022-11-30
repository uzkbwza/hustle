extends Control

var buttons = []
var moving_sprite_start

var character_color = Color.white
var outline_color = Color.black

var free_colors = []

var selected_hitspark = "bash"

var hitspark_scene = null

func get_custom_data():
	return {
		"character_color": character_color.to_html(false) if character_color != null else null,
		"use_outline": $"%ShowOutline".pressed,
		"outline_color": outline_color if $"%ShowOutline".pressed else null,
		"hitspark": "bash" if selected_hitspark == null else selected_hitspark,
	}


func _ready():
	for name in Global.name_paths:
		var button = preload("res://ui/CSS/CharacterButton.tscn").instance()
		button.character_scene = load(Global.name_paths[name])
		$"%CharacterButtonContainer".add_child(button)
		buttons.append(button)
		button.connect("pressed", self, "_on_character_button_pressed", [button])
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
#		var character = button.character_scene.instance()
		button.text = name
	buttons[0].pressed = true
	moving_sprite_start = $"%MovingSprite".position
	$"%Character".connect("color_changed", self, "_on_character_color_changed")
	$"%Outline".connect("color_changed", self, "_on_outline_color_changed")
	$"%ShowOutline".connect("toggled", self, "_on_show_outline_toggled")
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	for i in range(Custom.simple_colors.size()):
		var simple_color_button = preload("res://ui/CustomizationScreen/SimpleColorButton.tscn").instance()
		var color = Custom.simple_colors[i]
		var outline = Custom.simple_outlines[i]
		simple_color_button.init(color, outline)
		$"%SimpleColorButtonContainer".add_child(simple_color_button)
		simple_color_button.connect("pressed", self, "_on_character_color_changed", [Color(color)])
		simple_color_button.connect("pressed", self, "_on_outline_color_changed", [Color(outline)])
	$"%ResetColorButton".connect("pressed", self, "_on_reset_color_pressed")
#	select_hitspark("default")
	for hitspark in Custom.hitsparks:
		var button = Button.new()
		button.text = hitspark
		button.connect("pressed", self, "select_hitspark", [hitspark])
		button.rect_min_size = Vector2(50, 20)
		$"%HitsparkButtonContainer".add_child(button)

func select_hitspark(hitspark_name):
	selected_hitspark = hitspark_name
	spawn_hitspark()

func spawn_hitspark():
	if Custom.hitsparks.has(selected_hitspark):
		if is_instance_valid(hitspark_scene):
			hitspark_scene.queue_free()
		hitspark_scene = load(Custom.hitsparks[selected_hitspark]).instance()

		$"%HitsparkDisplay".add_child(hitspark_scene)

func _physics_process(delta):
	if !is_instance_valid(hitspark_scene):
		spawn_hitspark()
	else:
		hitspark_scene.tick()

func _on_back_button_pressed():
	get_tree().reload_current_scene()

func _on_reset_color_pressed():
	character_color = null
	$"%StaticSprite".get_material().set_shader_param("color", Color.white)
	_on_show_outline_toggled(false)

func _on_character_color_changed(color):
	$"%StaticSprite".get_material().set_shader_param("color", color)
#	$"%MovingSprite".get_material().set_shader_param("color", color)
	character_color = color

func _on_outline_color_changed(color):
	$"%ShowOutline".set_pressed_no_signal(true)
	$"%StaticSprite".get_material().set_shader_param("outline_color", color)
	$"%StaticSprite".get_material().set_shader_param("use_outline", true)
#	$"%MovingSprite".get_material().set_shader_param("color", color)
	outline_color = color

func _on_show_outline_toggled(on):
	$"%StaticSprite".get_material().set_shader_param("use_outline", on)
	$"%ShowOutline".set_pressed_no_signal(on)

func _on_character_button_pressed(button):
	for button in buttons:
		button.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)
	var character = button.character_scene.instance()
	add_child(character)
	var character_texture = character.sprite.frames.get_frame("Wait", 0)
	$"%StaticSprite".texture = character_texture
	$"%MovingSprite".texture = character_texture
	character.free()

func _process(delta):
	if visible:
		$"%MovingSprite".position = moving_sprite_start + Vector2(Utils.wave(-50, 50, 2.0), 0)
