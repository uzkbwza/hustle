extends Node

signal nag_window()

var VERSION = "0.10.13-steam"

var audio_player
var music_enabled = true
var freeze_ghost_prediction = true
var ghost_afterimages = true
var fullscreen = false
var show_hitboxes = false
var light_mode = false
var frame_advance = false
var show_playback_controls = false
var playback_speed_mod = 1
var default_dojo = 0
var current_game = null
var css_open = false
var has_supporter_pack_file = false
var enable_custom_colors = true
var enable_custom_particles = true
var enable_custom_hit_sparks = true
var enable_emotes = true
var steam_demo_version = false

var name_paths = {
	"Ninja": "res://characters/stickman/NinjaGuy.tscn",
	"Cowboy": "res://characters/swordandgun/SwordGuy.tscn",
	"Wizard": "res://characters/wizard/Wizard.tscn",
	"Robot": "res://characters/robo/Robot.tscn",
}

var paid_characters = [
	"Robot"
]

var songs = {
	"bg1": preload("res://sound/music/bg1.mp3")
}

func full_version():
	return (!steam_demo_version) and SteamHustle.STARTED

func _enter_tree():
#	get_tree().set_auto_accept_quit(false)
	steam_demo_version = "steam" in VERSION and "beta" in VERSION
	audio_player = AudioStreamPlayer.new()
	call_deferred("add_child", audio_player)
	audio_player.bus = "Music"
	var data = get_player_data()
	for key in data.options:
		set(key, data.options[key])
#	music_enabled = data.options.music_enabled
#	freeze_ghost_prediction = data.options.freeze_ghost_prediction
#	ghost_afterimages = data.options.ghost_afterimages
#	fullscreen = data.options.fullscreen
#	show_hitboxes = data.options.show_hitboxes
	set_music_enabled(music_enabled)
	set_fullscreen(fullscreen)
#	load_supporter_pack()
#
#func load_supporter_pack():
#	var success = ProjectSettings.load_resource_pack(OS.get_executable_path().get_base_dir() + "/Supporter.pck")
#	if success:
#		has_supporter_pack_file = true
#		print(has_supporter_pack_file)

func _ready():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	randomize()
	if randi() % 50 == 0 and !SteamHustle.STARTED:
		emit_signal("nag_window")

func set_music_enabled(on):
	music_enabled = on
	if on:
		play_song("bg1")
		pass
	else:
		audio_player.stop()
		pass

func has_supporter_pack():
	return true

func set_playback_controls(on):
	show_playback_controls = on
	save_options()
	
func set_fullscreen(on):
	fullscreen = on
	if fullscreen:
		OS.window_fullscreen = true
		OS.window_borderless = true
	else:
		OS.window_fullscreen = false
		OS.window_borderless = false
	save_options()

func set_hitboxes(on):
	show_hitboxes = on
	save_options()

func play_song(song_name):
	audio_player.stream = songs[song_name]
	audio_player.play()

func add_dir_contents(dir: Directory, files: Array, directories: Array, recursive=true):
	var file_name = dir.get_next()

	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name
		
		if dir.current_is_dir():
			if recursive:
#				print("Found directory: %s" % path)
				var subDir = Directory.new()
				subDir.open(path)
				subDir.list_dir_begin(true, false)
				directories.append(path)
				add_dir_contents(subDir, files, directories)
		else:
#			print("Found file: %s" % path)
			files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()

func save_username(username: String):
	save_player_data({"username": username})

func save_option(value, option):
	set(option, value)
	save_options()

func set_light_mode(on):
	light_mode = on
	save_options()

func save_options():
	save_player_data({
		"options": {
			"music_enabled": music_enabled,
			"freeze_ghost_prediction": freeze_ghost_prediction,
			"ghost_afterimages": ghost_afterimages,
			"fullscreen": fullscreen,
			"show_hitboxes": show_hitboxes,
			"show_playback_controls": show_playback_controls,
			"default_dojo": 0,
#			"light_mode": light_mode,
			"enable_emotes": enable_emotes,
			"enable_custom_colors": enable_custom_colors,
			"enable_custom_particles": enable_custom_particles,
			"enable_custom_hit_sparks": enable_custom_hit_sparks,
		}
	})

func get_default_player_data():
	return {
		"username": "",
		"options" : {
			"music_enabled": true,
			"freeze_ghost_prediction": true,
			"ghost_afterimages": true,
			"fullscreen": false,
			"show_hitboxes": false,
			"show_playback_controls": false,
			"default_dojo": 0,
			"enable_emotes": true,
			"enable_custom_colors": true,
			"enable_custom_particles": true,
			"enable_custom_hit_sparks": true,
#			"light_mode": false,
		}
	}

func get_player_data():
	var file = File.new()
	var data
	if !file.file_exists("user://playerdata.json"):
		data = get_default_player_data()
		save_player_data(data)
	file.open("user://playerdata.json", File.READ)
	data = parse_json(file.get_as_text())
	var default_data = get_default_player_data()
	if !(data is Dictionary):
		save_player_data(get_default_player_data())
		file.close()
		return get_default_player_data()
	for key in default_data:
		if not (key in data):
			data[key] = default_data[key]
	file.close()
	return data

func save_player_data(data: Dictionary):
	var file = File.new()
	var existing_data
	if !file.file_exists("user://playerdata.json"):
		existing_data = get_default_player_data()
	else:
		file.open("user://playerdata.json", File.READ)
		var string = file.get_as_text()
		existing_data = parse_json(string)
		if !(existing_data is Dictionary):
			var dir = Directory.new()
			dir.open("user://")
			dir.remove("user://playerdata.json")
			existing_data = get_default_player_data()

	for key in data:
		existing_data[key] = data[key]
	file.open("user://playerdata.json", File.WRITE)
	file.store_string(JSON.print(existing_data, "  "))
	file.close()
	return
