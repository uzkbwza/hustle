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
# Sprite name for the advanced/custom hitspark editor — "" maps to (none).
var custom_hitspark_sprite := ""
# Two parallel slots, same shape as the aura cache: each entry is either a
# settings dict (last value the user touched) or null. Slot 0 maps to the
# legacy `particles` / `show_particles` config fields, slot 1 to
# `particles_2` / `show_particles_2`.
const HITSPARK_PARTICLE_SLOT_COUNT = 2
var custom_hitspark_particles = [null, null]
var custom_hitspark_show_particles = [false, false]
var current_hitspark_particle_slot := 0
var hitspark_particle_slot_tabs: Tabs = null
var copy_hitspark_particles_button: Button = null
var paste_hitspark_particles_button: Button = null
var swap_hitspark_particles_button: Button = null
var hitspark_particles_clipboard = null
# Full-hitspark clipboard — covers sprite, both particle slots, the flip
# toggle. Separate from the per-slot particles clipboard above.
var copy_hitspark_button: Button = null
var paste_hitspark_button: Button = null
var hitspark_clipboard = null
var loading_hitspark_particle_slot := false
# When true, left-facing hitspark spawns are just horizontally mirrored
# (scale.x = -1) instead of also rotated 180°. Useful for asymmetric sprites
# where the rotation reads "upside down" rather than "mirrored".
var custom_hitspark_flip_when_facing_left := false
var loading_hitspark_particles := false

var workshop_preview_image: Image = null

# FileManagerInterface node already on the scene — same class the mod loader
# uses. Here it manages named LISTS of which styles are toggled on/off for
# the character-select randomizer (exactly like mod on/off lists), NOT the
# single-style save/load, which now goes exclusively through
# %StyleListContainer below.
onready var file_manager: FileManagerInterface = $"%FileManagerInterface"

# One entry per discovered ".style" file on disk:
# style_name -> { "active": bool, "path": String, "toggle": CheckButton,
#                 "button": Button, "parent": Control }
var styles: Dictionary = {}

# Name of whichever style entry is currently loaded into the editor, so the
# %StyleListContainer button for it can be highlighted. "" when nothing
# loaded from the list yet (e.g. a brand-new unsaved style).
var current_style_name := ""

# Style list sort mode - mirrors ModLoaderMenu's sorter. Cycles
# NAME -> DATE -> ACTIVE -> NAME and reorders the %StyleListContainer
# entries. The %SortInvert toggle flips the order. Comparison logic lives
# in the shared FileManager.sort_items().
var cur_style_sort = FileManager.SortMode.NAME
var cur_style_inverted := false

var hitspark_scene = null

const AURA_SLOT_COUNT = 3
var current_aura_slot = 0
var aura_show = [false, false, false]
var aura_settings_cache = [null, null, null]
var aura_slot_tabs: Tabs = null
var copy_aura_button: Button = null
var paste_aura_button: Button = null
var swap_aura_button: MenuButton = null
var aura_clipboard = null
var loading_aura_slot = false

# limb_data dict from the currently-previewed character (for attaching auras
# to limbs on the portrait sprites in the customization preview).
var current_character_limb_data := {}

# Attribution: creator + last-N modifiers (capped by MAX_STYLE_MODIFIERS).
# Filled from the loaded .style
# dict; updated on save when the user has actually made changes. The *_id
# arrays are parallel to the username arrays — same index, same person —
# and hold steam_ids as strings (or "" for non-steam users / unknown).
# Used so a re-save by the latest person in the chain can bypass the
# allow_others_save gate even when usernames clash.
var loaded_style_creator := ""
var loaded_style_creator_id := ""
# Old styles (saved before attribution existed) and renounced-creator styles
# both flag this so the claim button can offer to attach the current user.
# It's an explicit flag rather than a name check because we don't want a
# real user named "unknown" to be treated as unattributed.
var loaded_style_creator_unknown := false
var loaded_style_modifiers := []
var loaded_style_modifier_ids := []
var style_modified_since_load := false
const MAX_STYLE_MODIFIERS := 2000
const UNKNOWN_CREATOR_NAME := "unknown"
# x-coord where the ClaimButton's right edge sits — captured from the .tscn
# so the box can grow leftward as text changes (claim → renounce) without
# the right edge wandering.
const CLAIM_BUTTON_RIGHT_EDGE := 522.0

func get_style_data():
	save_current_aura_slot()
	save_current_hitspark_particle_slot()
	var auras := []
	for i in range(AURA_SLOT_COUNT):
		auras.append({"show": aura_show[i], "settings": aura_settings_cache[i]})
	var data = {
		"style_name": Utils.filter_filename($"%StyleName".text.strip_edges()) if $"%StyleName".text.strip_edges() else "untitled" + str(int(Time.get_unix_time_from_system())),
		"character_color": character_color,
		"extra_color_1": extra_color_1,
		"extra_color_2": extra_color_2,
		"use_outline": $"%ShowOutline".pressed,
		"outline_color": outline_color if $"%ShowOutline".pressed else null,
		"hitspark": "bash" if selected_hitspark == null else selected_hitspark,
		# Custom hitspark editor state — only meaningful when hitspark == "custom".
		# Always written so the round-trip preserves the user's last sprite pick
		# even after they toggle back to a Simple preset.
		"custom_hitspark": get_custom_hitspark_config(),
		# Old-format mirrors of the first two array entries — kept so older
		# game versions can still read newly-saved styles.
		"show_aura": aura_show[0],
		"aura_settings": aura_settings_cache[0],
		"show_aura_2": aura_show[1],
		"aura_settings_2": aura_settings_cache[1],
		"auras": auras,
		"ivy_effect": false,
		# Unknown / renounced styles round-trip through an empty creator field
		# so older game versions (and the load_style branch above) treat them
		# as unattributed instead of seeing the literal "unknown" string.
		"creator": "" if loaded_style_creator_unknown else loaded_style_creator,
		"creator_id": "" if loaded_style_creator_unknown else loaded_style_creator_id,
		"modifiers": loaded_style_modifiers.duplicate(),
		"modifier_ids": loaded_style_modifier_ids.duplicate(),
		# Empty dict reserved for mod-specific data attached to the style.
		"mod_data": {},
	}
	if Global.STYLE_SAVE_FEATURE_ENABLED:
		data["allow_others_save"] = $"%AllowSaveButton".pressed
	return data

func save_current_aura_slot():
	if loading_aura_slot:
		return
	var show = $"%ShowAura".pressed
	var settings = $"%TrailSettings".get_settings()
	var sync_on = has_node("%SyncAuraChanges") and $"%SyncAuraChanges".pressed
	var prev_settings = aura_settings_cache[current_aura_slot]
	var prev_show = aura_show[current_aura_slot]
	# Sync only the keys that actually changed since the last save of THIS slot,
	# so each other slot keeps its own values for everything the user didn't
	# touch. Skipped on the first save (when the prev cache is null) — that
	# would propagate the entire form state and clobber distinct slots.
	if sync_on and prev_settings is Dictionary and settings is Dictionary:
		for i in range(AURA_SLOT_COUNT):
			if i == current_aura_slot:
				continue
			if show != prev_show:
				aura_show[i] = show
			if not (aura_settings_cache[i] is Dictionary):
				aura_settings_cache[i] = settings.duplicate(true)
			else:
				for key in settings:
					if not (key in prev_settings) or prev_settings[key] != settings[key]:
						aura_settings_cache[i][key] = settings[key]
	aura_show[current_aura_slot] = show
	aura_settings_cache[current_aura_slot] = settings

func switch_aura_slot(slot):
	save_current_aura_slot()
	current_aura_slot = posmod(slot, AURA_SLOT_COUNT)
	loading_aura_slot = true
	$"%ShowAura".pressed = aura_show[current_aura_slot]
	if aura_settings_cache[current_aura_slot]:
		$"%TrailSettings".load_settings(aura_settings_cache[current_aura_slot])
	else:
		$"%TrailSettings".load_settings(CustomTrailParticle.get_default())
	loading_aura_slot = false
	if aura_slot_tabs:
		aura_slot_tabs.current_tab = current_aura_slot
	_refresh_swap_aura_menu()
	create_all_auras()

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
	$"%ManageStylesButton".connect("toggled", self, "_on_manage_styles_pressed")
	$"%Sorter".connect("pressed", self, "_on_style_sorter_pressed")
	$"%SortInvert".connect("toggled", self, "_on_style_sort_invert_toggled")
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
	# Advanced hitspark tab: sprite picker. "(none)" first, then the named
	# sprite frame sets pulled from Custom.HITSPARK_SPRITE_NAMES.
	if has_node("%HitsparkSpriteOption"):
		for sprite_name in Custom.HITSPARK_SPRITE_NAMES:
			$"%HitsparkSpriteOption".add_item(Custom.hitspark_sprite_label(sprite_name))
		$"%HitsparkSpriteOption".connect("item_selected", self, "_on_custom_hitspark_sprite_selected")
	if has_node("%HitsparkTabs"):
		$"%HitsparkTabs".connect("tab_changed", self, "_on_hitspark_tab_changed")
	if has_node("%HitsparkParticles"):
		$"%HitsparkParticles".connect("settings_changed", self, "_on_hitspark_particles_changed")
		# Seed the editor with the hitspark default so explosiveness=1 etc.
		# are visible from the start.
		loading_hitspark_particles = true
		$"%HitsparkParticles".load_settings(_default_hitspark_particles())
		loading_hitspark_particles = false
	if has_node("%ShowHitsparkParticles"):
		$"%ShowHitsparkParticles".connect("toggled", self, "_on_show_hitspark_particles_toggled")
	if has_node("%HitsparkParticleSlotTabsContainer"):
		hitspark_particle_slot_tabs = Tabs.new()
		hitspark_particle_slot_tabs.theme = preload("res://theme.tres")
		hitspark_particle_slot_tabs.tab_align = Tabs.ALIGN_LEFT
		hitspark_particle_slot_tabs.size_flags_horizontal = SIZE_EXPAND_FILL
		for i in range(HITSPARK_PARTICLE_SLOT_COUNT):
			hitspark_particle_slot_tabs.add_tab("Particles %d" % (i + 1))
		hitspark_particle_slot_tabs.current_tab = 0
		hitspark_particle_slot_tabs.connect("tab_changed", self, "_on_hitspark_particle_slot_tab_changed")
		$"%HitsparkParticleSlotTabsContainer".add_child(hitspark_particle_slot_tabs)
	if has_node("%HitsparkCopyPasteRow"):
		copy_hitspark_particles_button = Button.new()
		copy_hitspark_particles_button.text = "copy particles"
		copy_hitspark_particles_button.hint_tooltip = "Copy this slot's particle settings."
		copy_hitspark_particles_button.connect("pressed", self, "_on_copy_hitspark_particles_pressed")
		$"%HitsparkCopyPasteRow".add_child(copy_hitspark_particles_button)
		paste_hitspark_particles_button = Button.new()
		paste_hitspark_particles_button.text = "paste particles"
		paste_hitspark_particles_button.hint_tooltip = "Paste particles into this slot."
		paste_hitspark_particles_button.disabled = true
		paste_hitspark_particles_button.connect("pressed", self, "_on_paste_hitspark_particles_pressed")
		$"%HitsparkCopyPasteRow".add_child(paste_hitspark_particles_button)
		swap_hitspark_particles_button = Button.new()
		swap_hitspark_particles_button.text = "swap particles"
		swap_hitspark_particles_button.hint_tooltip = "Swap the two hitspark particle slots."
		swap_hitspark_particles_button.connect("pressed", self, "_on_swap_hitspark_particles_pressed")
		$"%HitsparkCopyPasteRow".add_child(swap_hitspark_particles_button)
	if has_node("%HitsparkConfigCopyPasteRow"):
		copy_hitspark_button = Button.new()
		copy_hitspark_button.text = "copy hitspark"
		copy_hitspark_button.hint_tooltip = "Copy the whole hitspark config."
		copy_hitspark_button.connect("pressed", self, "_on_copy_hitspark_pressed")
		$"%HitsparkConfigCopyPasteRow".add_child(copy_hitspark_button)
		paste_hitspark_button = Button.new()
		paste_hitspark_button.text = "paste hitspark"
		paste_hitspark_button.hint_tooltip = "Paste the saved hitspark config."
		paste_hitspark_button.disabled = true
		paste_hitspark_button.connect("pressed", self, "_on_paste_hitspark_pressed")
		$"%HitsparkConfigCopyPasteRow".add_child(paste_hitspark_button)
	if has_node("%HitsparkFlipWhenFacingLeft"):
		$"%HitsparkFlipWhenFacingLeft".connect("toggled", self, "_on_hitspark_flip_when_facing_left_toggled")
	$"%TrailSettings".connect("settings_changed", self, "_on_trail_settings_changed")
	$"%ShowAura".connect("pressed", self, "_on_show_aura_pressed")
	aura_slot_tabs = Tabs.new()
	aura_slot_tabs.theme = preload("res://theme.tres")
	aura_slot_tabs.tab_align = Tabs.ALIGN_LEFT
	aura_slot_tabs.size_flags_horizontal = SIZE_EXPAND_FILL
	for i in range(AURA_SLOT_COUNT):
		aura_slot_tabs.add_tab("Aura %d" % (i + 1))
	aura_slot_tabs.current_tab = 0
	aura_slot_tabs.connect("tab_changed", self, "_on_aura_slot_tab_changed")
	$"%AuraTabsContainer".add_child(aura_slot_tabs)
	copy_aura_button = Button.new()
	copy_aura_button.text = "copy aura"
	copy_aura_button.hint_tooltip = "Copy this aura's settings to the clipboard."
	copy_aura_button.connect("pressed", self, "_on_copy_aura_pressed")
	$"%AuraCopyPasteRow".add_child(copy_aura_button)
	paste_aura_button = Button.new()
	paste_aura_button.text = "paste aura"
	paste_aura_button.hint_tooltip = "Paste the clipboard's aura into this slot (overwrites)."
	paste_aura_button.disabled = true
	paste_aura_button.connect("pressed", self, "_on_paste_aura_pressed")
	$"%AuraCopyPasteRow".add_child(paste_aura_button)
	swap_aura_button = MenuButton.new()
	swap_aura_button.text = "swap with..."
	swap_aura_button.hint_tooltip = "Swap this aura slot's settings with another slot."
	swap_aura_button.get_popup().connect("id_pressed", self, "_on_swap_aura_with_slot")
	$"%AuraCopyPasteRow".add_child(swap_aura_button)
	_refresh_swap_aura_menu()
	$"%SaveButton".connect("pressed", self, "save_style")
	_load_styles()
	_setup_file_manager()
	$"%ExpandAllButton".connect("pressed", self, "_on_expand_all_pressed")
	$"%CollapseAllButton".connect("pressed", self, "_on_collapse_all_pressed")
	$"%FlatViewButton".connect("toggled", self, "_on_flat_view_toggled")
	if has_node("%ClaimButton"):
		$"%ClaimButton".connect("pressed", self, "_on_claim_button_pressed")
	$"%ColorTabs".connect("tab_changed", self, "_on_color_tab_changed")
	call_deferred("_on_color_tab_changed", $"%ColorTabs".current_tab)
	$"%AllowSaveButton".connect("toggled", self, "_on_allow_save_toggled")
	
	
	if !Global.STYLE_SAVE_FEATURE_ENABLED:
		$"%AllowSaveButton".hide()
	else:
		$"%AllowSaveButton".set_pressed_no_signal(Global.allow_save_default)
	if !SteamHustle.WORKSHOP_ENABLED:
		$"%WorkshopButton".disabled = true
	_on_character_button_pressed(buttons[0])
	_on_reset_color_pressed()
	update_warning()


func _on_manage_styles_pressed(_toggled):
	if _toggled:
		$"%ListPanel".show()
		$"%Panel".hide()
		$"%Sorter".show()
		$"%SortInvert".show()
	else:
		$"%ListPanel".hide()
		$"%Panel".show()
		$"%Sorter".hide()
		$"%SortInvert".hide()


func show():
	update_warning()
	.show()
	_on_reset_color_pressed()
	
func save_style(clear_text = false):
	# Apply attribution before snapshotting style data: set creator on a
	# fresh style and append the current user as a modifier when there have
	# been actual edits since loading. Capped at MAX_STYLE_MODIFIERS, with
	# a consecutive-duplicate skip so saving twice in a row doesn't double up.
	var current_user = _current_username()
	var current_id = _current_steam_id()
	if loaded_style_creator == "" and current_user != "":
		loaded_style_creator = current_user
		loaded_style_creator_id = current_id
	if style_modified_since_load and current_user != "":
		# Don't list the creator as a modifier, and don't list any modifier
		# more than once. Strict dedup:
		#   - both sides have a steam_id → match by id (rename-safe)
		#   - both sides lack an id → match by username (legacy / non-steam)
		#   - mismatched id presence → treat as different people (a steam
		#     user can share a name with a legacy entry coincidentally)
		var already_in_chain = false
		if current_id != "" and loaded_style_creator_id != "":
			if current_id == loaded_style_creator_id:
				already_in_chain = true
		elif current_id == "" and loaded_style_creator_id == "":
			if current_user == loaded_style_creator:
				already_in_chain = true
		if !already_in_chain:
			for i in range(loaded_style_modifiers.size()):
				var mid = loaded_style_modifier_ids[i]
				if current_id != "" and mid != "":
					if current_id == mid:
						already_in_chain = true
						break
				elif current_id == "" and mid == "":
					if loaded_style_modifiers[i] == current_user:
						already_in_chain = true
						break
		if !already_in_chain:
			loaded_style_modifiers.append(current_user)
			loaded_style_modifier_ids.append(current_id)
		while loaded_style_modifiers.size() > MAX_STYLE_MODIFIERS:
			loaded_style_modifiers.pop_front()
			if !loaded_style_modifier_ids.empty():
				loaded_style_modifier_ids.pop_front()
	style_modified_since_load = false
	var data = get_style_data()
	Custom.save_style(data)
	_refresh_style_credits_button()
	SteamHustle.unlock_achievement("ACH_STYLISH")
	if data.character_color == Color("0b0c0f"):
		if !data.use_outline or data.outline_color == Color("0b0c0f"):
			SteamHustle.unlock_achievement("ACH_SNEAKY")
	# Pick up a brand-new style file in the toggle list too (no-op if this
	# save just overwrote an existing, already-listed style), and keep the
	# highlight on whichever entry now matches what's loaded.
	_load_styles()
	_set_current_style_selection(data.style_name)
	if clear_text:
		$"%StyleName".clear()
	_set_label_with_ellipsis($"%SavedLabel", "saved as " + data.style_name + ".style")
	$"%SavedLabel".show()

func update_warning():
#	if !Global.full_version():
#		$"%DLCWarning".visible = Custom.requires_dlc(get_style_data())
	pass

func load_style(style):
	if style:
		# Reset attribution caches from the loaded style. Backward compat:
		# legacy styles without the keys default to empty creator and an
		# empty modifiers list — the next save will fill them in.
		loaded_style_creator = style.get("creator", "") if style is Dictionary else ""
		loaded_style_creator_id = ""
		loaded_style_creator_unknown = false
		loaded_style_modifiers = []
		loaded_style_modifier_ids = []
		if style is Dictionary:
			loaded_style_creator_id = str(style.get("creator_id", ""))
			if style.has("modifiers") and style["modifiers"] is Array:
				for n in style["modifiers"]:
					if n is String:
						loaded_style_modifiers.append(n)
			if style.has("modifier_ids") and style["modifier_ids"] is Array:
				for id_val in style["modifier_ids"]:
					loaded_style_modifier_ids.append(str(id_val))
		# Pad the id array with "" so it stays aligned with the username
		# array — older styles only have usernames.
		while loaded_style_modifier_ids.size() < loaded_style_modifiers.size():
			loaded_style_modifier_ids.append("")
		while loaded_style_modifier_ids.size() > loaded_style_modifiers.size():
			loaded_style_modifier_ids.pop_back()
		# Old-version styles (saved before attribution existed) and styles
		# that have been renounced both come in with no creator. Mark them
		# unknown so the claim button can offer to take attribution.
		if loaded_style_creator == "":
			loaded_style_creator = UNKNOWN_CREATOR_NAME
			loaded_style_creator_id = ""
			loaded_style_creator_unknown = true
		# If we recognise our own steam_id anywhere in the chain but the saved
		# username is stale, refresh those entries to the current username.
		# Next save persists the rename.
		var my_id = _current_steam_id()
		var my_user = _current_username()
		if my_id != "" and my_user != "":
			if loaded_style_creator_id == my_id and loaded_style_creator != my_user:
				loaded_style_creator = my_user
			for i in range(loaded_style_modifier_ids.size()):
				if loaded_style_modifier_ids[i] == my_id and loaded_style_modifiers[i] != my_user:
					loaded_style_modifiers[i] = my_user
		# Legacy styles without this field are treated as allowing save.
		# Skipped entirely while the feature is disabled — the button is
		# hidden anyway and the field stops round-tripping through saves.
		if Global.STYLE_SAVE_FEATURE_ENABLED:
			var allow_save = true
			if style is Dictionary:
				allow_save = style.get("allow_others_save", true)
			$"%AllowSaveButton".set_pressed_no_signal(allow_save)
		style_modified_since_load = false
		loading_aura_slot = true
		# Reset all slots, then fill from new "auras" array if present, else
		# from the old aura_settings/aura_settings_2 fields.
		for i in range(AURA_SLOT_COUNT):
			aura_show[i] = false
			aura_settings_cache[i] = null
		if style.has("auras") and style["auras"] is Array:
			var arr = style["auras"]
			for i in range(min(arr.size(), AURA_SLOT_COUNT)):
				var entry = arr[i]
				if entry is Dictionary:
					aura_show[i] = entry.get("show", false)
					aura_settings_cache[i] = entry.get("settings")
		else:
			aura_show[0] = style.get("show_aura", false)
			aura_settings_cache[0] = style.get("aura_settings")
			aura_show[1] = style.get("show_aura_2", false)
			aura_settings_cache[1] = style.get("aura_settings_2")
		current_aura_slot = 0
		if aura_slot_tabs:
			aura_slot_tabs.current_tab = 0
		$"%ShowAura".pressed = aura_show[0]
		if aura_settings_cache[0]:
			$"%TrailSettings".load_settings(aura_settings_cache[0])
		loading_aura_slot = false
		$"%StyleName".text = style.style_name
		_refresh_style_credits_button()
		$"%ShowOutline".pressed = style.use_outline
		if style.use_outline:
			$"%Outline".set_color(style.outline_color)
		if style.get("extra_color_1"):
			$"%Extra1".set_color(style.extra_color_1)
		if style.get("extra_color_2"):
			$"%Extra2".set_color(style.extra_color_2)
		call_deferred("create_all_auras")
		if style.character_color != null:
			$"%Character".set_color(style.character_color)
		# Auto-switch the color tab to Advanced if this style uses anything
		# the Simple presets can't represent (extras set, or a base/outline
		# pair that isn't one of the preset combos).
		if has_node("%ColorTabs"):
			$"%ColorTabs".current_tab = 1 if _style_uses_advanced_colors(style) else 0
		# Restore the custom hitspark sprite pick before deciding which tab to
		# show — so the OptionButton reflects the saved value even if the style
		# is currently a Simple preset.
		var custom_cfg = style.get("custom_hitspark", null) if style is Dictionary else null
		custom_hitspark_particles = [null, null]
		custom_hitspark_show_particles = [false, false]
		if custom_cfg is Dictionary:
			custom_hitspark_sprite = str(custom_cfg.get("sprite", ""))
			var saved_p0 = custom_cfg.get("particles", null)
			if saved_p0 is Dictionary:
				custom_hitspark_particles[0] = saved_p0
			var saved_p1 = custom_cfg.get("particles_2", null)
			if saved_p1 is Dictionary:
				custom_hitspark_particles[1] = saved_p1
			custom_hitspark_show_particles[0] = bool(custom_cfg.get("show_particles", false))
			custom_hitspark_show_particles[1] = bool(custom_cfg.get("show_particles_2", false))
			custom_hitspark_flip_when_facing_left = bool(custom_cfg.get("flip_when_facing_left", false))
		else:
			custom_hitspark_sprite = ""
			custom_hitspark_flip_when_facing_left = false
		current_hitspark_particle_slot = 0
		if hitspark_particle_slot_tabs:
			hitspark_particle_slot_tabs.current_tab = 0
		if has_node("%ShowHitsparkParticles"):
			$"%ShowHitsparkParticles".set_pressed_no_signal(custom_hitspark_show_particles[0])
		if has_node("%HitsparkFlipWhenFacingLeft"):
			$"%HitsparkFlipWhenFacingLeft".set_pressed_no_signal(custom_hitspark_flip_when_facing_left)
		if has_node("%HitsparkSpriteOption"):
			var sprite_idx = Custom.HITSPARK_SPRITE_NAMES.find(custom_hitspark_sprite)
			if sprite_idx == -1:
				sprite_idx = 0
			$"%HitsparkSpriteOption".selected = sprite_idx
		if has_node("%HitsparkParticles"):
			loading_hitspark_particles = true
			var slot0 = custom_hitspark_particles[0]
			$"%HitsparkParticles".load_settings(slot0 if slot0 is Dictionary else _default_hitspark_particles())
			loading_hitspark_particles = false
		var hs = style.hitspark.strip_edges() if style.has("hitspark") else "bash"
		if hs == "custom":
			if has_node("%HitsparkTabs"):
				$"%HitsparkTabs".current_tab = 1
			selected_hitspark = "custom"
			spawn_hitspark()
		else:
			if has_node("%HitsparkTabs"):
				$"%HitsparkTabs".current_tab = 0
			for child in $"%HitsparkButtonContainer".get_children():
				if child.text == hs:
					child.pressed = true
					select_hitspark(hs)
	$"%WorkshopButton".disabled = false

# ---------------------------------------------------------------------------
# Style toggle list - same "named list of on/off items" pattern the mod
# loader uses, applied to ".style" files. Each discovered style gets a
# toggle; whichever ones are ON make up the pool the character-select
# randomizer draws from. FileManagerInterface saves/loads that on/off state
# as named lists, exactly like ModLoaderMenu does for mod lists.
#
# %StyleListContainer is ALSO the only way to pick and load an individual
# style into the editor now (clicking its name button) - there is no
# dropdown involved anywhere in this flow.
# ---------------------------------------------------------------------------

func _setup_file_manager() -> void:
	file_manager.connect("get_data_requested", self, "_on_fm_get_data_requested")
	file_manager.connect("apply_data_requested", self, "_on_fm_apply_data_requested")
	file_manager.connect("get_listed_requested", self, "_on_fm_get_listed_requested")
	file_manager.connect("folder_updated", self, "_on_fm_folder_updated")
	
	# use_game_folder = false: styles live in user://custom, the same
	# folder _on_OpenFolderButton_pressed() already opens - not next to
	# the executable like mods.
	file_manager.setup("custom", PoolStringArray([".style"]), false)
	file_manager.get_node("%Close").hide()
	
	$"%ManageStylesButton".connect("toggled", self, "_open_file_manager")


func _open_file_manager(_toggled) -> void:
	if _toggled:
		file_manager._on_open_pressed()
	else:
		file_manager._on_close_pressed()


# Scans user://custom for ".style" files and adds a toggle entry for each
# one not already known. Safe to call repeatedly - existing entries are
# left untouched.
func _load_styles() -> void:
	var dir = Directory.new()
	if dir.open("user://custom") != OK:
		return
	if dir.list_dir_begin(true, true) != OK:
		return
	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		if dir.current_is_dir():
			continue
		if file_name.get_extension() != "style":
			continue
		add_style_entry("user://custom".plus_file(file_name))
	dir.list_dir_end()


# Cycles the sort mode NAME -> DATE -> ACTIVE -> NAME and reorders the style
# list, mirroring ModLoaderMenu's _on_sorter_pressed.
func _on_style_sorter_pressed() -> void:
	match cur_style_sort:
		FileManager.SortMode.NAME:
			cur_style_sort = FileManager.SortMode.DATE
			$"%Sorter".text = "Sort: Date"
		FileManager.SortMode.DATE:
			cur_style_sort = FileManager.SortMode.ACTIVE
			$"%Sorter".text = "Sort: Active"
		FileManager.SortMode.ACTIVE:
			cur_style_sort = FileManager.SortMode.NAME
			$"%Sorter".text = "Sort: Name"
	_sort_style_buttons()


func _on_style_sort_invert_toggled(toggled: bool) -> void:
	cur_style_inverted = toggled
	_sort_style_buttons()


func _sort_style_buttons() -> void:
	var items := []
	for style_entry in styles.values():
		items.append({
			"name": style_entry.button.text,
			"active": style_entry.active,
			"path": style_entry.path,
			"parent": style_entry.parent,
		})
	items = FileManager.sort_items(items, cur_style_sort, cur_style_inverted)
	for i in range(items.size()):
		$"%StyleListContainer".move_child(items[i].parent, i)


# Creates the name button + on/off toggle for one style file, mirroring
# add_mod()'s button/toggle pair but without any zip/info-tab machinery -
# a style is just a name and a path.
func add_style_entry(path: String) -> void:
	var style_name = path.get_file().get_basename()
	if styles.has(style_name):
		return

	var _container = HBoxContainer.new()
	_container.set_h_size_flags(3)
	_container.set_v_size_flags(1)
	_container.name = style_name

	var btn = generateButton(style_name)
	var toggle = generateButton("", false, 1)

	_container.add_child(btn, true)
	_container.add_child(toggle, true)
	$"%StyleListContainer".add_child(_container)

	btn.connect("pressed", self, "_on_style_button_pressed", [path])
	toggle.connect("toggled", self, "_on_style_toggle_pressed", [style_name, toggle, btn])

	styles[style_name] = {
		"active": true,
		"path": path,
		"toggle": toggle,
		"button": btn,
		"parent": _container,
	}
	_set_style_toggle_state(true, style_name, toggle, btn)


func generateButton(text_gen, _is_button = true, _h_size_flag: int = 3, _v_size_flag: int = 1):
	var _button = Button.new() if _is_button else CheckButton.new()
	_button.text = text_gen
	_button.flat = true
	_button.set("mouse_default_cursor_shape", 2) #CURSOR_POINTING_HAND
	_button.set("custom_colors/font_color_hover", Color(100.0, 0.2, 0.23, 1.0))
	_button.set_h_size_flags(_h_size_flag)
	_button.set_v_size_flags(_v_size_flag)
	_button.add_color_override("font_color", Color("ffffff"))
	return _button

# Clicking a style's name loads its full contents into the editor - this is
# now the ONLY place style selection/loading happens from.
func _on_style_button_pressed(path: String) -> void:
	var data = _read_style_file(path)
	if data.empty():
		return
	load_style(data)
	_set_current_style_selection(path.get_file().get_basename())


# Highlights whichever %StyleListContainer entry is currently loaded into
# the editor, clearing the highlight off the previous one. Purely visual -
# doesn't touch the on/off toggle state.
func _set_current_style_selection(style_name: String) -> void:
	if styles.has(current_style_name):
		styles[current_style_name].button.add_color_override("font_color", Color("ffffff"))
	current_style_name = style_name
	if styles.has(current_style_name):
		styles[current_style_name].button.add_color_override("font_color", Color("55ff55"))


# Signal handler for a human clicking a toggle - the only path that should
# persist anything. Saves the change to whichever named list is currently
# selected in the file manager (or "unnamed" if none is selected), same
# as the mod loader's _on_toggle_pressed.
func _on_style_toggle_pressed(_button_pressed: bool, style_name: String, toggle: CheckButton, button: Button) -> void:
	_set_style_toggle_state(_button_pressed, style_name, toggle, button)
	var idx = file_manager.option_button.selected
	if idx >= 0 and idx < file_manager.loaded_lists.size():
		file_manager.save_current_list(file_manager.loaded_lists[idx].list_name)
	else:
		file_manager.save_current_list("")


# Pure UI/state sync - no saving. Safe to call from add_style_entry()
# (initial setup) and apply_new_style_list() (restoring saved state).
func _set_style_toggle_state(_button_pressed: bool, style_name: String, toggle: CheckButton, button: Button) -> void:
	if !styles.has(style_name):
		return
	styles[style_name].active = _button_pressed
	toggle.set_pressed_no_signal(_button_pressed)


func get_current_style_list(_default: bool = false) -> Dictionary:
	var _saved_active_list := []
	var _saved_inactive_list := []

	for style_name in styles:
		if _default:
			_saved_active_list.append(style_name)
		elif styles[style_name].active:
			_saved_active_list.append(style_name)
		else:
			_saved_inactive_list.append(style_name)

	return {"active": _saved_active_list, "inactive": _saved_inactive_list}


func apply_new_style_list(list: Dictionary) -> void:
	for style_name in styles:
		var entry = styles[style_name]
		if style_name in list.active:
			_set_style_toggle_state(true, style_name, entry.toggle, entry.button)
		elif style_name in list.inactive:
			_set_style_toggle_state(false, style_name, entry.toggle, entry.button)


# Resolves a saved list's "active" names into actual ".style" file paths -
# this is what the character-select randomizer should read (via
# get_listed_requested) to know which files it can pick from.
func get_listed_styles(list: Dictionary) -> Array:
	var _items = []
	for style_name in styles:
		if style_name in list.active:
			_items.append(styles[style_name].path)
	return _items


# Reads a ".style" file straight off disk. Styles are saved with
# store_var (see Custom.save_style) rather than JSON, and allow_objects
# is left at its default false - never load arbitrary Objects from a
# style file.
func _read_style_file(path: String) -> Dictionary:
	var f = File.new()
	if f.open(path, File.READ) != OK:
		return {}
	var data = f.get_var()
	f.close()
	if data is Dictionary:
		return data
	return {}


func _on_fm_get_data_requested(use_default: bool, result: Dictionary) -> void:
	result["data"] = get_current_style_list(use_default)


func _on_fm_apply_data_requested(data: Dictionary) -> void:
	apply_new_style_list(data)


func _on_fm_get_listed_requested(list_data: Dictionary, result: Dictionary) -> void:
	result["paths"] = PoolStringArray(get_listed_styles(list_data))


func _on_fm_folder_updated(path: String) -> void:
	add_style_entry(path)

func select_hitspark(hitspark_name):
	if selected_hitspark != hitspark_name:
		_mark_style_modified()
	selected_hitspark = hitspark_name
	spawn_hitspark()
	update_warning()

func spawn_hitspark():
	if is_instance_valid(hitspark_scene):
		hitspark_scene.queue_free()
		hitspark_scene = null
	if selected_hitspark == "custom":
		var packed = Custom.make_custom_hitspark_scene(get_custom_hitspark_config())
		if packed:
			hitspark_scene = packed.instance()
			# Set custom_config BEFORE add_child so CustomHitEffect.gd picks
			# it up in _ready.
			hitspark_scene.set("custom_config", get_custom_hitspark_config())
			$"%HitsparkDisplay".add_child(hitspark_scene)
	elif Custom.hitsparks.has(selected_hitspark):
		hitspark_scene = load(Custom.hitsparks[selected_hitspark]).instance()
		$"%HitsparkDisplay".add_child(hitspark_scene)

func get_custom_hitspark_config() -> Dictionary:
	return {
		"sprite": custom_hitspark_sprite,
		"show_particles": custom_hitspark_show_particles[0],
		"particles": custom_hitspark_particles[0],
		"show_particles_2": custom_hitspark_show_particles[1],
		"particles_2": custom_hitspark_particles[1],
		"flip_when_facing_left": custom_hitspark_flip_when_facing_left,
	}

func save_current_hitspark_particle_slot():
	if loading_hitspark_particle_slot:
		return
	if !has_node("%HitsparkParticles"):
		return
	var slot = current_hitspark_particle_slot
	custom_hitspark_particles[slot] = $"%HitsparkParticles".get_settings()
	if has_node("%ShowHitsparkParticles"):
		custom_hitspark_show_particles[slot] = $"%ShowHitsparkParticles".pressed

func switch_hitspark_particle_slot(slot):
	save_current_hitspark_particle_slot()
	current_hitspark_particle_slot = posmod(slot, HITSPARK_PARTICLE_SLOT_COUNT)
	loading_hitspark_particle_slot = true
	if has_node("%ShowHitsparkParticles"):
		$"%ShowHitsparkParticles".set_pressed_no_signal(custom_hitspark_show_particles[current_hitspark_particle_slot])
	if has_node("%HitsparkParticles"):
		loading_hitspark_particles = true
		var s = custom_hitspark_particles[current_hitspark_particle_slot]
		$"%HitsparkParticles".load_settings(s if s is Dictionary else _default_hitspark_particles())
		loading_hitspark_particles = false
	loading_hitspark_particle_slot = false
	if hitspark_particle_slot_tabs:
		hitspark_particle_slot_tabs.current_tab = current_hitspark_particle_slot
	spawn_hitspark()

func _on_hitspark_particle_slot_tab_changed(tab):
	switch_hitspark_particle_slot(tab)

func _on_copy_hitspark_particles_pressed():
	save_current_hitspark_particle_slot()
	var slot_settings = custom_hitspark_particles[current_hitspark_particle_slot]
	if slot_settings is Dictionary:
		hitspark_particles_clipboard = slot_settings.duplicate(true)
		if paste_hitspark_particles_button:
			paste_hitspark_particles_button.disabled = false

func _on_paste_hitspark_particles_pressed():
	if !(hitspark_particles_clipboard is Dictionary):
		return
	loading_hitspark_particle_slot = true
	custom_hitspark_particles[current_hitspark_particle_slot] = hitspark_particles_clipboard.duplicate(true)
	custom_hitspark_show_particles[current_hitspark_particle_slot] = true
	if has_node("%ShowHitsparkParticles"):
		$"%ShowHitsparkParticles".set_pressed_no_signal(true)
	if has_node("%HitsparkParticles"):
		loading_hitspark_particles = true
		$"%HitsparkParticles".load_settings(custom_hitspark_particles[current_hitspark_particle_slot])
		loading_hitspark_particles = false
	loading_hitspark_particle_slot = false
	_mark_style_modified()
	selected_hitspark = "custom"
	spawn_hitspark()
	update_warning()

func _on_swap_hitspark_particles_pressed():
	# Save current UI state into the active slot first, then swap the two
	# slots in-place and reload the current slot's view from the (now-
	# swapped) cache.
	save_current_hitspark_particle_slot()
	var tmp_settings = custom_hitspark_particles[0]
	var tmp_show = custom_hitspark_show_particles[0]
	custom_hitspark_particles[0] = custom_hitspark_particles[1]
	custom_hitspark_show_particles[0] = custom_hitspark_show_particles[1]
	custom_hitspark_particles[1] = tmp_settings
	custom_hitspark_show_particles[1] = tmp_show
	loading_hitspark_particle_slot = true
	if has_node("%ShowHitsparkParticles"):
		$"%ShowHitsparkParticles".set_pressed_no_signal(custom_hitspark_show_particles[current_hitspark_particle_slot])
	if has_node("%HitsparkParticles"):
		loading_hitspark_particles = true
		var s = custom_hitspark_particles[current_hitspark_particle_slot]
		$"%HitsparkParticles".load_settings(s if s is Dictionary else _default_hitspark_particles())
		loading_hitspark_particles = false
	loading_hitspark_particle_slot = false
	_mark_style_modified()
	spawn_hitspark()
	update_warning()

func _on_copy_hitspark_pressed():
	hitspark_clipboard = get_custom_hitspark_config().duplicate(true)
	if paste_hitspark_button:
		paste_hitspark_button.disabled = false

func _on_paste_hitspark_pressed():
	if !(hitspark_clipboard is Dictionary):
		return
	loading_hitspark_particle_slot = true
	custom_hitspark_sprite = str(hitspark_clipboard.get("sprite", ""))
	custom_hitspark_flip_when_facing_left = bool(hitspark_clipboard.get("flip_when_facing_left", false))
	custom_hitspark_particles = [null, null]
	custom_hitspark_show_particles = [false, false]
	var p0 = hitspark_clipboard.get("particles", null)
	if p0 is Dictionary:
		custom_hitspark_particles[0] = p0.duplicate(true)
	var p1 = hitspark_clipboard.get("particles_2", null)
	if p1 is Dictionary:
		custom_hitspark_particles[1] = p1.duplicate(true)
	custom_hitspark_show_particles[0] = bool(hitspark_clipboard.get("show_particles", false))
	custom_hitspark_show_particles[1] = bool(hitspark_clipboard.get("show_particles_2", false))
	current_hitspark_particle_slot = 0
	if hitspark_particle_slot_tabs:
		hitspark_particle_slot_tabs.current_tab = 0
	if has_node("%ShowHitsparkParticles"):
		$"%ShowHitsparkParticles".set_pressed_no_signal(custom_hitspark_show_particles[0])
	if has_node("%HitsparkFlipWhenFacingLeft"):
		$"%HitsparkFlipWhenFacingLeft".set_pressed_no_signal(custom_hitspark_flip_when_facing_left)
	if has_node("%HitsparkSpriteOption"):
		var sprite_idx = Custom.HITSPARK_SPRITE_NAMES.find(custom_hitspark_sprite)
		if sprite_idx == -1:
			sprite_idx = 0
		$"%HitsparkSpriteOption".selected = sprite_idx
	if has_node("%HitsparkParticles"):
		loading_hitspark_particles = true
		var slot0 = custom_hitspark_particles[0]
		$"%HitsparkParticles".load_settings(slot0 if slot0 is Dictionary else _default_hitspark_particles())
		loading_hitspark_particles = false
	loading_hitspark_particle_slot = false
	if has_node("%HitsparkTabs"):
		$"%HitsparkTabs".current_tab = 1
	selected_hitspark = "custom"
	_mark_style_modified()
	spawn_hitspark()
	update_warning()

# Default particle settings used when a style first switches to the custom
# hitspark and there's nothing saved yet. Hitsparks are bursts, so default
# explosiveness is 1 (vs auras' default 0). `in_front` flips to true so the
# particles render in front of the AnimatedSprite — auras default to behind
# the character, but for hitsparks the sprite is the centerpiece and
# particles read better layered on top.
func _default_hitspark_particles() -> Dictionary:
	var d = CustomTrailParticle.get_default()
	d["explosiveness"] = 1.0
	d["in_front"] = true
	return d

func _on_custom_hitspark_sprite_selected(idx):
	if idx < 0 or idx >= Custom.HITSPARK_SPRITE_NAMES.size():
		return
	var new_sprite = Custom.HITSPARK_SPRITE_NAMES[idx]
	if custom_hitspark_sprite != new_sprite:
		_mark_style_modified()
	custom_hitspark_sprite = new_sprite
	# Switching the sprite also implies the user is on the custom hitspark
	# now — flip selected_hitspark to "custom" so save_style writes it out.
	selected_hitspark = "custom"
	spawn_hitspark()
	update_warning()

func _on_hitspark_particles_changed(settings):
	if loading_hitspark_particles or loading_hitspark_particle_slot:
		return
	custom_hitspark_particles[current_hitspark_particle_slot] = settings
	_mark_style_modified()
	# Touching the particle editor implies the user is on the custom hitspark.
	selected_hitspark = "custom"
	spawn_hitspark()
	update_warning()

func _on_show_hitspark_particles_toggled(on):
	if loading_hitspark_particle_slot:
		return
	if custom_hitspark_show_particles[current_hitspark_particle_slot] == on:
		return
	custom_hitspark_show_particles[current_hitspark_particle_slot] = on
	_mark_style_modified()
	selected_hitspark = "custom"
	spawn_hitspark()
	update_warning()

func _on_hitspark_flip_when_facing_left_toggled(on):
	if custom_hitspark_flip_when_facing_left == on:
		return
	custom_hitspark_flip_when_facing_left = on
	_mark_style_modified()
	selected_hitspark = "custom"
	spawn_hitspark()

func _on_hitspark_tab_changed(tab):
	# Tab 0 = Simple (one of the named presets), tab 1 = Advanced (custom).
	# Switching tabs alone shouldn't dirty the style; flipping the active
	# hitspark to match is enough.
	if tab == 1:
		selected_hitspark = "custom"
	else:
		# Fall back to a reasonable default if leaving the custom tab and the
		# active selection wasn't a real preset.
		if selected_hitspark == "custom":
			selected_hitspark = "bash"
	spawn_hitspark()

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
	# Bail entirely during a slot load. load_settings fires value_changed
	# on every control as it pushes the cached dict back in (~50+ signals
	# in a row), and each one used to re-run get_settings() + queue an
	# aura rebuild — the source of the tab-switch lag. switch_aura_slot
	# already calls create_all_auras once at the end.
	if loading_aura_slot:
		return
	_mark_style_modified()
	save_current_aura_slot()
	call_deferred("create_all_auras")
	update_warning()

func _on_show_aura_pressed():
	if loading_aura_slot:
		return
	_mark_style_modified()
	save_current_aura_slot()
	call_deferred("create_all_auras")
	update_warning()

func _on_aura_slot_tab_changed(slot):
	switch_aura_slot(slot)

func _on_copy_aura_pressed():
	save_current_aura_slot()
	if aura_settings_cache[current_aura_slot] is Dictionary:
		aura_clipboard = aura_settings_cache[current_aura_slot].duplicate(true)
		paste_aura_button.disabled = false

func _on_paste_aura_pressed():
	if !(aura_clipboard is Dictionary):
		return
	loading_aura_slot = true
	aura_settings_cache[current_aura_slot] = aura_clipboard.duplicate(true)
	aura_show[current_aura_slot] = true
	$"%ShowAura".pressed = true
	$"%TrailSettings".load_settings(aura_settings_cache[current_aura_slot])
	loading_aura_slot = false
	create_all_auras()

# Rebuild the swap dropdown to list every other slot — called whenever
# the current slot changes so the menu always excludes "this one".
func _refresh_swap_aura_menu():
	if swap_aura_button == null:
		return
	var menu = swap_aura_button.get_popup()
	menu.clear()
	for i in range(AURA_SLOT_COUNT):
		if i == current_aura_slot:
			continue
		menu.add_item("Aura %d" % (i + 1), i)

func _on_swap_aura_with_slot(other_slot: int):
	if other_slot == current_aura_slot or other_slot < 0 or other_slot >= AURA_SLOT_COUNT:
		return
	save_current_aura_slot()
	var tmp_settings = aura_settings_cache[current_aura_slot]
	var tmp_show = aura_show[current_aura_slot]
	aura_settings_cache[current_aura_slot] = aura_settings_cache[other_slot]
	aura_show[current_aura_slot] = aura_show[other_slot]
	aura_settings_cache[other_slot] = tmp_settings
	aura_show[other_slot] = tmp_show
	loading_aura_slot = true
	$"%ShowAura".pressed = aura_show[current_aura_slot]
	if aura_settings_cache[current_aura_slot] is Dictionary:
		$"%TrailSettings".load_settings(aura_settings_cache[current_aura_slot])
	else:
		$"%TrailSettings".load_settings(CustomTrailParticle.get_default())
	loading_aura_slot = false
	_mark_style_modified()
	create_all_auras()

func create_all_auras():
	for particle in custom_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	custom_particles.clear()
	var entries := []
	for slot in range(AURA_SLOT_COUNT):
		entries.append({"show": aura_show[slot], "settings": aura_settings_cache[slot]})
	for expanded in Custom.expand_aura_entries(entries):
		var settings = expanded["settings"]
		var attach_limb = expanded["attach_limb"]
		var pair_index = expanded["pair_index"]
		var resolved_limb = Custom.resolve_attach_limb(expanded)
		var position_only = settings.get("attach_position_only", true)
		var mirror_pair = settings.get("attach_pair_mirror", true)
		for node in [$"%MovingSprite", $"%StaticSprite"]:
			var entry = _preview_limb_entry(node, resolved_limb) if attach_limb != "" else null
			# Skip entirely when an attached aura's limb has no data on this
			# preview sprite, so the aura doesn't appear at the wrong spot.
			if attach_limb != "" and entry == null:
				continue
			var particle = preload("res://fx/CustomTrailParticle.tscn").instance()
			node.add_child(particle)
			custom_particles.append(particle)
			particle.load_settings(settings)
			if attach_limb != "":
				particle.position = _preview_aura_pos_from_entry(node, entry)
				# Eyes: fold per-eye spacing/y into default_x/y_offset so
				# it rides the rotation pipeline (mirrors BaseChar). Set
				# from the saved base offset; never += or it accumulates.
				if attach_limb == "Eyes":
					var spacing = float(settings.get("attach_eye_spacing", 6))
					var x_eye = -spacing * 0.5 if pair_index == 0 else spacing * 0.5
					var y_eye = float(settings.get("attach_eye_left_y_offset", 0)) if pair_index == 0 else float(settings.get("attach_eye_right_y_offset", 0))
					particle.default_x_offset = float(settings.get("x_offset", 0)) + x_eye
					particle.default_y_offset = float(settings.get("y_offset", 0)) + y_eye
				particle.attached_to_limb = true
				if position_only:
					particle.attached_rotation = 0.0
					particle.attached_limb_flipped = false
				else:
					particle.attached_rotation = _preview_aura_rotation_from_entry(entry)
					var flipped = entry.get("flipped", false)
					if pair_index == 1 and mirror_pair:
						flipped = !flipped
					particle.attached_limb_flipped = flipped
					# See BaseChar — eyes' second particle gets the texture
					# flip from pair_mirror, but the scale.x = -1 would also
					# invert the user's global x_offset. Pre-negate it on
					# this particle so the offset cancels back to matching
					# direction with the first eye.
					if attach_limb == "Eyes" and pair_index == 1 and mirror_pair:
						particle.default_x_offset = -particle.default_x_offset
				particle.facing = 1
			else:
				particle.position = Vector2()

# Returns the limb entry for the given sprite, or null if there's no usable
# data on this sprite (no entry at all, or marked absent).
func _preview_limb_entry(sprite_node: Sprite, limb_name: String):
	if limb_name == "" or current_character_limb_data.empty():
		return null
	if !current_character_limb_data.has(limb_name):
		return null
	var by_tex = current_character_limb_data[limb_name]
	if !by_tex.has(sprite_node.texture):
		return null
	var entry = by_tex[sprite_node.texture]
	if entry is Dictionary and entry.get("absent", false):
		return null
	return entry

func _preview_aura_pos_from_entry(sprite_node: Sprite, entry) -> Vector2:
	var local = Vector2(entry.x, entry.y)
	if sprite_node.centered:
		local -= sprite_node.texture.get_size() / 2
	if "offset" in sprite_node:
		local += sprite_node.offset
	return local

func _preview_aura_rotation_from_entry(entry) -> float:
	var dir = Vector2(entry.dir_x, entry.dir_y)
	if dir.length_squared() < 0.0001:
		return 0.0
	return dir.angle()

func _on_back_button_pressed():
	Global.reload()

func _on_expand_all_pressed():
	_set_all_sections_expanded(true)

func _on_collapse_all_pressed():
	_set_all_sections_expanded(false)

func _on_flat_view_toggled(on):
	for section in _all_collapsible_sections(self):
		section.set_flat_mode(on)

# TabContainer's min size is the max of its children's min sizes, which
# means Simple inherits Advanced's height. Resize the container to the active
# tab's actual content size on tab_changed so Simple shrinks down.
func _on_color_tab_changed(_tab):
	var tabs = $"%ColorTabs"
	var idx = tabs.current_tab
	if idx < 0:
		return
	var visible_count = 0
	for c in tabs.get_children():
		if c is Control:
			if visible_count == idx:
				tabs.rect_min_size.y = c.get_combined_minimum_size().y + 16
				return
			visible_count += 1

func _set_all_sections_expanded(on):
	for section in _all_collapsible_sections(self):
		section.set_expanded(on)

func _all_collapsible_sections(root) -> Array:
	var out := []
	for child in root.get_children():
		if child is CollapsibleSection:
			out.append(child)
		out.append_array(_all_collapsible_sections(child))
	return out

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
	if character_color != color:
		_mark_style_modified()
	character_color = color
	update_warning()

func _on_extra_color_1_changed(color):
	$"%StaticSprite".get_material().set_shader_param("extra_color_1", color)
	if extra_color_1 != color:
		_mark_style_modified()
	extra_color_1 = color
	update_warning()

func _on_extra_color_2_changed(color):
	$"%StaticSprite".get_material().set_shader_param("extra_color_2", color)
	if extra_color_2 != color:
		_mark_style_modified()
	extra_color_2 = color
	update_warning()

func _on_outline_color_changed(color):
	$"%ShowOutline".set_pressed_no_signal(true)
	$"%StaticSprite".get_material().set_shader_param("outline_color", color)
	$"%StaticSprite".get_material().set_shader_param("use_outline", true)
#	$"%MovingSprite".get_material().set_shader_param("color", color)
	if outline_color != color:
		_mark_style_modified()
	outline_color = color
	update_warning()

func _on_show_outline_toggled(on):
	_mark_style_modified()
	$"%StaticSprite".get_material().set_shader_param("use_outline", on)
	$"%ShowOutline".set_pressed_no_signal(on)
	update_warning()

func _on_allow_save_toggled(pressed):
	Global.allow_save_default = pressed
	Global.save_options()
	_mark_style_modified()

func _on_character_button_pressed(button):
	for button in buttons:
		button.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)
	var character: Fighter = button.character_scene.instance()
	add_child(character)
	$"%StaticSprite".material = character.sprite.material
	$"%MovingSprite".material = character.sprite.material
	var character_texture = character.sprite.frames.get_frame("Wait", 0)
	var character_texture2 = character.character_portrait2
	$"%StaticSprite".get_material().set_shader_param("use_extra_color_1", character.use_extra_color_1)
	$"%StaticSprite".get_material().set_shader_param("use_extra_color_2", character.use_extra_color_2)
	$"%StaticSprite".get_material().set_shader_param("extra_replace_color_1", character.extra_color_1)
	$"%StaticSprite".get_material().set_shader_param("extra_replace_color_2", character.extra_color_2)
	$"%StaticSprite".texture = character_texture
	$"%MovingSprite".texture = character_texture2 if character_texture2 != null else character_texture
	current_character_limb_data = character.get_limb_data() if character.has_method("get_limb_data") else {}
	character.free()
	# Re-push the user's current color state onto the freshly-assigned
	# material — the new material starts with default shader params, so
	# without this the previously-applied color/outline visibly resets
	# on every character switch.
	var mat = $"%StaticSprite".get_material()
	mat.set_shader_param("color", character_color if character_color != null else Color.white)
	mat.set_shader_param("extra_color_1", extra_color_1 if extra_color_1 != null else Color.white)
	mat.set_shader_param("extra_color_2", extra_color_2 if extra_color_2 != null else Color.white)
	mat.set_shader_param("outline_color", outline_color)
	mat.set_shader_param("use_outline", $"%ShowOutline".pressed)
	create_all_auras()

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
	# Publishing to workshop implies sharing — force the toggle on so both
	# the local save and the uploaded copy carry allow_others_save = true.
	# Use no_signal so Global.allow_save_default isn't overwritten.
	if Global.STYLE_SAVE_FEATURE_ENABLED:
		$"%AllowSaveButton".set_pressed_no_signal(true)
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
	_populate_style_credits()


func _on_WorkshopUpdatedLabel_meta_clicked(meta):
	OS.shell_open(meta)
	pass # Replace with function body.


func _on_WorkshopButton2_pressed():
#	OS.shell_open("https://steamcommunity.com/app/2212330/workshop/")
	Steam.activateGameOverlayToWebPage("https://steamcommunity.com/app/2212330/workshop/")
	pass # Replace with function body.

# ---- Style attribution ----

# Sets a Label's text, truncating with "..." if it would overflow the
# label's rect width. Godot 3's Label has no native ellipsis behavior.
func _set_label_with_ellipsis(label: Label, text: String):
	label.clip_text = true
	var font = label.get_font("font")
	var available = label.rect_size.x
	if font == null or available <= 0 or font.get_string_size(text).x <= available:
		label.text = text
		return
	var ellipsis = "..."
	var ellipsis_w = font.get_string_size(ellipsis).x
	var truncated = text
	while truncated.length() > 0 and font.get_string_size(truncated).x + ellipsis_w > available:
		truncated = truncated.substr(0, truncated.length() - 1)
	label.text = truncated + ellipsis

func _current_username() -> String:
	if SteamHustle.STARTED and SteamHustle.STEAM_ID:
		var steam_name = Steam.getFriendPersonaName(SteamHustle.STEAM_ID)
		if steam_name is String and steam_name != "":
			return steam_name
	var pd = Global.get_player_data()
	if pd is Dictionary:
		var u = pd.get("username", "")
		if u is String:
			return u
	return ""

# The local user's steam_id as a string, or "" if the build isn't running
# under steam (or the id hasn't been resolved yet).
func _current_steam_id() -> String:
	var sid = SteamHustle.STEAM_ID
	if sid != null and typeof(sid) == TYPE_INT and sid > 0:
		return str(sid)
	return ""

func _mark_style_modified(_arg=null, _arg2=null):
	style_modified_since_load = true

# Refresh the inline style-credits scroll. Called whenever load_style or
# save_style changes the cached creator/modifiers — keeps the panel in sync
# with whichever style is currently loaded.
func _refresh_style_credits_button():
	_populate_style_credits()
	_refresh_claim_button()

# A style uses "advanced" colors if it has either extra slot set, or a
# character/outline combo that isn't one of the preset pairs in
# Custom.simple_colors / Custom.simple_outlines. Used to auto-pick the
# right color tab when loading.
func _style_uses_advanced_colors(style) -> bool:
	if !(style is Dictionary):
		return false
	if style.get("extra_color_1") != null:
		return true
	if style.get("extra_color_2") != null:
		return true
	var char_color = style.get("character_color")
	if char_color != null and Custom.is_color_dlc(char_color):
		return true
	if style.get("use_outline", false):
		var outline_color = style.get("outline_color")
		if outline_color != null and Custom.is_outline_dlc(outline_color):
			return true
		if char_color != null and outline_color != null and not Custom.is_combo_simple(char_color, outline_color):
			return true
	return false

# True iff the local user matches the cached creator. Match by steam_id when
# both sides have one (rename-safe), else fall back to username. Returns false
# for unknown-flagged styles so the claim button can offer to take attribution.
func _is_self_creator() -> bool:
	if loaded_style_creator_unknown:
		return false
	var current_user = _current_username()
	var current_id = _current_steam_id()
	if current_id != "" and loaded_style_creator_id != "":
		return current_id == loaded_style_creator_id
	if current_id == "" and loaded_style_creator_id == "":
		return current_user != "" and current_user == loaded_style_creator
	return false

# Strip the local user out of the modifiers list (matched by steam_id when
# both sides have one, else by name). Used when claiming, so the user doesn't
# end up listed as both creator and modifier.
func _remove_self_from_modifiers():
	var current_user = _current_username()
	var current_id = _current_steam_id()
	for i in range(loaded_style_modifiers.size() - 1, -1, -1):
		var mod_name = loaded_style_modifiers[i]
		var mod_id = loaded_style_modifier_ids[i] if i < loaded_style_modifier_ids.size() else ""
		var match_self = false
		if current_id != "" and mod_id != "":
			match_self = (mod_id == current_id)
		elif current_id == "" and mod_id == "":
			match_self = (current_user != "" and mod_name == current_user)
		if match_self:
			loaded_style_modifiers.remove(i)
			if i < loaded_style_modifier_ids.size():
				loaded_style_modifier_ids.remove(i)

# Append the local user to the modifiers list iff they aren't already in it.
# Used when renouncing — the renounced creator moves to the modifiers list
# instead of disappearing entirely.
func _add_self_to_modifiers():
	var current_user = _current_username()
	var current_id = _current_steam_id()
	if current_user == "":
		return
	for i in range(loaded_style_modifiers.size()):
		var mod_name = loaded_style_modifiers[i]
		var mod_id = loaded_style_modifier_ids[i] if i < loaded_style_modifier_ids.size() else ""
		if current_id != "" and mod_id != "":
			if mod_id == current_id:
				return
		elif current_id == "" and mod_id == "":
			if mod_name == current_user:
				return
	loaded_style_modifiers.append(current_user)
	loaded_style_modifier_ids.append(current_id)

func _on_claim_button_pressed():
	if loaded_style_creator_unknown:
		# Claim: take attribution. Bail if the local user can't be identified
		# — there's nothing meaningful to write into the creator slot.
		# Deliberately leaves style_modified_since_load alone: claiming is a
		# metadata-only act, not a content edit. If the user then renounces
		# without making real changes, the gate in the renounce branch keeps
		# them out of the modifiers list.
		var current_user = _current_username()
		if current_user == "":
			return
		_remove_self_from_modifiers()
		loaded_style_creator = current_user
		loaded_style_creator_id = _current_steam_id()
		loaded_style_creator_unknown = false
	elif _is_self_creator():
		# Renounce: drop yourself from the creator slot. Only step down into
		# the modifiers list if there were actual edits since loading —
		# a pure renounce with no other changes leaves nothing of yourself
		# behind. The auto-append-as-modifier in save_style is gated on
		# style_modified_since_load, so leaving the flag alone (instead of
		# forcing it true) lets a clean renounce save without re-adding self.
		if style_modified_since_load:
			_add_self_to_modifiers()
		loaded_style_creator = UNKNOWN_CREATOR_NAME
		loaded_style_creator_id = ""
		loaded_style_creator_unknown = true
	else:
		# Safeguard: button shouldn't be visible in this state, but if it is
		# (e.g. raced with a load), do nothing — never let one user reassign
		# someone else's authorship.
		return
	_refresh_style_credits_button()

# Show "claim authorship" when the style is unattributed, "renounce
# authorship" when the local user is the creator, and hide the button
# otherwise. Right-edge stays pinned at CLAIM_BUTTON_RIGHT_EDGE — only the
# left edge moves to absorb the new text width.
func _refresh_claim_button():
	if !has_node("%ClaimButton"):
		return
	var btn = $"%ClaimButton"
	if loaded_style_creator_unknown:
		btn.text = "claim authorship"
		btn.visible = _current_username() != ""
	elif _is_self_creator():
		btn.text = "renounce authorship"
		btn.visible = true
	else:
		btn.visible = false
		return
	btn.margin_right = CLAIM_BUTTON_RIGHT_EDGE
	btn.margin_left = CLAIM_BUTTON_RIGHT_EDGE - btn.get_combined_minimum_size().x

func _populate_style_credits():
	if !has_node("%StyleCreditsList"):
		return
	var list = $"%StyleCreditsList"
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var style_name = ""
	if has_node("%StyleName"):
		style_name = $"%StyleName".text.strip_edges()
	if style_name != "":
		var title = _make_credits_label(style_name)
		title.add_color_override("font_color", Color.cyan)
		list.add_child(title)
	if loaded_style_creator != "":
		list.add_child(_make_credits_label("created by", true))
		list.add_child(_make_credits_label(loaded_style_creator))
	if !loaded_style_modifiers.empty():
		list.add_child(_make_credits_label("modified by", true))
		# Render most-recent first.
		for i in range(loaded_style_modifiers.size() - 1, -1, -1):
			list.add_child(_make_credits_label(loaded_style_modifiers[i]))

func _make_credits_label(text: String, dim: bool = false) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.align = Label.ALIGN_CENTER
	lbl.autowrap = true
	lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	if dim:
		lbl.modulate = Color(1, 1, 1, 0.6)
	return lbl
