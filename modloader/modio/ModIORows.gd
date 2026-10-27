extends HBoxContainer

signal mods_pressed(collection)
signal page_pressed(collection)
signal open_pressed(guide)
signal toggle_pressed(collection)

const MODIO_IMAGE := preload("res://modloader/modio/ModIOImage.gd")

var kind := "collection"
var collection := {}
var guide := {}

var name_label: Label
var summary_label: Label
var details_label: Label
var mods_btn: Button
var page_btn: Button
var open_btn: Button
var toggle_btn: Button

var _built := false


func _init() -> void:
	size_flags_horizontal = SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_constant_override("separation", 4)
	name_label = _make_label()
	name_label.rect_min_size = Vector2(120, 0)
	add_child(name_label)


func _make_label() -> Label:
	var label = Label.new()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.autowrap = true
	label.max_lines_visible = 1
	return label


func _make_button(tooltip: String, icon: Texture) -> Button:
	var button = Button.new()
	button.size_flags_vertical = SIZE_EXPAND_FILL
	button.hint_tooltip = tooltip
	button.icon = icon
	button.icon_align = Button.ALIGN_CENTER
	return button


func _build() -> void:
	if _built:
		return
	_built = true
	if kind == "guide":
		details_label = _make_label()
		details_label.modulate = Color(0.8, 0.8, 0.8)
		add_child(details_label)
		open_btn = _make_button("Open this guide on mod.io", MODIO_IMAGE.icon("globe"))
		add_child(open_btn)
		open_btn.connect("pressed", self, "_on_open_pressed")
	elif kind == "editor":
		toggle_btn = _make_button("", MODIO_IMAGE.icon("collect"))
		add_child(toggle_btn)
		toggle_btn.connect("pressed", self, "_on_toggle_pressed")
	else:
		summary_label = _make_label()
		summary_label.modulate = Color(0.8, 0.8, 0.8)
		add_child(summary_label)
		mods_btn = _make_button("View this collection's mods", MODIO_IMAGE.icon("collect"))
		add_child(mods_btn)
		page_btn = _make_button("Open this collection on mod.io", MODIO_IMAGE.icon("globe"))
		add_child(page_btn)
		mods_btn.connect("pressed", self, "_on_mods_pressed")
		page_btn.connect("pressed", self, "_on_page_pressed")


func setup(data: Dictionary, is_member: bool = false) -> void:
	_build()
	if kind == "guide":
		guide = data
		name_label.text = str(data.get("name", "Guide"))
		var author = ""
		var user = data.get("user", {})
		if typeof(user) == TYPE_DICTIONARY:
			author = str(user.get("display_name", user.get("username", "")))
		var guide_summary = str(data.get("summary", "")).strip_edges()
		var details = author
		if guide_summary != "":
			details = "%s - %s" % [author, guide_summary] if author != "" else guide_summary
		details_label.text = details
		details_label.visible = details != ""
		return

	collection = data
	name_label.text = str(data.get("name", "Collection"))
	if kind == "editor":
		toggle_btn.icon = MODIO_IMAGE.icon("uncollect" if is_member else "collect")
		toggle_btn.hint_tooltip = "Remove from this collection" if is_member else "Add to this collection"
		return
	var summary = str(data.get("summary", "")).strip_edges()
	summary_label.text = summary
	summary_label.visible = summary != ""


func set_page_visible(value: bool) -> void:
	if page_btn != null:
		page_btn.visible = value


func _on_mods_pressed() -> void:
	emit_signal("mods_pressed", collection)


func _on_page_pressed() -> void:
	emit_signal("page_pressed", collection)


func _on_open_pressed() -> void:
	emit_signal("open_pressed", guide)


func _on_toggle_pressed() -> void:
	emit_signal("toggle_pressed", collection)
