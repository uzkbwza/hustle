extends Node

var name_paths = {
	"SwordGuy": "res://characters/swordandgun/SwordGuy.tscn",
	"NinjaGuy": "res://characters/stickman/NinjaGuy.tscn",
	"Wizard": "res://characters/wizard/Wizard.tscn",
}

func add_dir_contents(dir: Directory, files: Array, directories: Array):
	var file_name = dir.get_next()

	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name
		
		if dir.current_is_dir():
			print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			directories.append(path)
			add_dir_contents(subDir, files, directories)
		else:
			print("Found file: %s" % path)
			files.append(path)

		file_name = dir.get_next()

	dir.list_dir_end()
