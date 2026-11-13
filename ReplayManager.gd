extends Node

const MAX_BACKUPS = 30

var frames = {
	1: {},
	2: {},
	"finished": false,
	"emotes": {
		1: {},
		2: {},
	}
}

var playback = false setget set_playback

var resimulating = false
var play_full = false
var resim_tick = null
var replaying_ingame = false

# Latest chess-timer snapshot, written by UILayer._process every frame during
# chess-timer matches. Save-replay paths fall back to this so manual saves,
# autosaves, and spectator-side saves all bake in fresh timer state — matters
# for replay challenges with restore_timers, where stale or missing state
# leaves the new match starting from full duration.
var chess_timer_state = null

func set_playback(p):
	playback = p

func init():
	frames = {
		1: {},
		2: {},
		"finished": false,
		"emotes": {
			1: {},
			2: {},
		}
	}

func frame_ids():
	return [1, 2]

func cut_replay(last_frame):
	for id in frame_ids():
		for frame in frames[id].keys():
			if frame > last_frame:
				frames[id].erase(frame)

func should_trim_final_turn():
	var reason = str(frames.get("end_reason", ""))
	if reason == "ko" or reason == "forfeit":
		return true
	if reason == "timeout":
		return false
	return frames.get("finished", false)

func trim_final_turn():
	if !should_trim_final_turn():
		return 0
	var last_tick = 0
	for id in frame_ids():
		for tick in frames[id].keys():
			if int(tick) > last_tick:
				last_tick = int(tick)
	if last_tick <= 0:
		return 0
	for id in frame_ids():
		frames[id].erase(last_tick)
	if frames.has("emotes") and frames.emotes is Dictionary:
		for id in frames.emotes.keys():
			if frames.emotes[id] is Dictionary:
				frames.emotes[id].erase(last_tick)
	if frames.has("finished"):
		frames["finished"] = false
	return last_tick

func get_last_action_tick(id):
	var frame_numbers: Array = frames[id].keys()
	frame_numbers.sort()
	return frame_numbers[-1]

func get_last_action(id):
	var frame_numbers: Array = frames[id].keys()
	frame_numbers.sort()
	if frame_numbers:
		return frames[id][frame_numbers[-1]]
	return null

func emote(message, player_id, tick):
	if !playback:
		frames.emotes[player_id][tick] = message
	
func undo(cut=true):
	if resimulating:
		return
	var last_frame = 0
	var last_id = 1
	for id in frame_ids():
		for frame in frames[id].keys():
			if frame > last_frame:
				last_frame = frame
				last_id = id
	var other_id = 1 if last_id == 2 else 2
	if cut:
		frames[last_id].erase(last_frame)
		frames[other_id].erase(last_frame)
	resimulating = true
	playback = true
	resim_tick = (last_frame - 2) if cut else -1

func generate_mp_replay_name(p1: String, p2: String):
	return p1 + "_v_" + p2 + "_" + generate_replay_name()

func generate_replay_name():
	var time = Time.get_datetime_dict_from_system()
	var strings = [str(time.year), str(time.month), str(time.day), str(time.hour), str(time.minute)]
	var string = ""
	for s in strings:
		string += s
		string += "-"
	string += str(time.second)
	return string

func save_replay_mp(match_data, p1, p2):
	save_replay(match_data, generate_mp_replay_name(p1, p2), true)

func _strip_spectator_data(data: Dictionary):
	data.erase("spectating")
	data.erase("replay")
	data.erase("replay_challenge")

func save_replay(match_data: Dictionary, file_name="", autosave=false):
	if file_name == "":
		file_name = generate_replay_name()
	file_name = Utils.filter_filename(file_name)

	var data = match_data.duplicate(true)
	_strip_spectator_data(data)
	data["frames"] = frames
	data["version"] = Global.VERSION
	if chess_timer_state != null:
		data["chess_timer_state"] = chess_timer_state.duplicate()
	# Empty dict reserved for mod-specific data attached to the replay.
	if !data.has("mod_data"):
		data["mod_data"] = {}

	var dir = Directory.new()
	if !dir.dir_exists("user://replay"):
		dir.make_dir("user://replay")
	if !dir.dir_exists("user://replay/autosave"):
		dir.make_dir("user://replay/autosave")
	var file = File.new()
#	OS.shell_open(str("file://", "user://"))
	print(file_name)
	file.open("user://replay/"+("autosave/" if autosave else "")+file_name+".replay", File.WRITE)
	file.store_var(data, true)
	file.close()
	return file_name + ".replay"

const BACKUP_PREFIX = "backup_"

func save_replay_backup(match_data: Dictionary):
	var dir = Directory.new()
	if !dir.dir_exists("user://replay"):
		dir.make_dir("user://replay")
	if !dir.dir_exists("user://replay/backup"):
		dir.make_dir("user://replay/backup")
	var data = match_data.duplicate(true)
	_strip_spectator_data(data)
	data["frames"] = frames
	data["version"] = Global.VERSION
	if chess_timer_state != null:
		data["chess_timer_state"] = chess_timer_state.duplicate()
	if !data.has("mod_data"):
		data["mod_data"] = {}
	var stem = generate_replay_name()
	if match_data.has("user_data"):
		var ud = match_data.user_data
		var p1 = Utils.filter_filename(str(ud.get("p1", "p1")))
		var p2 = Utils.filter_filename(str(ud.get("p2", "p2")))
		stem = p1 + "_v_" + p2 + "_" + stem
	var file_name = BACKUP_PREFIX + stem
	var file = File.new()
	file.open("user://replay/backup/" + file_name + ".replay", File.WRITE)
	file.store_var(data, true)
	file.close()
	_rotate_backups()
	return file_name + ".replay"

func _rotate_backups():
	var dir = Directory.new()
	if !dir.dir_exists("user://replay/backup"):
		return
	var files = []
	var _directories = []
	dir.open("user://replay/backup")
	dir.list_dir_begin(false, true)
	Global.add_dir_contents(dir, files, _directories, false, ".replay")
	if files.size() <= MAX_BACKUPS:
		return
	var with_time = []
	var f = File.new()
	for path in files:
		with_time.append({"path": path, "modified": f.get_modified_time(path)})
	with_time.sort_custom(self, "_sort_by_modified_asc")
	var to_remove = with_time.size() - MAX_BACKUPS
	for i in range(to_remove):
		dir.remove(with_time[i].path)

func _sort_by_modified_asc(a, b):
	return a.modified < b.modified

func load_replays(autosave=true, backups=true):
	var dir = Directory.new()
	var files = []
	var _directories = []
	if !dir.dir_exists("user://replay"):
		dir.make_dir("user://replay")
	if !dir.dir_exists("user://replay/autosave"):
		dir.make_dir("user://replay/autosave")
	if !dir.dir_exists("user://replay/backup"):
		dir.make_dir("user://replay/backup")
	dir.open("user://replay")
	dir.list_dir_begin(false, true)
	Global.add_dir_contents(dir, files, _directories, false)
	if autosave:
		dir.open("user://replay/autosave")
		dir.list_dir_begin(false, true)
		Global.add_dir_contents(dir, files, _directories, false)
	if backups:
		dir.open("user://replay/backup")
		dir.list_dir_begin(false, true)
		Global.add_dir_contents(dir, files, _directories, false)
	var replay_paths = {}
	for path in files:
		var replay_file = File.new()
		var modified = replay_file.get_modified_time(path)
		var data = {
			"path": path,
			"modified": modified,
		}
		if ".replay" in path:
			replay_paths[path.get_file().get_basename()] = data
		replay_file.close()
	return replay_paths

func load_replay(path):
	var file = File.new()
	file.open(path, File.READ)
	var data: Dictionary = file.get_var()
	frames = data.frames
	var match_data = data.duplicate(true)
	match_data.erase("frames")
	_strip_spectator_data(match_data)
	if !match_data.has("mod_data"):
		match_data["mod_data"] = {}
	Utils.normalize_timer_settings(match_data)
	return match_data

func force_ints(dict):
	for key in dict:
		if dict[key] is float:
			dict[key] = int(dict[key])
		if dict[key] is Dictionary:
			force_ints(dict[key])
