extends HBoxContainer

var path
var modified

onready var button = $Button

signal pressed()


func setup(replay_map, key):
	button.text = key
	button.connect("pressed", self, "emit_signal", ["pressed"])
	var data = replay_map[key]
	path = data["path"]
	modified = data["modified"]
#	if data.has("version"):
#		$VersionLabel.text = str(data.version) if data.version else ("unknown")
