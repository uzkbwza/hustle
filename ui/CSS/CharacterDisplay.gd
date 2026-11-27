extends VBoxContainer

export var player_id = 1
export var save_style = false

signal style_selected(style)

const STYLE_LIST_DIR := "user://lists/custom"
const StyleListButton = preload("res://ui/CustomizationScreen/StyleListButton.gd")

var selected_style = null
var selected_list_data := {}
var aura_particles := []
var character_limb_data := {}
var _style_options := []
var _random_options := []
onready var style_menu_button = $"%StyleMenuButton"
onready var random_menu_button = $"%RandomMenuButton"
onready var style_buttons = $"CenterContainer/StyleButtons"
onready var style_menu = $"%MenuLayer/StyleMenu"
onready var random_menu = $"%MenuLayer/RandomMenu"
onready var style_items = $"%MenuLayer/StyleMenu/StyleScroll/StyleItems"
onready var random_items = $"%MenuLayer/RandomMenu/RandomScroll/RandomItems"

func _ready():
	$"%PlayerLabel".text = "P1" if player_id == 1 else "P2"
	$"%CharacterPortrait".flip_h = player_id != 1
	call_deferred("_raise_style_ui")

func _raise_style_ui():
	var center = style_buttons.get_parent()
	if center != null:
		center.move_child(style_buttons, center.get_child_count() - 1)
	var layer = style_menu.get_parent()
	if layer != null:
		move_child(layer, get_child_count() - 1)
	style_menu_button.connect("pressed", self, "_open_style_menu")
	random_menu_button.connect("pressed", self, "_open_random_menu")
	if not Global.is_connected("mobile_ui_changed", self, "_on_mobile_ui_changed"):
		Global.connect("mobile_ui_changed", self, "_on_mobile_ui_changed")

func _on_mobile_ui_changed(_mobile):
	if style_menu.visible:
		_rebuild_style_options()
		_place_menu(style_menu, style_items, style_menu_button)
	elif random_menu.visible:
		_rebuild_random_options()
		_place_menu(random_menu, random_items, random_menu_button)

func _rebuild_style_options():
	_style_options = []
	for child in style_items.get_children():
		child.free()
	_add_style_option("style: off", null, "")
	var all = Custom.load_all_styles()
	var all_styles = all[0]
	var all_paths = all[1]
	for i in range(all_styles.size()):
		var style = all_styles[i]
		if !Custom.can_use_style(player_id, style):
			continue
		_add_style_option(style.style_name, style, str(all_paths[i]))
	style_items.rect_min_size = Vector2(0, _style_options.size() * (_menu_item_height() + 2))

func _rebuild_random_options():
	_random_options = []
	for child in random_items.get_children():
		child.free()
	_add_random_option("random style: off", {})
	var lists = FileManager.load_all_lists(STYLE_LIST_DIR)
	for list_data in lists:
		if list_data.get("list_name", "") == "_current_state":
			continue
		_add_random_option(str(list_data.get("list_name", "default")), list_data)
	random_items.rect_min_size = Vector2(0, _random_options.size() * (_menu_item_height() + 2))

func _menu_item_height() -> int:
	return 24 if Global.mobile_ui else 14

func _make_menu_button(text, parent, target, method, index):
	var h = _menu_item_height()
	var btn = Button.new()
	btn.text = text
	btn.rect_min_size = Vector2(0, h)
	btn.rect_position = Vector2(0, index * (h + 2))
	btn.rect_size = Vector2(max(0, parent.rect_size.x - 4), h)
	btn.connect("pressed", target, method, [index])
	parent.add_child(btn)

func _add_style_option(text, style, path):
	var idx = _style_options.size()
	_style_options.append({"style": style, "path": path})
	_make_menu_button(text, style_items, self, "_on_style_option_pressed", idx)

func _add_random_option(text, list_data):
	var idx = _random_options.size()
	_random_options.append({"list": list_data})
	_make_menu_button(text, random_items, self, "_on_random_option_pressed", idx)

func _place_menu(menu, items, button):
	var layer = menu.get_parent()
	var below = button.rect_global_position + Vector2(0, button.rect_size.y + 2)
	var local = below - layer.rect_global_position
	var screen = get_viewport().get_visible_rect().size
	var width = max(160.0, style_buttons.rect_size.x + 24.0)
	var global_x = style_buttons.rect_global_position.x + style_buttons.rect_size.x * 0.5 - width * 0.5
	local.x = clamp(global_x - layer.rect_global_position.x, -layer.rect_global_position.x, max(-layer.rect_global_position.x, screen.x - width - layer.rect_global_position.x))
	menu.rect_position = local
	var h = _menu_item_height()
	var count = items.get_child_count()
	var content_height = count * (h + 2)
	var max_height = max(h + 2, screen.y - below.y - 10.0)
	var scroll = items.get_parent()
	var item_width = width - 6.0
	if content_height > max_height:
		item_width -= 10.0
	scroll.rect_min_size = Vector2(width - 2.0, min(content_height, max_height))
	items.rect_min_size = Vector2(item_width, content_height)
	menu.rect_size = menu.get_combined_minimum_size()
	for i in range(count):
		var btn = items.get_child(i)
		btn.rect_size = Vector2(item_width, h)
		btn.rect_position = Vector2(2.0, i * (h + 2))

func _open_style_menu():
	if style_menu.visible:
		style_menu.hide()
		return
	random_menu.hide()
	_rebuild_style_options()
	_place_menu(style_menu, style_items, style_menu_button)
	style_menu.show()

func _open_random_menu():
	if random_menu.visible:
		random_menu.hide()
		return
	style_menu.hide()
	_rebuild_random_options()
	_place_menu(random_menu, random_items, random_menu_button)
	random_menu.show()

func _on_style_option_pressed(index):
	if index < 0 or index >= _style_options.size():
		return
	style_menu.hide()
	var option = _style_options[index]
	selected_list_data = {}
	if save_style:
		Global.save_player_data({"last_style": option["path"]})
	_on_style_selected(option["style"])

func _on_random_option_pressed(index):
	if index < 0 or index >= _random_options.size():
		return
	random_menu.hide()
	selected_list_data = _random_options[index]["list"]
	if save_style:
		Global.save_player_data({"last_style": ""})
	_on_style_selected(null)

func _on_style_selected(style):
	emit_signal("style_selected", style)
	selected_style = style
	var material = $"%CharacterPortrait".get_material()
	material.set_shader_param("color", Color.white)
	material.set_shader_param("use_outline", false)
	$"%CharacterPortrait".get_material().set_shader_param("use_extra_color_1", false)
	$"%CharacterPortrait".get_material().set_shader_param("use_extra_color_2", false)
	if style:
		Custom.apply_style_to_material(style, $"%CharacterPortrait".get_material(), true)
	_refresh_auras()

# Recreates the aura particles from selected_style. Doesn't touch shader
# params — call _on_style_selected if you need a full reset.
func _refresh_auras():
	for p in aura_particles:
		if is_instance_valid(p):
			p.queue_free()
	aura_particles.clear()
	if !selected_style:
		return
	var expanded = Custom.expand_aura_entries(Custom.style_auras(selected_style))
	for entry in expanded:
		var particle = _create_display_particle(entry)
		if particle != null:
			aura_particles.append(particle)

func _create_display_particle(entry: Dictionary):
	var settings = entry["settings"]
	var attach_limb = entry["attach_limb"]
	var resolved = Custom.resolve_attach_limb(entry)
	# Mirror left/right limbs on a flipped portrait so the aura stays on the
	# same screen side, matching the in-game `attach_consistent_screen_side`
	# behavior.
	if $"%CharacterPortrait".flip_h and settings is Dictionary and settings.get("attach_consistent_side", true):
		resolved = Custom.swap_left_right_limb(resolved)
	var limb_entry = _display_limb_entry(resolved) if attach_limb != "" else null
	# Skip entirely when an attached aura's limb has no data on this portrait
	# — auto-restart in _physics_process makes "create + pause emit" unreliable.
	if attach_limb != "" and limb_entry == null:
		return null
	var particle = preload("res://fx/CustomTrailParticle.tscn").instance()
	$"%CharacterPortrait".add_child(particle)
	particle.load_settings(settings)
	if attach_limb != "":
		particle.position = _display_aura_pos(limb_entry)
		# Eyes: fold per-eye spacing/y into default_x/y_offset so it rides
		# the rotation pipeline (mirrors BaseChar). Set the combined value
		# from the saved base offset — never += or it accumulates.
		if attach_limb == "Eyes":
			var pair_idx = entry.get("pair_index", 0)
			var spacing = float(settings.get("attach_eye_spacing", 6))
			var x_eye = -spacing * 0.5 if pair_idx == 0 else spacing * 0.5
			var y_eye = float(settings.get("attach_eye_left_y_offset", 0)) if pair_idx == 0 else float(settings.get("attach_eye_right_y_offset", 0))
			particle.default_x_offset = float(settings.get("x_offset", 0)) + x_eye
			particle.default_y_offset = float(settings.get("y_offset", 0)) + y_eye
		particle.attached_to_limb = true
		if settings.get("attach_position_only", true):
			particle.attached_rotation = 0.0
			particle.attached_limb_flipped = false
		else:
			particle.attached_rotation = _display_aura_rotation(limb_entry)
			var flipped = limb_entry.get("flipped", false)
			if entry.get("pair_index", 0) == 1 and settings.get("attach_pair_mirror", true):
				flipped = !flipped
			particle.attached_limb_flipped = flipped
			# See BaseChar — compensate the mirrored eye's x_offset so the
			# user's global offset moves both eyes together while the
			# texture still flips.
			if attach_limb == "Eyes" and entry.get("pair_index", 0) == 1 and settings.get("attach_pair_mirror", true):
				particle.default_x_offset = -particle.default_x_offset
		# Flipped portrait (P2) treated as facing left so x_offset mirrors.
		particle.facing = -1 if $"%CharacterPortrait".flip_h else 1
	else:
		particle.position = $"%CharacterPortrait".rect_size / 2
		if particle.flip_with_character or player_id == 1:
			particle.scale.x = -1 if player_id == 2 else 1
		particle.facing = -1 if player_id == 2 else 1
	return particle

func _display_limb_entry(limb_name):
	if limb_name == "" or character_limb_data.empty():
		return null
	if !character_limb_data.has(limb_name):
		return null
	var tex = $"%CharacterPortrait".texture
	if tex == null:
		return null
	var by_tex = character_limb_data[limb_name]
	var entry = null
	if by_tex.has(tex):
		entry = by_tex[tex]
	else:
		var tex_path = tex.resource_path if tex.resource_path else ""
		if tex_path != "":
			for key in by_tex.keys():
				if key is Texture and key.resource_path == tex_path:
					entry = by_tex[key]
					break
	if entry == null:
		return null
	if entry is Dictionary and entry.get("absent", false):
		return null
	return entry

# Scale factor texture-pixel → display-pixel for the current portrait
# under its stretch_mode. Used to scale eye-attach offsets (stored in
# texture-pixel units) so they match the displayed limb-pixel scale.
func _display_scale() -> float:
	var rect = $"%CharacterPortrait"
	var tex = rect.texture
	if tex == null:
		return 1.0
	var rect_size = rect.rect_size
	var tex_size = tex.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return 1.0
	match rect.stretch_mode:
		TextureRect.STRETCH_KEEP, TextureRect.STRETCH_KEEP_CENTERED:
			return 1.0
		TextureRect.STRETCH_KEEP_ASPECT, TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			return min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			return max(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
		_:
			# STRETCH_SCALE — x and y can diverge but eye offsets are
			# symmetric on each axis, so average is the best single scalar.
			return (rect_size.x / tex_size.x + rect_size.y / tex_size.y) * 0.5

# Texture-pixel → TextureRect-local pixel. Picks the right scaling based on
# the rect's stretch_mode. Mirrors the X axis when the portrait is flipped.
func _display_aura_pos(entry) -> Vector2:
	var rect = $"%CharacterPortrait"
	var tex = rect.texture
	var rect_size = rect.rect_size
	var tex_size = tex.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return rect_size / 2
	var s
	match rect.stretch_mode:
		TextureRect.STRETCH_KEEP, TextureRect.STRETCH_KEEP_CENTERED:
			s = 1.0
		TextureRect.STRETCH_KEEP_ASPECT, TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			s = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			s = max(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
		_:
			# STRETCH_SCALE / STRETCH_SCALE_ON_EXPAND: stretch to fill the rect
			# without preserving aspect.
			var rect_pos = Vector2(
				entry.x * (rect_size.x / tex_size.x),
				entry.y * (rect_size.y / tex_size.y))
			if rect.flip_h:
				rect_pos.x = rect_size.x - rect_pos.x
			return rect_pos
	var off
	match rect.stretch_mode:
		TextureRect.STRETCH_KEEP, TextureRect.STRETCH_KEEP_ASPECT:
			# Top-left aligned (no centering).
			off = Vector2(0, 0)
		_:
			off = Vector2((rect_size.x - tex_size.x * s) / 2, (rect_size.y - tex_size.y * s) / 2)
	var rect_pos = off + Vector2(entry.x, entry.y) * s
	if rect.flip_h:
		rect_pos.x = rect_size.x - rect_pos.x
	return rect_pos

func _display_aura_rotation(entry) -> float:
	var dir = Vector2(entry.dir_x, entry.dir_y)
	if dir.length_squared() < 0.0001:
		return 0.0
	var angle = dir.angle()
	# Mirror the angle when the portrait is flipped — combined with scale.x
	# = -1 (facing = -1) this aligns the world emission with the displayed
	# (mirrored) limb dir.
	if $"%CharacterPortrait".flip_h:
		angle = -angle
	return angle

func load_last_style():
	yield(get_tree(), "idle_frame")
	var last_style = Global.get_player_data()["last_style"]
	if last_style == "":
		return
	_rebuild_style_options()
	for option in _style_options:
		if option["path"] == last_style:
			_on_style_selected(option["style"])
			return

func init():
	$"%CharacterLabel".text = ""
	set_enabled(true)
	save_style = true
	style_menu_button.hide()
	random_menu_button.hide()
	style_menu.hide()
	random_menu.hide()
	if !Network.multiplayer_active or player_id == Network.player_id:
		style_menu_button.show()
		random_menu_button.show()

func load_character_data(data):
	$"%CharacterPortrait".texture = data["portrait"]
	$"%CharacterLabel".text = data["name"]
	$"%CharacterPortrait".get_material().set_shader_param("extra_replace_color_1", data.get("extra_color_1"))
	$"%CharacterPortrait".get_material().set_shader_param("extra_replace_color_2", data.get("extra_color_2"))
	character_limb_data = data.get("limb_data", {})
	# Re-create any active auras now that the portrait + limb data have changed.
	_refresh_auras()

func set_enabled(on):
	for child in get_children():
		if child == style_menu or child == random_menu:
			continue
		child.visible = on
	save_style = on


func get_style_for_match(seed_value: int):
	if !selected_list_data.empty():
		var picked = StyleListButton.pick_from_list(selected_list_data, player_id, seed_value)
		if picked != null:
			return picked
	return selected_style

