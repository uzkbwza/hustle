extends Control

var path
var modified

onready var button = $"%Button"

signal pressed()
signal data_updated()


func setup(replay_map, key):
	button.text = key
	button.connect("pressed", self, "emit_signal", ["pressed"])
	var data = replay_map[key]
	path = data["path"]
	modified = data["modified"]
#	if data.has("version"):
#		$VersionLabel.text = str(data.version) if data.version else ("unknown")

func show_data():
	var match_data = ReplayManager.load_replay(path)
	if !("version" in match_data):
		return
	$"%VersionLabel".show()
	$"%VersionLabel".text = str(match_data["version"])
	yield(get_tree(), "idle_frame")
	emit_signal("data_updated")
