extends Control

var buttons = []
var moving_sprite_start

var character_color = Color.white
var outline_color = Color.black
var extra_color_1 = null
var extra_color_2 = null

var free_colors = []
var custom_particles = []

var selected_hitspark = "bash"

var workshop_preview_image: Image = null

var hitspark_scene = null

func get_style_data():
	return {
		"style_name": Utils.filter_filename($"%StyleName".text.strip_edges()) if $"%StyleName".text.strip_edges() else "untitled" + str(int(Time.get_unix_time_from_system())),
		"character_color": character_color,
		"extra_color_1": extra_color_1,
		"extra_color_2": extra_color_2,
		"use_outline": $"%ShowOutline".pressed,
		"outline_color": outline_color if $"%ShowOutline".pressed else null,
		"hitspark": "bash" if selected_hitspark == null else selected_hitspark,
		"show_aura": $"%ShowAura".pressed,
		"aura_settings": $"%TrailSettings".get_settings() if $"%ShowAura".pressed else null,
		"ivy_effect": false,
	}

func init():
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
	$"%Extra1".connect("color_changed", self, "_on_extra_color_1_changed")
	$"%Extra2".connect("color_changed", self, "_on_extra_color_2_changed")
	$"%Outline".connect("color_changed", self, "_on_outline_color_changed")
	$"%ShowOutline".connect("toggled", self, "_on_show_outline_toggled")
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	for i in range(Custom.simple_colors.size()):
		var simple_color_button = preload("res://ui/CustomizationScreen/SimpleColorButton.tscn").instance()
		var color = Custom.simple_colors[i]
		var outline = Custom.simple_outlines[i]
		simple_color_button.init(color, outline)
		$"%SimpleColorButtonContainer".add_child(simple_color_button)
		simple_color_button.connect("pressed", self, "_on_character_color_changed", [color])
		simple_color_button.connect("pressed", self, "_on_outline_color_changed", [outline])
	$"%ResetColorButton".connect("pressed", self, "_on_reset_color_pressed")
#	select_hitspark("default")
	for hitspark in Custom.hitsparks:
		var button = Button.new()
		button.text = hitspark
		button.connect("pressed", self, "select_hitspark", [hitspark])
		button.rect_min_size = Vector2(50, 20)
		$"%HitsparkButtonContainer".add_child(button)
	$"%TrailSettings".connect("settings_changed", self, "_on_trail_settings_changed")
	$"%ShowAura".connect("pressed", $"%TrailSettings", "_setting_value_changed")
#	$"%ShowAura".connect("toggled", $"%TrailSettings", "_show_aura_toggled")
	$"%SaveButton".connect("pressed", self, "save_style")
	$"%LoadStyleButton".connect("style_selected", self, "load_style")
	if !SteamHustle.WORKSHOP_ENABLED:
		$"%WorkshopButton".disabled = true
	_on_character_button_pressed(buttons[0])
	_on_reset_color_pressed()
	update_warning()

func show():
	$"%LoadStyleButton".update_styles()
	update_warning()
	.show()
	_on_reset_color_pressed()
	
func save_style(clear_text = false):
	var data = get_style_data()
	Custom.save_style(data)
	SteamHustle.unlock_achievement("ACH_STYLISH")
	if data.character_color == Color("0b0c0f"):
		if !data.use_outline or data.outline_color == Color("0b0c0f"):
			SteamHustle.unlock_achievement("ACH_SNEAKY")
	$"%LoadStyleButton".update_styles()
	if clear_text:
		$"%StyleName".clear()
	$"%SavedLabel".text = "saved as " + data.style_name + ".style"
	$"%SavedLabel".show()

func update_warning():
#	if !Global.full_version():
#		$"%DLCWarning".visible = Custom.requires_dlc(get_style_data())
	pass

func load_style(style):
	if style:
		if style.show_aura:
			$"%TrailSettings".load_settings(style.aura_settings)
		$"%StyleName".text = style.style_name
		$"%ShowOutline".pressed = style.use_outline
		if style.use_outline:
			$"%Outline".set_color(style.outline_color)
		if style.get("extra_color_1"):
			$"%Extra1".set_color(style.extra_color_1)
		if style.get("extra_color_2"):
			$"%Extra2".set_color(style.extra_color_2)
	
		$"%ShowAura".pressed = style.show_aura
		call_deferred("create_aura", style.aura_settings)
		if style.character_color != null:
			$"%Character".set_color(style.character_color)
		for child in $"%HitsparkButtonContainer".get_children():
			if child.text == style.hitspark.strip_edges():
				child.pressed = true
				select_hitspark(style.hitspark)
	$"%WorkshopButton".disabled = false

func select_hitspark(hitspark_name):
	selected_hitspark = hitspark_name
	spawn_hitspark()
	update_warning()

func spawn_hitspark():
	if Custom.hitsparks.has(selected_hitspark):
		if is_instance_valid(hitspark_scene):
			hitspark_scene.queue_free()
		hitspark_scene = load(Custom.hitsparks[selected_hitspark]).instance()

		$"%HitsparkDisplay".add_child(hitspark_scene)

func _physics_process(delta):
	if !visible:
		return
	if !is_instance_valid(hitspark_scene):
		spawn_hitspark()
	else:
		hitspark_scene.tick()
#	for particle in custom_particles:
#		if is_instance_valid(particle):
#			particle.tick()

func _on_trail_settings_changed(settings):
	call_deferred("create_aura", settings)
	update_warning()

func create_aura(trail_settings):
	for particle in custom_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	custom_particles.clear()
	if !$"%ShowAura".pressed:
		return
	for node in [$"%MovingSprite", $"%StaticSprite"]:
		var particle = preload("res://fx/CustomTrailParticle.tscn").instance()
		node.add_child(particle)
		custom_particles.append(particle)
		particle.load_settings(trail_settings)

func _on_back_button_pressed():
	Global.reload()

func _on_reset_color_pressed():
	character_color = null
	extra_color_1 = null
	extra_color_2 = null
	$"%StaticSprite".get_material().set_shader_param("color", Color.white)
	$"%StaticSprite".get_material().set_shader_param("extra_color_1", Color.white)
	$"%StaticSprite".get_material().set_shader_param("extra_color_2", Color.white)
	_on_show_outline_toggled(false)
	update_warning()

func _on_character_color_changed(color):
	$"%StaticSprite".get_material().set_shader_param("color", color)
#	$"%MovingSprite".get_material().set_shader_param("color", color)
	character_color = color
	update_warning()

func _on_extra_color_1_changed(color):
	$"%StaticSprite".get_material().set_shader_param("extra_color_1", color)
	extra_color_1 = color
	update_warning()

func _on_extra_color_2_changed(color):
	$"%StaticSprite".get_material().set_shader_param("extra_color_2", color)
	extra_color_2 = color
	update_warning()

func _on_outline_color_changed(color):
	$"%ShowOutline".set_pressed_no_signal(true)
	$"%StaticSprite".get_material().set_shader_param("outline_color", color)
	$"%StaticSprite".get_material().set_shader_param("use_outline", true)
#	$"%MovingSprite".get_material().set_shader_param("color", color)
	outline_color = color
	update_warning()

func _on_show_outline_toggled(on):
	$"%StaticSprite".get_material().set_shader_param("use_outline", on)
	$"%ShowOutline".set_pressed_no_signal(on)
	update_warning()

func _on_character_button_pressed(button):
	for button in buttons:
		button.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)
	var character: Fighter = button.character_scene.instance()
	add_child(character)
	var character_texture = character.sprite.frames.get_frame("Wait", 0)
	var character_texture2 = character.character_portrait2
	$"%StaticSprite".get_material().set_shader_param("use_extra_color_1", character.use_extra_color_1)
	$"%StaticSprite".get_material().set_shader_param("use_extra_color_2", character.use_extra_color_2)
	$"%StaticSprite".get_material().set_shader_param("extra_replace_color_1", character.extra_color_1)
	$"%StaticSprite".get_material().set_shader_param("extra_replace_color_2", character.extra_color_2)
	$"%StaticSprite".texture = character_texture
	$"%MovingSprite".texture = character_texture2 if character_texture2 != null else character_texture
	character.free()

func _process(delta):
	if visible:
		$"%MovingSprite".position = moving_sprite_start + Vector2(Utils.wave(-50, 50, 2.0), 0)


func _on_StyleName_text_entered(new_text):
	save_style(false)
	pass # Replace with function body.

func _on_OpenFolderButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://custom"))
	pass # Replace with function body.

func _on_DLCWarning_meta_clicked(meta):
	Steam.activateGameOverlayToStore(SteamHustle.APP_ID)
	pass # Replace with function body.

func _on_WorkshopButton_pressed():
	save_style(false)
	var item = UGCItem.new()
	item.connect("item_created", self, "_on_item_created")
	item.connect("item_updated", self, "_on_item_updated")
	$"%WorkshopButton".disabled = true
	var image: Image = get_viewport().get_texture().get_data()
	image.flip_y()
	var rect = Rect2(Vector2(357, 119), Vector2(70, 70))
#	var rect = Rect2(Vector2(328, 117), Vector2(124, 70))
	image = image.get_rect(rect)
	image.resize(image.get_width() * 6, image.get_height() * 6, 0)
	workshop_preview_image = image

func _on_item_created(p_file_id):
	var data = get_style_data()
	data["workshop_id"] = p_file_id
	
	var folder_path = Custom.save_style_workshop(data)
	
	var item = UGCItem.new(p_file_id)
	item.set_tags(["Style"])
	item.set_title($"%StyleName".text)
	item.set_content(ProjectSettings.globalize_path(folder_path))
	item.set_visibility(0)
#	print(ProjectSettings.globalize_path(folder_path) + "/preview.png")
	workshop_preview_image.save_png(ProjectSettings.globalize_path(folder_path) + "/preview.png")
#	item.set_preview()
	item.set_preview(ProjectSettings.globalize_path(folder_path) + "/preview.png")
	item.update("new style")

func _on_item_updated(url):
	$"%WorkshopUpdatedLabel".clear()
	$"%WorkshopUpdatedLabel".append_bbcode("[u][url=%s]style uploaded to workshop[/url]" % url)
	$"%WorkshopUpdatedLabel".show()

func _on_StyleName_text_changed(new_text: String):
	$"%WorkshopButton".disabled = new_text.strip_edges() == ""
	$"%WorkshopUpdatedLabel".hide()


func _on_WorkshopUpdatedLabel_meta_clicked(meta):
	OS.shell_open(meta)
	pass # Replace with function body.


func _on_WorkshopButton2_pressed():
#	OS.shell_open("https://steamcommunity.com/app/2212330/workshop/")
	Steam.activateGameOverlayToWebPage("https://steamcommunity.com/app/2212330/workshop/")
	pass # Replace with function body.
