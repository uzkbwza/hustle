extends Control

export(float) var spin_seconds = 1.8
export(float) var stall_seconds = 10.0
export(Color) var stall_color = Color(1, 0.42, 0.36)

onready var _status_label = $Hud/HudMargin/Box/StatusLabel
onready var _detail_label = $Hud/HudMargin/Box/Info/DetailLabel
onready var _progress = $Hud/HudMargin/Box/Progress
onready var _percent_label = $Hud/HudMargin/Box/Header/PercentLabel
onready var _version_label = $Hud/HudMargin/Box/Header/VersionLabel
onready var _elapsed_label = $Hud/HudMargin/Box/Info/ElapsedLabel
onready var _log_label = $LogPanel/LogMargin/LogBox/LogLabel
onready var _log_panel = $LogPanel
onready var _spin_sprites = $Hud/HudMargin/Box/Header/SpinHolder.get_children()

var _spin_index = 0
var _spin_side = true
var _spin_ms = 0.0
var _normal_time_color = Color(1, 1, 1)
var _log_lines = []
var _start_ms = 0
var _stalled = false


func _ready():
	_start_ms = OS.get_ticks_msec()
	_normal_time_color = _elapsed_label.get_color("font_color")
	_version_label.text = str(Global.VERSION)
	var border = get_node_or_null("/root/BorderManager")
	if border != null:
		border.set_border_color(1, Color(0, 0, 0))
		border.set_border_color(2, Color(0, 0, 0))
	for i in range(_spin_sprites.size()):
		_spin_sprites[i].visible = i == 0
	call_deferred("_boot")


func _process(delta):
	_update_spin(delta)

	var now = OS.get_ticks_msec()
	var seconds = (now - _start_ms) / 1000.0
	var text = "%.1f s" % seconds
	var stalled = false
	var last = get_node_or_null("/root/ModLoader")
	if last != null and last.last_step_ms > 0:
		var since = (now - last.last_step_ms) / 1000.0
		if since >= stall_seconds:
			stalled = true
			text = "%d s without progress" % int(since)
	if stalled != _stalled:
		_stalled = stalled
		_elapsed_label.add_color_override("font_color", stall_color if stalled else _normal_time_color)
		_log_panel.visible = stalled
		if stalled:
			_log_label.text = PoolStringArray(_log_lines).join("\n")
	if stalled:
		var pulse = 0.55 + 0.45 * abs(sin(now / 260.0))
		_elapsed_label.modulate = Color(1, 1, 1, pulse)
	else:
		_elapsed_label.modulate = Color(1, 1, 1, 1)
	_elapsed_label.text = text


func _update_spin(delta):
	_spin_ms += delta * 1000.0
	var phase = fmod(_spin_ms / (spin_seconds * 1000.0), 1.0)
	var scale_x = cos(phase * TAU)
	var side = scale_x >= 0.0
	if side != _spin_side:
		_spin_side = side
		_spin_sprites[_spin_index].visible = false
		_spin_index = (_spin_index + 1) % _spin_sprites.size()
		_spin_sprites[_spin_index].visible = true
	_spin_sprites[_spin_index].rect_scale.x = scale_x


func set_status(text):
	_status_label.text = text.substr(0, 1).to_upper() + text.substr(1)


func set_detail(text):
	_detail_label.text = text


func set_progress(value):
	var clamped = clamp(value, 0.0, 100.0)
	_progress.value = clamped
	_percent_label.text = str(int(clamped)) + "%"


func add_log(text):
	_log_lines.append(text)
	while _log_lines.size() > 40:
		_log_lines.pop_front()
	if _stalled:
		_log_label.text = PoolStringArray(_log_lines).join("\n")


func _boot():
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	var loader = get_node_or_null("/root/ModLoader")
	if loader != null:
		yield(loader.start(self), "completed")

	set_status("Starting game...")
	set_detail("")
	set_progress(100)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	get_tree().change_scene("res://Main.tscn")
