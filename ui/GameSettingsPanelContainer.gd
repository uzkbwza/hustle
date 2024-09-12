extends MarginContainer

export var steam = false

var singleplayer = true
var init = false

var loaded_formats = []
var selected_format = ""

onready var settings_nodes = {
	"stage_width": $"%StageWidth",
	"p2_dummy": $"%P2Dummy",
	"di_enabled": $"%DIEnabled",
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
	"chess_timer": $"%ChessTimer",
	"extremely_turbo_mode": $"%ExtremelyTurboMode",
	"clashing_enabled": $"%ClashingEnabled",
	"asymmetrical_clashing": $"%AsymmetricalClashing",
	"global_damage_modifier": $"%DamageModifier",
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
}

var float_to_string = [
	"global_damage_modifier",
	"global_hitstop_modifier",
	"global_hitstun_modifier",
	"global_gravity_modifier",
	"starting_meter",
	"min_di_scaling",
	"max_di_scaling",
]

func _ready():
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if not (node is Node):
			continue
		if node.has_signal("value_changed"):
			node.connect("value_changed", self, "_setting_value_changed", [setting])
		if node.has_signal("toggled"):
			node.connect("toggled", self, "_setting_value_changed", [setting])
		pass
	SteamLobby.connect("received_match_settings", self, "_on_received_match_settings")
	init = false
	update_menu()
	if load_all_formats() == []:
		save_format(get_data(), "default")
	$"%GameFormats".connect("item_selected", self, "_on_game_formats_item_selected")
	load_formats_to_menu()
	
func _on_game_formats_item_selected(item):
	if loaded_formats.size() > item:
		load_settings(loaded_formats[item])

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
	for setting in settings:
		if !settings_nodes.has(setting):
			print("invalid setting: " + str(setting))
			continue
		var node = settings_nodes[setting]
		if node.has_method("set_pressed_no_signal") and settings[setting] is bool:
			node.set_pressed_no_signal(settings[setting])
		if node.get("value") != null and settings[setting] is int:
			node.value = settings[setting]
		if node.get("value") != null and node.get("value") is float and settings[setting] is String:
			node.value = float(settings[setting])

	$"%LineEdit".clear()
	update_menu()

func update_menu():
	if $"%ChessTimer".pressed:
#		if $"%TurnLengthLabel".text != "Turn Clock (min)":
#			$"%TurnLength".value = 30
		$"%TurnLengthLabel".text = "Turn Clock (min)"
		$"%TurnMinLengthContainer".show()
	else:
#		if $"%TurnLengthLabel".text != "Turn Clock (sec)":
#			$"%TurnLength".value = 30
		$"%TurnLengthLabel".text = "Turn Clock (sec)"
		$"%TurnMinLengthContainer".hide()
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
	$"%TurnLengthContainer".visible = !singleplayer
	$"%ChessTimer".visible = !singleplayer
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
	save_format(get_data(), text)

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


func _on_StartingMeter_value_changed(value):
	$"%StartingMeterValueLabel".text = str(value)
	pass # Replace with function body.


func _on_MinDIScalingMeter_value_changed(value):
	$"%MinDIScalingMeterValueLabel".text = str(value)
	pass # Replace with function body.


func _on_MaxDIScalingMeter_value_changed(value):
	$"%MaxDIScalingMeterValueLabel".text = str(value)
	pass # Replace with function body.
