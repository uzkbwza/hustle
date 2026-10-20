extends MarginContainer

export var steam = false

var singleplayer = true
var init = false

var loaded_formats = []
var selected_format = ""
# Snapshotted at the very top of _ready, before any code or signals can mutate
# the panel's nodes. Picking "default" in the dropdown re-applies these scene
# values regardless of what's on disk — saving over default.gameformat doesn't
# permanently rebrand "default" as the user's custom setup.
var scene_defaults = {}

const TIMER_MODES = ["default", "none", "chess", "increment"]

onready var settings_nodes = {
	"stage_width": $"%StageWidth",
	"p2_dummy": $"%P2Dummy",
	"di_enabled": $"%DIEnabled",
	"prorated_di": $"%ProratedDI",
	"turbo_mode": $"%TurboMode",
	"infinite_resources": $"%InfiniteResources",
	"one_hit_ko": $"%OneHitKO",
	"game_length": $"%GameLength",
	"turn_time": $"%TurnLength",
	"burst_enabled": $"%BurstEnabled",
	"frame_by_frame": $"%FrameByFrame",
	"always_perfect_parry": $"%AlwaysPerfectParry",
	"char_distance": $"%CharDist",
	"char_height": $"%CharHeight",
	"gravity_enabled": $"%GravityEnabled",
	"timer_mode": $"%TimerMode",
	"increment_starting_time": $"%IncrementStarting",
	"increment_per_turn": $"%IncrementPerTurn",
	"increment_max_time": $"%IncrementMaxTime",
	"extremely_turbo_mode": $"%ExtremelyTurboMode",
	"clashing_enabled": $"%ClashingEnabled",
	"asymmetrical_clashing": $"%AsymmetricalClashing",
	"global_damage_modifier": $"%DamageModifier",
	"parry_combo_scaling": $"%ParryComboScalingMeter",
	"burst_parry_combo_scaling": $"%BurstParryComboScalingMeter",
	"prediction_enabled": $"%PredictionEnabled",
	"has_ceiling": $"%CeilingEnabled",
	"global_hitstun_modifier": $"%HitstunModifier",
	"global_hitstop_modifier": $"%HitstopModifier",
	"global_gravity_modifier": $"%GravityModifier",
	"ceiling_height": $"%CeilingHeight",
	"sadness_enabled": $"%SadnessEnabled",
	"turn_min_length": $"%TurnMinLength",
	"starting_meter": $"%StartingMeter",
	"min_di_scaling": $"%MinDIScalingMeter",
	"max_di_scaling": $"%MaxDIScalingMeter",
	"di_combo_limit": $"%DIComboLimit",
	"brace_enabled": $"%BraceEnabled",
	"show_last_di_state": $"%ShowLastDIState",
	"asymmetrical_health_meter": $"%AsymmetricalHealthMeter",
	"p1_starting_health": $"%P1Health",
	"p2_starting_health": $"%P2Health",
	"p1_starting_meter": $"%P1Meter",
	"p2_starting_meter": $"%P2Meter",
}

var float_to_string = [
	"global_damage_modifier",
	"global_hitstop_modifier",
	"global_hitstun_modifier",
	"global_gravity_modifier",
	"starting_meter",
	"min_di_scaling",
	"max_di_scaling",
	"p1_starting_meter",
	"p2_starting_meter",
	"parry_combo_scaling",
	"burst_parry_combo_scaling",
]

func _ready():
	# Snapshot the scene's hardcoded defaults BEFORE any code or signal can
	# mutate the panel's nodes — this is the source of truth for the "default"
	# dropdown entry.
	scene_defaults = get_data()
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if not (node is Node):
			continue
		if node.has_signal("value_changed"):
			node.connect("value_changed", self, "_setting_value_changed", [setting])
		if node.has_signal("toggled"):
			node.connect("toggled", self, "_setting_value_changed", [setting])
		# OptionButton has neither — its only mutation signal is item_selected.
		if node is OptionButton:
			node.connect("item_selected", self, "_setting_value_changed", [setting])
		pass
	SteamLobby.connect("received_match_settings", self, "_on_received_match_settings")
	init = false
	update_menu()
	if load_all_formats() == []:
		save_format(scene_defaults, "default")
	$"%GameFormats".connect("item_selected", self, "_on_game_formats_item_selected")
	load_formats_to_menu()
	# Restore the last format the user picked so the dropdown's visible
	# selection actually matches the settings sliders. Without this the
	# OptionButton silently lands on whatever's at index 0 (file-system
	# order) while the sliders stay at scene defaults — selection text and
	# real values don't agree until the user manually re-picks.
	_restore_last_format()
	UIManager.register_menu(self.get_parent(), _ui_elements())

func _ui_elements() -> Array:
	var elements := []
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if node is Node:
			elements.append(node)
	elements.append($"%GameFormats")
	elements.append($"%LineEdit")
	elements.append($"%SaveButton")
	elements.append($VBoxContainer)
	elements.append($"%GameSettingsContainer")
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if not (node is Node):
			continue
		var parent = node.get_parent()
		if parent is BoxContainer and not elements.has(parent):
			elements.append(parent)
	return elements

# "default" routes to the scene snapshot regardless of what's in
# default.gameformat — keeps the entry meaning "the un-edited starter values"
# even after someone hits Save while default is the active selection.
func _apply_format(format):
	if format.get("format_name", "") == "default":
		load_settings(scene_defaults)
	else:
		load_settings(format)

func _restore_last_format():
	if loaded_formats.empty():
		return
	var last_name = Global.get_player_data().get("last_game_format", "")
	for i in loaded_formats.size():
		if loaded_formats[i].get("format_name", "") == last_name:
			$"%GameFormats".selected = i
			_apply_format(loaded_formats[i])
			return
	# No saved pick (or it was deleted) — apply whatever the dropdown is
	# pointing at so its text and the slider values still agree.
	var idx = max($"%GameFormats".selected, 0)
	$"%GameFormats".selected = idx
	_apply_format(loaded_formats[idx])

func _on_game_formats_item_selected(item):
	if loaded_formats.size() > item:
		_apply_format(loaded_formats[item])
		Global.save_player_data({"last_game_format": loaded_formats[item].get("format_name", "")})

func disable():
	for node in settings_nodes.values():
		if node.get("editable") != null:
			node.editable = false
		if node.get("disabled") != null:
			node.disabled = true
	$"%GameFormats".disabled = true
	update_menu()

func enable():
	for node in settings_nodes.values():
		if node.get("editable") != null:
			node.editable = true
		if node.get("disabled") != null:
			node.disabled = false
	$"%GameFormats".disabled = false
	update_menu()

func _setting_value_changed(_value, _setting):
	if init:
		update_lobby_data()
	update_menu()

func _on_received_match_settings(settings, force=false):
	if SteamLobby.LOBBY_OWNER == SteamHustle.STEAM_ID:
		if !force:
			return
		if !init:
			update_lobby_data()
	load_settings(settings)

func load_settings(settings):
	# Backwards compat: old game formats / lobby settings carried `chess_timer`
	# as a bool. Translate to the new timer_mode string before the generic
	# loop reads it (and skip the bool itself, since chess_timer isn't in
	# settings_nodes anymore). Old false → "default" (the 30-sec-per-turn
	# clock that always existed); only true mapped to "chess".
	if settings.has("chess_timer") and !settings.has("timer_mode"):
		settings = settings.duplicate()
		settings["timer_mode"] = "chess" if settings.chess_timer else "default"
		settings.erase("chess_timer")
	for setting in settings:
		if !settings_nodes.has(setting):
			print("invalid setting: " + str(setting))
			continue
		var node = settings_nodes[setting]
		if node is OptionButton and settings[setting] is String:
			# OptionButton uses indices internally — map back from canonical
			# string. Falls back to 0 (Default) for unknown values.
			if setting == "timer_mode":
				var idx = TIMER_MODES.find(settings[setting])
				node.selected = idx if idx >= 0 else 0
			continue
		if node.has_method("set_pressed_no_signal") and settings[setting] is bool:
			node.set_pressed_no_signal(settings[setting])
		if node.get("value") != null and settings[setting] is int:
			node.value = settings[setting]
		if node.get("value") != null and node.get("value") is float and settings[setting] is String:
			node.value = float(settings[setting])

	$"%LineEdit".clear()
	update_menu()

func update_menu():
	var mode = TIMER_MODES[$"%TimerMode".selected]
	# Show/hide param rows per mode.
	# - default: per-turn turn time only (in seconds)
	# - none: no params
	# - chess: total clock (in minutes) + min turn length
	# - increment: starting bank + per-turn add (the increment itself is the
	#   minimum — no separate min turn length needed)
	$"%TurnLengthContainer".visible = mode == "chess" or mode == "default"
	$"%TurnMinLengthContainer".visible = mode == "chess"
	$"%IncrementStartingContainer".visible = mode == "increment"
	$"%IncrementPerTurnContainer".visible = mode == "increment"
	$"%IncrementMaxTimeContainer".visible = mode == "increment"
	if mode == "chess":
		$"%TurnLengthLabel".text = "Turn Clock (min)"
	else:
		$"%TurnLengthLabel".text = "Turn Clock (sec)"
	$"%AsymmetricalContainer".visible = $"%AsymmetricalHealthMeter".pressed
	pass

func update_lobby_data():
#	if SteamLobby.LOBBY_ID == 0:
#		return
	if SteamHustle.STEAM_ID != Steam.getLobbyOwner(SteamLobby.LOBBY_ID):
		return
	print("updating lobby settings")
	SteamLobby.update_match_settings(get_data())
	
func get_data():
	var settings := {}
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if setting in float_to_string:
			settings[setting] = str(node.value)
		elif node is OptionButton:
			if setting == "timer_mode":
				settings[setting] = TIMER_MODES[node.selected]
		elif node.get("value") != null:
			settings[setting] = int(node.value)
		elif node.get("pressed") != null:
			settings[setting] = node.pressed

	var overrides = get_data_overrides()
	settings.merge(overrides, true)
	
#	print(settings)
	
	return settings
	
#	return {
#		"stage_width": int($"%StageWidth".value),
#		"p2_dummy": $"%P2Dummy".pressed if singleplayer else false,
#		"di_enabled": $"%DIEnabled".pressed,
#		"turbo_mode": $"%TurboMode".pressed,
#		"infinite_resources": $"%InfiniteResources".pressed,
#		"one_hit_ko": $"%OneHitKO".pressed,
#		"game_length": int($"%GameLength".value),
#		"turn_time": int($"%TurnLength".value),
#		"burst_enabled": $"%BurstEnabled".pressed,
#		"frame_by_frame": $"%FrameByFrame".pressed,
#		"always_perfect_parry": $"%AlwaysPerfectParry".pressed,
#		"char_distance": int($"%CharDist".value),
#	}

func get_data_overrides():
	return {
		"p2_dummy": $"%P2Dummy".pressed if singleplayer else false,
	}

func init(singleplayer=true):
	show()
	# Singleplayer has no opponent clock — force the picker to None (idx 1)
	# and hide it so update_menu hides the per-mode param rows for free.
	if singleplayer:
		$"%TimerMode".selected = TIMER_MODES.find("none")
	$"%TimerModeContainer".visible = !singleplayer
	if !steam:
		if !singleplayer:
			if !Network.is_host():
				hide()
	else:
		init = true
		pass
	$"%P2Dummy".visible = singleplayer
	if singleplayer:
		update_singleplayer()
	else:
		update_multiplayer()
	update_menu()

func update_singleplayer():
	$"%SadnessEnabled".pressed = false

func update_multiplayer():
	$"%SadnessEnabled".pressed = true

func load_formats_to_menu():
	loaded_formats = load_all_formats()
	$"%GameFormats".clear()
	for format in loaded_formats:
		$"%GameFormats".add_item(format.format_name)

func make_formats_folder():
	var dir = Directory.new()
	if !dir.dir_exists("user://gameformats"):
		dir.make_dir("user://gameformats")

func save_format(format, format_name):
	format_name = format_name.strip_edges()
	if format_name == "":
		format_name = "unnamed format"
	make_formats_folder()
	format = format.duplicate(true)
	format["format_name"] = format_name
	var file = File.new()
	file.open("user://gameformats/"+ format.format_name + ".gameformat", File.WRITE)
	file.store_var(format, true)
	file.close()
	load_formats_to_menu()
	return format_name

func _select_format_by_name(name):
	if name == "":
		return
	for i in loaded_formats.size():
		if loaded_formats[i].get("format_name", "") == name:
			$"%GameFormats".selected = i
			Global.save_player_data({"last_game_format": name})
			return

func load_all_formats():
	make_formats_folder()
	var dir = Directory.new()
	var files = []
	var _directories = []
	var formats = []
	dir.open("user://gameformats")
	dir.list_dir_begin(false, true)
#	print(dir.get_current_dir())
	Global.add_dir_contents(dir, files, _directories, false, ".gameformat")
	for path in files:
		var file = File.new()
		file.open(path, File.READ)
		var data: Dictionary = file.get_var()
		formats.append(data)
		file.close()
	return formats

func save_current_format():
	var text = Utils.filter_filename($"%LineEdit".text)
	# load_formats_to_menu (called inside save_format) leaves .selected
	# pointing at whichever format add_item selected last — in Godot 3.5
	# that's the final item from the filesystem walk, which is typically the
	# newest file. Pin selection to the actual name we just saved so the
	# dropdown text matches the user's intent and persists across relaunches.
	var saved_name = save_format(get_data(), text)
	_select_format_by_name(saved_name)

func _on_LineEdit_text_entered(new_text):
	save_current_format()
	$"%LineEdit".clear()


func _on_SaveButton_pressed():
	save_current_format()
	pass # Replace with function body.

func _on_DamageModifier_value_changed(value):
	$"%DamageModifierValueLabel".text = str(value)
	pass # Replace with function body.


func _on_HitstunModifier_value_changed(value):
	$"%HitstunModifierValueLabel".text = str(value)
	pass # Replace with function body.


func _on_HitstopModifier_value_changed(value):
	$"%HitstopModifierValueLabel".text = str(value)
	pass # Replace with function body.


func _on_GravityModifier_value_changed(value):
	$"%GravityModifierValueLabel".text = str(value)
	pass # Replace with function body.


func _on_ParryComboScalingMeter_value_changed(value):
	$"%ParryComboScalingValueLabel".text = str(value)


func _on_BurstParryComboScalingMeter_value_changed(value):
	$"%BurstParryComboScalingValueLabel".text = str(value)


func _on_StartingMeter_value_changed(value):
	$"%StartingMeterValueLabel".text = str(value)
	pass # Replace with function body.


func _on_MinDIScalingMeter_value_changed(value):
	$"%MinDIScalingMeterValueLabel".text = str(value)
	pass # Replace with function body.


func _on_MaxDIScalingMeter_value_changed(value):
	$"%MaxDIScalingMeterValueLabel".text = str(value)
	pass # Replace with function body.


func _on_P1Health_value_changed(value):
	$"%P1HealthValueLabel".text = str(int(value)) + "%"


func _on_P2Health_value_changed(value):
	$"%P2HealthValueLabel".text = str(int(value)) + "%"


func _on_P1Meter_value_changed(value):
	$"%P1MeterValueLabel".text = str(value)


func _on_P2Meter_value_changed(value):
	$"%P2MeterValueLabel".text = str(value)
