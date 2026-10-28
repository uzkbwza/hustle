extends Node

const SUPPORTER_PACK = 2232850
const WORKSHOP_STORE = preload("res://modloader/modio/WorkshopStore.gd")

# Pair-attach limb keys → the two underlying limb names. When an aura's
# attach_limb is one of these, two particles are spawned (one per limb).
const ATTACH_PAIRS = {
	"Hands": ["LeftHand", "RightHand"],
	"Feet": ["LeftFoot", "RightFoot"],
	# Eyes pair maps both indices to "Head" — the two particles share the
	# head limb's position and the per-eye spacing / y-offset settings
	# (attach_eye_spacing, attach_eye_left_y_offset, attach_eye_right_y_offset)
	# are applied on top in BaseChar._apply_aura_state.
	"Eyes": ["Head", "Head"],
}

# Renames from the older limb naming scheme. Applied at runtime so old saved
# styles still work without re-authoring.
const ATTACH_LIMB_MIGRATIONS := {
	"UpperBody": "",
	"LowerBody": "",
	"Body": "",
	"LeftArm": "LeftHand",
	"RightArm": "RightHand",
	"LeftLeg": "LeftFoot",
	"RightLeg": "RightFoot",
}

func migrate_attach_limb(name: String) -> String:
	if name in ATTACH_LIMB_MIGRATIONS:
		return ATTACH_LIMB_MIGRATIONS[name]
	return name

# Swaps "Left*" and "Right*" prefixes — used when the aura should follow the
# screen-side rather than the anatomical limb when the character is mirrored.
func swap_left_right_limb(name: String) -> String:
	if name.begins_with("Left"):
		return "Right" + name.substr(4)
	if name.begins_with("Right"):
		return "Left" + name.substr(5)
	return name

# Caps on internal particle count when expanding the aura array. Up to 3
# single-limb auras and up to 6 internal particles total (every slot could be
# a pair attach, so 3 slots × 2 limbs = 6). Anyone trying to stack >3
# single-limb auras will have the extras silently ignored — they need pair
# attaches (Hands/Feet) to actually use their later slots.
const MAX_AURA_SINGLES = 3
const MAX_AURA_INTERNAL = 6

# Returns true if the attach_limb string spawns a pair of particles.
func is_pair_attach(attach_limb: String) -> bool:
	return attach_limb in ATTACH_PAIRS

# Returns the two limb names for a pair attach, or null for a single attach.
func pair_limbs(attach_limb: String):
	if attach_limb in ATTACH_PAIRS:
		return ATTACH_PAIRS[attach_limb]
	return null

# Pulls the aura entries out of a style — supports the old aura_settings/
# aura_settings_2 schema and the new "auras" array. Returns array of dicts
# {show: bool, settings: dict}.
func style_auras(style) -> Array:
	if style == null:
		return []
	if style.has("auras") and style["auras"] is Array:
		var out := []
		for entry in style["auras"]:
			if entry is Dictionary:
				out.append({
					"show": entry.get("show", false),
					"settings": entry.get("settings"),
				})
		return out
	var legacy := []
	if style.get("show_aura") and style.get("aura_settings"):
		legacy.append({"show": true, "settings": style.get("aura_settings")})
	if style.get("show_aura_2") and style.get("aura_settings_2"):
		legacy.append({"show": true, "settings": style.get("aura_settings_2")})
	return legacy

# Expands the aura entries into the per-internal-particle list, capping at
# MAX_AURA_SINGLES singles and MAX_AURA_INTERNAL total. Each output entry is
# {settings, attach_limb, pair_index} where pair_index is 0 for first/single
# and 1 for the second limb in a pair.
func expand_aura_entries(entries: Array) -> Array:
	var out := []
	var single_count := 0
	for e in entries:
		if !e.get("show", false):
			continue
		var s = e.get("settings")
		if !(s is Dictionary):
			continue
		var attach = migrate_attach_limb(s.get("attach_limb", ""))
		if is_pair_attach(attach):
			if out.size() + 2 > MAX_AURA_INTERNAL:
				continue
			out.append({"settings": s, "attach_limb": attach, "pair_index": 0})
			out.append({"settings": s, "attach_limb": attach, "pair_index": 1})
		else:
			if single_count >= MAX_AURA_SINGLES:
				continue
			if out.size() + 1 > MAX_AURA_INTERNAL:
				continue
			single_count += 1
			out.append({"settings": s, "attach_limb": attach, "pair_index": 0})
	return out

# Resolves the actual single limb name for an entry — for pair attaches this
# is one of the two real limbs; for singles it's the attach_limb itself.
func resolve_attach_limb(entry: Dictionary) -> String:
	var attach = entry.get("attach_limb", "")
	if is_pair_attach(attach):
		var pair = ATTACH_PAIRS[attach]
		return pair[entry.get("pair_index", 0)]
	return attach

var hitsparks = {
	"bash": "res://fx/HitEffect1.tscn",
	"bash2": "res://fx/hitsparks/HitEffect1Alt.tscn",
	"bash3": "res://fx/hitsparks/HitEffect2Alt.tscn",
	"fire": "res://fx/hitsparks/FireHitEffect.tscn",
	"hearts": "res://fx/hitsparks/HeartHitEffect.tscn",
	"petals": "res://fx/hitsparks/PetalHitEffect.tscn",
	"coins": "res://fx/hitsparks/CoinHitEffect.tscn",
	"dust": "res://fx/hitsparks/DustHitEffect.tscn",
	"acid": "res://fx/hitsparks/AcidHitEffect.tscn",
	"elec": "res://fx/hitsparks/ElectricHitEffect.tscn",
}

# Sprite-frame resources usable by the custom hitspark editor's "advanced"
# tab. Order is the order they appear in the OptionButton; the empty string
# is the "(none)" option which renders no animated sprite at all.
const HITSPARK_SPRITE_NAMES = ["", "bash", "bash2", "bash3", "fire", "hearts", "petals", "acid", "elec"]
const HITSPARK_SPRITE_NONE_LABEL = "(none)"
const CUSTOM_HITSPARK_SCENE_PATH = "res://fx/hitsparks/CustomHitEffect.tscn"
# Non-default AnimatedSprite scales for sprite frame sets that need them — the
# elec frames are designed to be drawn wide-and-short and look wrong at 1:1.
# Names absent from this dict default to Vector2(1, 1).
const HITSPARK_SPRITE_SCALES = {
	"elec": Vector2(1.36, 0.68),
}

# Display label for a sprite name in the option button — the empty-string
# "no animation" entry shows up as "(none)".
func hitspark_sprite_label(sprite_name: String) -> String:
	if sprite_name == "":
		return HITSPARK_SPRITE_NONE_LABEL
	return sprite_name

# Build a fresh PackedScene of a custom hitspark with the user's chosen
# animated-sprite frames already applied. The result can be assigned to
# Hitbox.HIT_PARTICLE just like the named-preset scenes — each hit instance()s
# its own copy. Returns null if the template can't be loaded.
func make_custom_hitspark_scene(config) -> PackedScene:
	var template = load(CUSTOM_HITSPARK_SCENE_PATH)
	if template == null:
		return null
	# Per-instance config goes through the CustomHitEffect script's
	# `custom_config` member (set by spawners before add_child), not through
	# PackedScene.pack — which doesn't reliably preserve Dictionary or
	# sub-scene-instance overrides in Godot 3 and was leaving particles
	# unconfigured. The packed template itself is identical for every style;
	# the spawn site decides what config to apply.
	return template

#var hitspark_dlc = {
#	"bash": false,
#	"bash2": false,
#	"hearts": true,
#}

var p1_selected_style = null
var p2_selected_style = null

var simple_colors = ["94e4ff", "ffc1a1", "ecffa4", "fec2ff", "6e8696", "ffea5d", "04579a", "85001f", "008561", "9f42ba", "343537", "ff9444"]
var simple_outlines = ["04579a", "85001f", "008561", "9f42ba", "343537", "ff9444", "94e4ff", "ffc1a1", "ecffa4", "fec2ff", "6e8696", "ffea5d"]

func _ready():
	for i in range(simple_colors.size()):
		simple_colors[i] = Color(simple_colors[i])
		simple_outlines[i] = Color(simple_outlines[i])
	make_custom_folder()
	
func make_custom_folder():
	var dir = Directory.new()
	if !dir.dir_exists("user://custom"):
		dir.make_dir("user://custom")

func apply_style_to_material(style, material: ShaderMaterial, force_extras = false):
	if style.character_color != null:
		material.set_shader_param("color", style.character_color)
	material.set_shader_param("use_outline", style.use_outline)
	if style.outline_color != null:
		material.set_shader_param("outline_color", style.outline_color)
	if style.get("extra_color_1") != null:
		material.set_shader_param("extra_color_1", style.extra_color_1)
		if force_extras:
			material.set_shader_param("use_extra_color_1", true)
	else:
		material.set_shader_param("use_extra_color_1", false)
	if style.get("extra_color_2") != null:
		material.set_shader_param("extra_color_2", style.extra_color_2)
		if force_extras:
			material.set_shader_param("use_extra_color_2", true)
	else:
		material.set_shader_param("use_extra_color_2", false)
	pass


func is_combo_simple(color, outline):
	return simple_colors.find(color) == simple_outlines.find(outline)

func is_color_dlc(color):
	if color == null:
		return false
	if !(color is Color):
		return !(Color(color) in simple_colors)
	return !(color in simple_colors)

func is_outline_dlc(color):
	if color == null:
		return false
	if !(color is Color):
		return !(Color(color) in simple_outlines)
	return !(color in simple_outlines)

func hitspark_to_dlc(spark_name):
#	if spark_name in hitspark_dlc:
#		return hitspark_dlc[spark_name]
	return 0

func can_use_style(player_id, style):
	if !requires_dlc(style):
		return Global.full_version()
	return true
#	if !Network.multiplayer_active:
##		return Global.has_supporter_pack()
#		return true
#	elif SteamHustle.STARTED:
#		if SteamLobby.SPECTATING:
#			return true
#		if player_id == SteamLobby.PLAYER_SIDE:
#			var has_supporter_pack = SteamHustle.has_supporter_pack(SteamHustle.STEAM_ID)
#			if has_supporter_pack:
#				print("You have the supporter pack.")
#			else:
#				print("You do not have the supporter pack.")
#			return has_supporter_pack
#		elif SteamLobby.OPPONENT_ID != 0:
#			var has_supporter_pack = SteamHustle.has_supporter_pack(SteamLobby.OPPONENT_ID)
#			if has_supporter_pack:
#				print("Your opponent has the supporter pack.")
#			else:
#				print("Your opponent does not have the supporter pack.")
#			return has_supporter_pack

func requires_dlc(data):
#	return false
#	if data == null:
#		return false
#	if data.show_aura:
#		return true
#	if is_color_dlc(data.character_color):
#		return true
#	if data.use_outline and is_outline_dlc(data.outline_color):
#		return true
#	if data.use_outline and !is_combo_simple(data.character_color, data.outline_color):
#		return true
#	if hitspark_to_dlc(data.hitspark):
#		return true
	return false


func save_style(style):
	make_custom_folder()
	var file = File.new()
	var filename_ = "user://custom/"+ style.style_name + ".style"
	# Empty dict reserved for mod-specific data attached to the style.
	if !style.has("mod_data"):
		style["mod_data"] = {}
	file.open(filename_, File.WRITE)
	file.store_var(style, true)
	file.close()
	return filename_

func save_style_workshop(style):
	var dir = Directory.new()
	var file = File.new()
	var folder_path = "user://custom/" + style.style_name
	if !dir.dir_exists(folder_path):
		dir.make_dir(folder_path)
	var filename_ = folder_path + "/" + style.style_name + ".style"
	if !style.has("mod_data"):
		style["mod_data"] = {}
	file.open(filename_, File.WRITE)
	file.store_var(style, true)
	file.close()
	return folder_path

func load_all_styles():
	make_custom_folder()
	var dir = Directory.new()
	var files = []
	var _directories = []
	var styles = []
	dir.open("user://custom")
	dir.list_dir_begin(false, true)
#	print(dir.get_current_dir())
	Global.add_dir_contents(dir, files, _directories, false, ".style")

	var workshop_files = []
	if SteamHustle.STARTED and SteamHustle.WORKSHOP_ENABLED:
		var workshop = SteamWorkshop.new()
		var content_root := ""
		var seen := {}
		var subscribed = Steam.getSubscribedItems()
		if subscribed == null:
			subscribed = []
		for item in subscribed:
			var info : Dictionary
			info = workshop.get_item_install_info(item)
			if not info.ret or str(info.get("folder", "")) == "":
				continue
			var item_folder = str(info.folder)
			seen[str(int(item))] = true
			content_root = item_folder.get_base_dir()
			_scan_workshop_styles(item_folder, workshop_files, _directories)
		var root_dir = Directory.new()
		if content_root != "" and root_dir.open(content_root) == OK:
			root_dir.list_dir_begin(true, true)
			while true:
				var name = root_dir.get_next()
				if name == "":
					break
				if not root_dir.current_is_dir() or not name.is_valid_integer():
					continue
				if not seen.has(name):
					_scan_workshop_styles(content_root.plus_file(name), workshop_files, _directories)
			root_dir.list_dir_end()

	files = _dedupe_styles(workshop_files + files)
	files.sort_custom(self, "sort_styles")
#	for file in files:
#		print(get_style_name(file))

	for path in files:
		var file = File.new()
		file.open(path, File.READ)
		var data = file.get_var()
		file.close()
		if !(data is Dictionary):
			continue
		if !data.has("mod_data"):
			data["mod_data"] = {}
		styles.append(data)

	return [styles, files]

func get_style_name(path):
	return path.get_file().split(".")[0].strip_edges()

func sort_styles(a: String, b: String):
	return get_style_name(a) < get_style_name(b)

func _dedupe_styles(files: Array) -> Array:
	var seen := {}
	var unique := []
	for path in files:
		var style_name = get_style_name(path)
		if seen.has(style_name):
			continue
		seen[style_name] = true
		unique.append(path)
	return unique

func _scan_workshop_styles(folder: String, out: Array, directories: Array) -> void:
	var dir = Directory.new()
	if dir.open(folder) != OK:
		return
	# skip "." and "..": with recursion, ".." would scan every workshop item
	if dir.list_dir_begin(true, true) != OK:
		return
	Global.add_dir_contents(dir, out, directories, true, ".style")
