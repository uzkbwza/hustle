extends MarginContainer

export var steam = false

var singleplayer = true
var init = false

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
	"gravity_enabled": $"%GravityEnabled"
}

func _ready():
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if node.has_signal("value_changed"):
			node.connect("value_changed", self, "_setting_value_changed", [setting])
		if node.has_signal("toggled"):
			node.connect("toggled", self, "_setting_value_changed", [setting])
		pass
	SteamLobby.connect("received_match_settings", self, "_on_received_match_settings")
	init = false
	pass

func disable():
	for node in settings_nodes.values():
		if node.get("editable") != null:
			node.editable = false
		if node.get("disabled") != null:
			node.disabled = true

func enable():
	for node in settings_nodes.values():
		if node.get("editable") != null:
			node.editable = true
		if node.get("disabled") != null:
			node.disabled = false


func _setting_value_changed(_value, _setting):
	if init:
		update_lobby_data()
	pass

func _on_received_match_settings(settings, force=false):
	if SteamLobby.LOBBY_OWNER == SteamYomi.STEAM_ID:
		if !force:
			return
		if !init:
			update_lobby_data()
	for setting in settings:
		if !settings_nodes.has(setting):
			print("invalid setting: " + str(setting))
			continue
		var node = settings_nodes[setting]
		if node.has_method("set_pressed_no_signal") and settings[setting] is bool:
			node.set_pressed_no_signal(settings[setting])
		if node.get("value") != null and settings[setting] is int:
			node.value = settings[setting]

func update_lobby_data():
#	if SteamLobby.LOBBY_ID == 0:
#		return
	if SteamYomi.STEAM_ID != Steam.getLobbyOwner(SteamLobby.LOBBY_ID):
		return
	print("updating lobby settings")
	SteamLobby.update_match_settings(get_data())

func get_data():
	var settings := {}
	for setting in settings_nodes:
		var node = settings_nodes[setting]
		if node.get("value") != null:
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
	$"%TurnLengthContainer".visible = !singleplayer
	if !steam:
		if !singleplayer:
			if !Network.is_host():
				hide()
	else:
		init = true
		pass
	$"%P2Dummy".visible = singleplayer
