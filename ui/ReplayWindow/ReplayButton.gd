extends Control

var path
var modified
# Populated by show_data once the replay file has been parsed. Used by
# UILayer's filter + the missing-character click-confirm.
var version = ""
var has_missing_character = false
# Which folder the replay came from: "manual" (root), "autosave", "backup".
var category = "manual"

static func detect_category(full_path) -> String:
	if full_path.get_base_dir().ends_with("autosave"):
		return "autosave"
	if full_path.get_base_dir().ends_with("backup"):
		return "backup"
	return "manual"

onready var button = $"%Button"
onready var toggle = get_node_or_null("%Toggle")

signal pressed()
signal data_updated()


func setup(replay_map, key):
	button.text = key
	button.connect("pressed", self, "emit_signal", ["pressed"])
	var data = replay_map[key]
	path = data["path"]
	modified = data["modified"]
	category = detect_category(path)
	# Ensure toggle is optional for compatibility with older scenes/mods
	if is_instance_valid(toggle):
		toggle.visible = false
#	if data.has("version"):
#		$VersionLabel.text = str(data.version) if data.version else ("unknown")

func _pretty(full_name):
	if full_name == null:
		return "?"
	if full_name.find("__") != -1:
		return full_name.split("__")[1]
	return full_name

func _is_character_installed(raw_name):
	if raw_name == null:
		return true
	if Global.name_paths.has(raw_name):
		return true
	var css = Network.css_instance
	if is_instance_valid(css) and css.name_to_index.has(raw_name):
		return true
	return false

func show_data():
	var match_data = ReplayManager.load_replay(path)
	if !("version" in match_data):
		return
	version = str(match_data["version"])
	$"%VersionLabel".show()
	$"%VersionLabel".text = version
	if match_data.has("selected_characters"):
		var sc = match_data.selected_characters
		var p1_name = _pretty(sc[1].name) if sc.has(1) and sc[1].has("name") else "?"
		var p2_name = _pretty(sc[2].name) if sc.has(2) and sc[2].has("name") else "?"
		$"%MatchupLabel".text = p1_name + " vs " + p2_name
		# Missing-character check uses the raw name — same key game.gd uses
		# to load the character scene, so this matches whether the replay
		# would actually fail to open.
		var raw1 = sc[1].name if sc.has(1) and sc[1].has("name") else null
		var raw2 = sc[2].name if sc.has(2) and sc[2].has("name") else null
		has_missing_character = !_is_character_installed(raw1) or !_is_character_installed(raw2)
		# Color is owned by UILayer._refresh_replay_button_colors so it stays
		# in sync with the version-mode toggle. We only paint it here to give
		# the initial render the right tint before the first filter pass runs.
		if has_missing_character:
			modulate = Color(1, 0.45, 0.45)
		elif version != "" and version != Global.VERSION:
			modulate = Color(1, 0.85, 0.2)
	yield(get_tree(), "idle_frame")
	emit_signal("data_updated")
