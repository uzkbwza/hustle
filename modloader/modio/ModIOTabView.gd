extends VBoxContainer

const GRID_COLUMNS := 4
const CARD_WIDTH := 128
const GRID_GAP := 4

onready var prev_btn: Button = $"%Prev"
onready var page_label: Label = $"%PageLabel"
onready var next_btn: Button = $"%Next"
onready var search_edit: LineEdit = $"%SearchEdit"
onready var search_btn: Button = $"%SearchBtn"
onready var sort_option: OptionButton = $"%SortOption"
onready var filter_option: OptionButton = $"%FilterOption"
onready var timespan_option: OptionButton = $"%TimespanOption"
onready var compact_toggle: CheckButton = $"%Compact"
onready var author_option: OptionButton = $"%AuthorOption"
onready var subscribed_check: CheckButton = $"%SubscribedCheck"
onready var status: Label = $"%Status"
onready var list: GridContainer = $"%List"

var index := 0
var title := ""
var sort_options := []
var rows := {}
var offset := 0
var result_total := -1
var searching := false
var loaded := false
var generation := 0
var search := ""
var sort := ""
var filter := ""
var author := ""
var subscribed_only := false
var timespan := "all_time"
var timespan_set := false
var filter_values := [""]
var grid_view := true
var compact := false
var card_width := CARD_WIDTH


func _ready() -> void:
	connect("resized", self, "_apply_columns")
	$Scroll.connect("resized", self, "_apply_columns")


func setup(p_index: int, p_title: String, p_sort_options: Array, p_grid_view: bool) -> void:
	index = p_index
	title = p_title
	grid_view = p_grid_view
	search_edit.placeholder_text = "Search %s..." % title.to_lower()

	sort_options = p_sort_options.duplicate()
	sort_option.clear()
	for option in sort_options:
		sort_option.add_item(option[0])
	if sort_options.size() > 0:
		sort = sort_options[0][1]

	filter_option.clear()
	filter_option.add_item("All")
	filter_values = [""]
	filter = ""
	author_option.clear()
	author_option.add_item("All creators")
	author_option.add_item("My uploads")
	author_option.add_item("Other creators")
	author = ""
	subscribed_only = false
	subscribed_check.set_pressed_no_signal(false)
	_apply_columns()


func set_compact(value: bool) -> void:
	compact = value
	compact_toggle.set_pressed_no_signal(value)
	list.add_constant_override("v_separation", 0 if value else GRID_GAP)
	_apply_columns()


func set_page(page: int, pages: int) -> void:
	page_label.text = "%d/%d" % [page, pages]


func set_paging_enabled(prev_enabled: bool, next_enabled: bool) -> void:
	prev_btn.disabled = not prev_enabled
	next_btn.disabled = not next_enabled


func set_card_width(value: int) -> void:
	card_width = value
	_apply_columns()


func set_filter_options(labels: Array, values: Array) -> void:
	var current = filter
	filter_option.clear()
	filter_option.add_item("All")
	filter_values = [""]
	for i in range(labels.size()):
		filter_option.add_item(labels[i])
		filter_values.append(values[i])
	_restore_filter(current)


func set_timespan_options(options: Array) -> void:
	timespan_option.clear()
	for option in options:
		timespan_option.add_item(option[0])


func set_author_filters_visible(value: bool) -> void:
	$AuthorRow.visible = value


func set_subscribed_visible(value: bool) -> void:
	subscribed_check.visible = value


func set_filter_visible(value: bool) -> void:
	$SearchRow/FilterRow.visible = value


func set_filter_label(text: String) -> void:
	filter_option.hint_tooltip = text


func set_sort_visible(value: bool) -> void:
	sort_option.visible = value


func set_controls_visible(value: bool) -> void:
	$SearchRow.visible = value
	$AuthorRow.visible = value


func set_source_options(labels: Array, values: Array) -> void:
	filter_option.clear()
	filter_values = []
	for i in range(labels.size()):
		filter_option.add_item(labels[i])
		filter_values.append(values[i])
	if filter_values.size() > 0:
		filter_option.select(0)
		filter = filter_values[0]


func set_search_visible(value: bool) -> void:
	search_edit.visible = value
	search_btn.visible = value


func clear_rows() -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	rows.clear()


func _apply_columns() -> void:
	if compact or not grid_view:
		list.columns = 1
		return
	var width = int($Scroll.rect_size.x)
	if width <= 0:
		width = int(rect_size.x)
	if width <= 0:
		list.columns = GRID_COLUMNS
		return
	list.columns = min(GRID_COLUMNS, max(1, int((width + GRID_GAP) / (card_width + GRID_GAP))))


func _restore_filter(value: String) -> void:
	filter = ""
	if value == "":
		return
	for i in range(filter_values.size()):
		if filter_values[i] == value:
			filter_option.select(i)
			filter = value
			return
