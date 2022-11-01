extends Node

const VERSION = "0.1.0"

var name_paths = {
	"SwordGuy": "res://characters/swordandgun/SwordGuy.tscn",
	"NinjaGuy": "res://characters/stickman/NinjaGuy.tscn",
	"Wizard": "res://characters/wizard/Wizard.tscn",
}

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
	var file = File.new()
	file.open("user://playerdata.json")

func get_default_player_data():
	return {
		"username": "username"
#		"favorite_color": null,
	}

func get_player_data():
	var file = File.new()
	var data
	if !file.file_exists("user://playerdata.json"):
		data = get_default_player_data()
		save_player_data(data)
	file.open("user://playerdata.json", File.READ)
	data = parse_json(file.get_as_text())
	if !(data is Dictionary):
		save_player_data(get_default_player_data())
		file.close()
		return get_default_player_data()
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
