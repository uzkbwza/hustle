extends Window

signal update_requested(key)
signal unsubscribe_requested(key)
signal issues_dismissed(keys)

onready var timer = $"%Timer"
onready var timer_label = $"%TimerLabel"
onready var ok_button = $"%OkButton"
onready var title_label = $"%Title"
onready var warning_container = $"%WarningContainer"
onready var warning_label = $"%Label"
onready var crash_label = $"%Crash"
onready var subscription_section = $"%SubscriptionSection"
onready var subscription_rows = $"%SubscriptionRows"
onready var update_all_button = $"%UpdateAll"
onready var unsubscribe_all_button = $"%UnsubscribeAll"

var _rows := {}
var _warning_active := false


func _ready() -> void:
	set_process(false)
	update_all_button.connect("pressed", self, "_on_update_all")
	unsubscribe_all_button.connect("pressed", self, "_on_unsubscribe_all")


func start() -> void:
	_warning_active = true
	title_label.text = "WARNING!!!"
	ok_button.disabled = true
	timer_label.show()
	warning_container.show()
	show()
	set_process(true)
	timer.start()


func set_issues(issues: Dictionary) -> void:
	warning_container.visible = _warning_active
	for key in _rows.keys():
		if not issues.has(key):
			_rows[key].node.queue_free()
			_rows.erase(key)

	for key in issues.keys():
		if not _rows.has(key):
			_rows[key] = _create_row(key)
		_update_row(_rows[key], issues[key])

	subscription_section.visible = not issues.empty()
	if issues.empty():
		if not _warning_active:
			hide()
		return
	if _warning_active:
		return

	ok_button.disabled = false
	timer_label.hide()
	set_process(false)
	title_label.text = "Mod subscriptions"
	warning_label.hide()
	crash_label.hide()
	show()


func _create_row(key: String) -> Dictionary:
	var row = VBoxContainer.new()
	row.add_constant_override("separation", 1)
	var title = Label.new()
	title.autowrap = true
	row.add_child(title)
	var info = Label.new()
	info.modulate = Color(1, 1, 1, 0.7)
	info.autowrap = true
	row.add_child(info)
	var status = Label.new()
	status.modulate = Color(1, 0.75, 0.4)
	status.autowrap = true
	row.add_child(status)
	var buttons = HBoxContainer.new()
	buttons.add_constant_override("separation", 4)
	var update = Button.new()
	update.text = "Update"
	update.size_flags_horizontal = SIZE_EXPAND_FILL
	update.connect("pressed", self, "_on_update_pressed", [key])
	buttons.add_child(update)
	var unsubscribe = Button.new()
	unsubscribe.text = "Unsubscribe"
	unsubscribe.size_flags_horizontal = SIZE_EXPAND_FILL
	unsubscribe.connect("pressed", self, "_on_unsubscribe_pressed", [key])
	buttons.add_child(unsubscribe)
	row.add_child(buttons)
	subscription_rows.add_child(row)
	return {
		"node": row,
		"title": title,
		"info": info,
		"status": status,
		"update": update,
		"unsubscribe": unsubscribe,
	}


func _update_row(row: Dictionary, issue: Dictionary) -> void:
	var title: Label = row["title"]
	var info: Label = row["info"]
	var status: Label = row["status"]
	var update: Button = row["update"]
	var unsubscribe: Button = row["unsubscribe"]
	var source = str(issue.get("source_label", ""))
	var author = str(issue.get("author", ""))
	title.text = str(issue.get("title", "Mod"))
	info.text = source if author == "" else source + "  |  " + author
	status.text = str(issue.get("status", ""))
	update.disabled = bool(issue.get("busy", false)) or bool(issue.get("resolved", false))
	unsubscribe.disabled = bool(issue.get("busy", false))


func _on_update_all() -> void:
	for key in _rows.keys():
		emit_signal("update_requested", key)


func _on_unsubscribe_all() -> void:
	for key in _rows.keys():
		emit_signal("unsubscribe_requested", key)


func _on_update_pressed(key: String) -> void:
	emit_signal("update_requested", key)


func _on_unsubscribe_pressed(key: String) -> void:
	emit_signal("unsubscribe_requested", key)


func _process(_delta: float) -> void:
	timer_label.text = str(ceil(timer.time_left))


func _on_OkButton_pressed() -> void:
	var keys = _rows.keys()
	_warning_active = false
	set_process(false)
	timer.stop()
	hide()
	if not keys.empty():
		emit_signal("issues_dismissed", keys)


func _on_Timer_timeout() -> void:
	set_process(false)
	timer_label.hide()
	ok_button.disabled = false
