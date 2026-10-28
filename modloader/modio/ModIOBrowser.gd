extends Window

const PAGE_SIZE := 48
const GRID_COLUMNS := 4
const CARD_WIDTH := 128
const MOBILE_CARD_WIDTH := 128
const SIDEBAR_WIDTH := 96
const MOBILE_SIDEBAR_WIDTH := 96
const CONTENT_WIDTH := 512
const GRID_GAP := 0
const THUMB_SIZE := 190

const TOOLTIP_WIDTH := 300
const TOOLTIP_MAX_LINES := 18
const TOOLTIP_PAD := 8

const TAB_VIEW_SCENE := preload("res://modloader/modio/ModIOTabView.tscn")
const MOD_ROW_SCENE := preload("res://modloader/modio/ModIOBrowserRow.tscn")
const ROWS_SCRIPT := preload("res://modloader/modio/ModIORows.gd")
const MODIO_IMAGE := preload("res://modloader/modio/ModIOImage.gd")
const WORKSHOP_API_SCRIPT := preload("res://modloader/modio/WorkshopAPI.gd")
const WORKSHOP_STORE := preload("res://modloader/modio/WorkshopStore.gd")

const TAB_FEATURED := 0
const TAB_MODS := 1
const TAB_COLLECTIONS := 2
const TAB_GUIDES := 3

const TAB_NAMES := ["Featured", "Mods", "Collections", "Guides"]

const WORKSHOP_TAB_EXPLORE := 0
const WORKSHOP_TAB_MY_ITEMS := 1
const WORKSHOP_TAB_COLLECTIONS := 2

const WORKSHOP_TAB_NAMES := ["Explore", "My Items", "Collections"]
const WORKSHOP_TAB_BASE := 4
const WORKSHOP_PAGE_SIZE := 50

const WORKSHOP_TAG_OPTIONS := [
	"Style",
	"Character",
	"Texture Replacement",
	"Sound Replacement",
	"Gamemode",
	"Stage",
	"Tweaks",
	"Tool",
	"Overhaul",
	"Clientside",
]

const WORKSHOP_SORT_OPTIONS := [
	["Trending", "trend"],
	["Most popular", "vote"],
	["Newest", "publication"],
]

const WORKSHOP_MY_ITEMS_SORT_OPTIONS := [
	["Recently subscribed", "subscription"],
	["Newest", "creation"],
	["Recently updated", "updated"],
	["Alphabetical", "title"],
]

const WORKSHOP_MY_ITEMS_SOURCES := [
	["Subscribed", "subscribed"],
	["Published", "published"],
]

const WORKSHOP_DISCUSSION_LINKS := [
	["Workshop Discussions", "Talk about Workshop items, updates and ideas.", "https://steamcommunity.com/workshop/discussions/?appid=2212330"],
	["Game Discussions", "General discussion for Your Only Move Is HUSTLE.", "https://steamcommunity.com/app/2212330/discussions/"],
	["Steam Guides", "Community guides for the game.", "https://steamcommunity.com/app/2212330/guides/"],
	["Workshop Hub", "Browse the Workshop on the Steam Community.", "https://steamcommunity.com/app/2212330/workshop/"],
]

const WORKSHOP_ABOUT_LINKS := [
	["About the Workshop", "What the Steam Workshop is and how it works.", "https://steamcommunity.com/workshop/about/?appid=2212330"],
	["Workshop Rules", "Steam Workshop rules and guidelines.", "https://steamcommunity.com/workshop/about/"],
	["Your Only Move Is HUSTLE", "Visit the game's Steam Community hub.", "https://steamcommunity.com/app/2212330"],
	["Store Page", "View Your Only Move Is HUSTLE on Steam.", "https://store.steampowered.com/app/2212330/"],
]

const TIMESPAN_OPTIONS := [
	["All time", "all_time"],
	["Today", "today"],
	["This week", "week"],
	["This month", "month"],
	["Last 3 months", "3_months"],
	["This year", "year"],
]

const MOD_SORT_OPTIONS := [
	["Popular", "-subscribers_total"],
	["Most downloaded", "-downloads_total"],
	["Top rated", "-ratings_weighted_aggregate"],
	["Newest", "-date_live"],
	["Recently updated", "-date_updated"],
	["Alphabetical", "name"],
]

const FEATURED_SORT_OPTIONS := [
	["Trending", "-downloads_today"],
	["Most downloaded", "-downloads_total"],
	["Most subscribers", "-subscribers_total"],
	["Top rated", "-ratings_weighted_aggregate"],
	["Newest", "-date_live"],
	["Recently updated", "-date_updated"],
	["Alphabetical", "name"],
]

const COLLECTION_SORT_OPTIONS := [
	["Recently added", "-date_live"],
	["Recently updated", "-date_updated"],
	["Alphabetical", "name"],
]

const GUIDE_SORT_OPTIONS := [
	["Recently added", "-date_live"],
	["Recently updated", "-date_updated"],
	["Most visited", "-visits_total"],
	["Most comments", "-comments_total"],
	["Alphabetical", "name"],
]


signal upload_mod_requested
signal upload_guide_requested
signal upload_collection_requested
signal upload_workshop_requested
signal closed

var menu = null

onready var account_bar = $"%AccountBar"
onready var title_button: Button = $"%Title"
onready var tab_bar: VBoxContainer = $"%TabBar"
onready var workshop_tab_bar: VBoxContainer = $"%WorkshopTabBar"
onready var tabs: TabContainer = $"%Tabs"
onready var footer: VBoxContainer = $"%Footer"
onready var website_btn: Button = $"%Website"
onready var upload_mod_btn: Button = $"%UploadMod"
onready var upload_guide_btn: Button = $"%UploadGuide"
onready var upload_collection_btn: Button = $"%UploadCollection"

onready var collection_detail = $"%CollectionDetail"
onready var collection_detail_back: Button = $"%DetailBack"
onready var collection_detail_title: Label = $"%DetailTitle"
onready var collection_detail_status: Label = $"%DetailStatus"
onready var collection_detail_list: GridContainer = $"%DetailList"

onready var collection_editor = $"%CollectionEditor"
onready var collection_editor_back: Button = $"%EditorBack"
onready var collection_editor_title: Label = $"%EditorTitle"
onready var collection_editor_status: Label = $"%EditorStatus"
onready var collection_editor_list: GridContainer = $"%EditorList"
onready var collection_name_edit: LineEdit = $"%CollectionNameEdit"
onready var collection_create_btn: Button = $"%CollectionCreateBtn"

onready var detail = $"%ModDetail"

var tab_buttons := []
var workshop_tab_buttons := []
var workshop_link_buttons := []
var views := []
var workshop_views := []

var _mode := "modio"
var _workshop = null
var _workshop_token := 0
var _last_modio_tab := 0

var collection_detail_rows := {}

var _mod_cache := {}
var _subscribed_ids := {}
var _user_collections := []
var _mod_collection_ids := {}
var _subscribed_loaded := false
var _collection_mod_id := 0
var _collection_mod_name := ""
var _current_collection := {}
var _return_to_detail := false

var _game_data := {}
var _placements := []
var _tags_loaded := false
var _guide_tags_loaded := false

var _compact := false
var _card_width := CARD_WIDTH
var _download_jobs := []
var _shown_bytes := -1

var _img_queue := []
var _img_request: HTTPRequest = null
var _img_busy := false
var _thumb_textures := {}

var _tooltip_panel: Panel = null
var _tooltip_label: Label = null
var _tooltip_mod_id := ""
var _tooltip_pinned := false


func _ready() -> void:
	$"%Close".connect("pressed", self, "_on_close_clicked")

	_setup_workshop()
	tab_buttons = tab_bar.get_children()
	for i in range(tab_buttons.size()):
		tab_buttons[i].connect("pressed", self, "_select_tab", [i])
	workshop_tab_buttons = workshop_tab_bar.get_children()
	for i in range(workshop_tab_buttons.size()):
		workshop_tab_buttons[i].connect("pressed", self, "_select_workshop_tab", [i])
	_build_workshop_links()

	_build_views()
	_connect_auth()
	_build_tooltip()
	_connect_controls()
	collection_detail_list.get_parent().connect("resized", self, "_apply_collection_columns")

	_img_request = HTTPRequest.new()
	add_child(_img_request)
	_img_request.use_threads = true
	_img_request.timeout = 20.0
	_img_request.connect("request_completed", self, "_on_thumb_received")

	_register_ui()
	for i in range(tab_buttons.size()):
		tab_buttons[i].set_pressed_no_signal(i == TAB_FEATURED)
	_update_footer()
	Global.connect("mobile_ui_changed", self, "adjust_ui")
	adjust_ui(Global.mobile_ui)


func _build_views() -> void:
	views = []
	for i in range(TAB_NAMES.size()):
		var view = TAB_VIEW_SCENE.instance()
		view.name = TAB_NAMES[i]
		tabs.add_child(view)
		view.setup(i, TAB_NAMES[i], _sort_options_for(i), i == TAB_FEATURED or i == TAB_MODS)
		view.set_timespan_options(TIMESPAN_OPTIONS)
		view.set_author_filters_visible(i == TAB_MODS or i == TAB_COLLECTIONS or i == TAB_GUIDES)
		view.set_subscribed_visible(i == TAB_MODS)
		view.prev_btn.connect("pressed", self, "_on_prev_pressed", [i])
		view.next_btn.connect("pressed", self, "_on_next_pressed", [i])
		view.compact_toggle.connect("toggled", self, "_on_compact_toggled", [i])
		view.search_edit.connect("text_entered", self, "_on_search_submitted", [i])
		view.search_btn.connect("pressed", self, "_on_search_pressed", [i])
		view.sort_option.connect("item_selected", self, "_on_sort_selected", [i])
		view.filter_option.connect("item_selected", self, "_on_filter_selected", [i])
		view.timespan_option.connect("item_selected", self, "_on_timespan_selected", [i])
		view.author_option.connect("item_selected", self, "_on_author_selected", [i])
		view.subscribed_check.connect("toggled", self, "_on_subscribed_toggled", [i])
		tabs.set_tab_title(tabs.get_tab_count() - 1, TAB_NAMES[i])
		views.append(view)
	_build_workshop_views()
	tabs.connect("tab_changed", self, "_on_tab_changed")


func _setup_workshop() -> void:
	_workshop = WORKSHOP_API_SCRIPT.new()
	add_child(_workshop)
	_workshop.connect("browse_loaded", self, "_on_workshop_loaded")
	_workshop.connect("browse_failed", self, "_on_workshop_failed")
	_workshop.connect("install_started", self, "_on_workshop_install_started")
	_workshop.connect("install_progress", self, "_on_workshop_install_progress")
	_workshop.connect("install_finished", self, "_on_workshop_install_finished")
	_workshop.connect("install_failed", self, "_on_workshop_install_failed")
	_workshop.connect("removed", self, "_on_workshop_removed")
	_workshop.connect("library_changed", self, "_on_workshop_library_changed")
	_workshop.connect("subscriptions_changed", self, "_on_workshop_subscriptions_changed")
	_workshop.connect("vote_loaded", self, "_on_workshop_vote_loaded")
	_workshop.connect("vote_set", self, "_on_workshop_vote_set")
	_workshop.connect("vote_failed", self, "_on_workshop_vote_failed")
	_update_mode_button()


func _build_workshop_links() -> void:
	var links = WORKSHOP_DISCUSSION_LINKS + WORKSHOP_ABOUT_LINKS
	for entry in links:
		var title = str(entry[0])
		var button = Button.new()
		button.text = _workshop_link_label(title)
		button.hint_tooltip = title + "\n" + str(entry[1])
		button.clip_text = true
		button.size_flags_horizontal = 3
		workshop_tab_bar.add_child(button)
		button.connect("pressed", self, "_on_workshop_link_pressed", [str(entry[2])])
		workshop_link_buttons.append(button)


func _workshop_link_label(title: String) -> String:
	if title == "Workshop Discussions":
		return "Workshop Talk"
	if title == "Game Discussions":
		return "Game Talk"
	if title == "About the Workshop":
		return "About Workshop"
	if title == "Your Only Move Is HUSTLE":
		return "Game Community"
	return title


func _build_workshop_views() -> void:
	workshop_views = []
	for i in range(WORKSHOP_TAB_NAMES.size()):
		var view = TAB_VIEW_SCENE.instance()
		view.name = "Workshop" + WORKSHOP_TAB_NAMES[i].replace(" ", "")
		tabs.add_child(view)
		var is_collections = i == WORKSHOP_TAB_COLLECTIONS
		view.setup(WORKSHOP_TAB_BASE + i, WORKSHOP_TAB_NAMES[i],
			_workshop_sort_options_for(i), not is_collections)
		view.set_card_width(_card_width)
		view.set_author_filters_visible(false)
		view.set_subscribed_visible(false)
		view.set_filter_visible(i == WORKSHOP_TAB_MY_ITEMS or i == WORKSHOP_TAB_EXPLORE)
		view.set_search_visible(i == WORKSHOP_TAB_EXPLORE)
		view.set_sort_visible(i == WORKSHOP_TAB_EXPLORE or i == WORKSHOP_TAB_MY_ITEMS)
		if i == WORKSHOP_TAB_EXPLORE:
			view.set_filter_label("Tag:")
			view.set_filter_options(WORKSHOP_TAG_OPTIONS, WORKSHOP_TAG_OPTIONS)
		if i == WORKSHOP_TAB_MY_ITEMS:
			view.set_filter_label("Show:")
			var source_labels := []
			var source_values := []
			for source in WORKSHOP_MY_ITEMS_SOURCES:
				source_labels.append(source[0])
				source_values.append(source[1])
			view.set_source_options(source_labels, source_values)
		if is_collections:
			view.set_controls_visible(false)
			view.status.visible = true
		view.prev_btn.connect("pressed", self, "_on_prev_pressed", [WORKSHOP_TAB_BASE + i])
		view.next_btn.connect("pressed", self, "_on_next_pressed", [WORKSHOP_TAB_BASE + i])
		view.compact_toggle.connect("toggled", self, "_on_compact_toggled", [WORKSHOP_TAB_BASE + i])
		view.search_edit.connect("text_entered", self, "_on_search_submitted", [WORKSHOP_TAB_BASE + i])
		view.search_btn.connect("pressed", self, "_on_search_pressed", [WORKSHOP_TAB_BASE + i])
		view.sort_option.connect("item_selected", self, "_on_sort_selected", [WORKSHOP_TAB_BASE + i])
		view.filter_option.connect("item_selected", self, "_on_workshop_filter_selected", [WORKSHOP_TAB_BASE + i])
		tabs.set_tab_title(tabs.get_tab_count() - 1, WORKSHOP_TAB_NAMES[i])
		workshop_views.append(view)


func _workshop_sort_options_for(index: int) -> Array:
	if index == WORKSHOP_TAB_MY_ITEMS:
		return WORKSHOP_MY_ITEMS_SORT_OPTIONS
	return WORKSHOP_SORT_OPTIONS


func _sort_options_for(index: int) -> Array:
	if index == TAB_FEATURED:
		return FEATURED_SORT_OPTIONS
	if index == TAB_COLLECTIONS:
		return COLLECTION_SORT_OPTIONS
	if index == TAB_GUIDES:
		return GUIDE_SORT_OPTIONS
	return MOD_SORT_OPTIONS


func _connect_controls() -> void:
	title_button.connect("pressed", self, "_on_mode_button_pressed")
	website_btn.connect("pressed", self, "_on_website_pressed")
	upload_mod_btn.connect("pressed", self, "_on_upload_mod_pressed")
	upload_guide_btn.connect("pressed", self, "_on_upload_guide_pressed")
	upload_collection_btn.connect("pressed", self, "_on_upload_collection_pressed")
	collection_detail_back.connect("pressed", self, "_close_collection_detail")
	collection_editor_back.connect("pressed", self, "_close_collection_editor")
	collection_create_btn.connect("pressed", self, "_on_create_collection_pressed")
	collection_name_edit.connect("text_entered", self, "_on_create_collection_pressed")
	detail.connect("back_pressed", self, "_close_detail")
	detail.connect("subscribe_pressed", self, "_on_subscribe_pressed")
	detail.connect("collections_pressed", self, "_on_collections_pressed")
	detail.connect("page_pressed", self, "_on_page_pressed")
	detail.connect("homepage_pressed", self, "_on_homepage_pressed")
	detail.connect("rate_pressed", self, "_on_rate_pressed")


func _register_ui() -> void:
	var registered = [
		$"%Close",
		title_button,
		website_btn,
		upload_mod_btn, upload_guide_btn, upload_collection_btn,
		collection_name_edit, collection_create_btn,
		collection_detail_back, collection_editor_back,
	]
	for view in views:
		registered.append(view.prev_btn)
		registered.append(view.next_btn)
		registered.append(view.compact_toggle)
		registered.append(view.search_edit)
		registered.append(view.search_btn)
		registered.append(view.sort_option)
		registered.append(view.filter_option)
		registered.append(view.timespan_option)
		if view.index == TAB_MODS or view.index == TAB_COLLECTIONS or view.index == TAB_GUIDES:
			registered.append(view.author_option)
		if view.index == TAB_MODS:
			registered.append(view.subscribed_check)
	for view in workshop_views:
		if view.index == WORKSHOP_TAB_BASE + WORKSHOP_TAB_COLLECTIONS:
			continue
		registered.append(view.prev_btn)
		registered.append(view.next_btn)
		registered.append(view.compact_toggle)
		registered.append(view.search_edit)
		registered.append(view.search_btn)
		registered.append(view.sort_option)
		registered.append(view.filter_option)
	for element in detail.ui_elements():
		registered.append(element)
	UIManager.register_menu(self, registered)
	for tab_btn in tab_buttons:
		UIManager.register_control(tab_btn, [tab_btn])
	for tab_btn in workshop_tab_buttons:
		UIManager.register_control(tab_btn, [tab_btn])
	for link_btn in workshop_link_buttons:
		UIManager.register_control(link_btn, [link_btn])


func _build_tooltip() -> void:
	_tooltip_panel = Panel.new()
	_tooltip_panel.visible = false
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.theme = theme
	get_parent().add_child(_tooltip_panel)
	_tooltip_label = Label.new()
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.autowrap = true
	_tooltip_panel.add_child(_tooltip_label)


func _connect_auth() -> void:
	ModIOAuth.connect("login_success", self, "_on_auth_changed")
	ModIOAuth.connect("logout_done", self, "_on_auth_changed")
	ModIOAuth.connect("user_updated", self, "_on_user_updated")


func open() -> void:
	if collection_editor.visible:
		_close_collection_editor()
	if detail.visible:
		_close_detail()
	if collection_detail.visible:
		_close_collection_detail()
	show()
	raise()
	var available = _workshop.is_available()
	_update_mode_button()
	if _mode == "workshop" and not available:
		_set_mode("modio")
	if _mode == "workshop":
		_workshop.refresh_subscriptions()
		var workshop_index = tabs.current_tab - WORKSHOP_TAB_BASE
		if workshop_index == WORKSHOP_TAB_COLLECTIONS:
			workshop_views[workshop_index].loaded = false
		_refresh_workshop_tab(workshop_index)
		return
	account_bar.refresh()
	if not ModIO.is_configured():
		_set_all_status("mod.io is not configured. Set game_id and api_key in modloader/modio/modio.cfg.")
		return
	if _game_data.empty():
		ModIO.request_game(self, "_on_game_received")
	if not _tags_loaded:
		ModIO.request_tag_options(self, "_on_tags_received")
	if not _guide_tags_loaded:
		ModIO.request_guide_tags(self, "_on_guide_tags_received")
	if _is_logged_in() and not _subscribed_loaded:
		_load_subscribed()
	_refresh_tab(tabs.current_tab)


func reload_current() -> void:
	if _mode == "workshop":
		_reload_current(true)
		return
	if views.empty():
		return
	_reload_tab(tabs.current_tab)


func _process(_delta) -> void:
	if _download_jobs.empty():
		return
	var bytes = ModIO.get_downloaded_bytes()
	if bytes < 0 or bytes == _shown_bytes:
		return
	_shown_bytes = bytes
	var job = _download_jobs[0]
	var total = int(job.size)
	var text = "..." if total <= 0 else "%s / %s" % [_fmt_bytes(bytes), _fmt_bytes(total)]
	_set_row_status(str(job.mod_id), text)


func _is_logged_in() -> bool:
	return ModIOAuth.is_logged_in()


func _require_login() -> bool:
	if _is_logged_in():
		return true
	account_bar.open_auth_window()
	return false


func _on_mode_button_pressed() -> void:
	if _mode == "workshop":
		_set_mode("modio")
	else:
		_set_mode("workshop")


func _set_mode(mode: String) -> void:
	if mode == _mode:
		return
	if mode == "workshop" and not _workshop.is_available():
		return
	_hide_tooltip()
	_close_detail()
	_close_collection_detail()
	_close_collection_editor()
	_mode = mode
	if mode == "workshop":
		if tabs.current_tab < WORKSHOP_TAB_BASE:
			_last_modio_tab = tabs.current_tab
		account_bar.visible = false
		upload_guide_btn.visible = false
		upload_collection_btn.visible = false
		website_btn.text = "Steam"
		tab_bar.visible = false
		workshop_tab_bar.visible = true
		_workshop.refresh_subscriptions()
		_select_workshop_tab(WORKSHOP_TAB_EXPLORE)
	else:
		account_bar.visible = true
		upload_guide_btn.visible = true
		upload_collection_btn.visible = true
		website_btn.text = "mod.io"
		tab_bar.visible = true
		workshop_tab_bar.visible = false
		if tabs.current_tab >= WORKSHOP_TAB_BASE or tabs.current_tab != _last_modio_tab:
			tabs.current_tab = _last_modio_tab
		_on_tab_changed(_last_modio_tab)
	_update_mode_button()


func _update_mode_button() -> void:
	var available = _workshop.is_available()
	title_button.text = "mod.io (swap)" if _mode == "modio" else "steam (swap)"
	title_button.disabled = _mode == "modio" and not available
	if title_button.disabled:
		title_button.hint_tooltip = "Steam Workshop is unavailable"
	elif _mode == "modio":
		title_button.hint_tooltip = "Switch to the Steam Workshop"
	else:
		title_button.hint_tooltip = "Switch to the mod.io workshop"


func adjust_ui(is_mobile: bool) -> void:
	$Layout/Sidebar.rect_min_size.x = MOBILE_SIDEBAR_WIDTH if is_mobile else SIDEBAR_WIDTH
	$Layout/Sidebar/TitleBar.rect_min_size.y = 25 if is_mobile else 20
	account_bar.set_compact(is_mobile)
	var contents = $Layout/Contents
	contents.rect_min_size.x = 0 if is_mobile else CONTENT_WIDTH
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_width = MOBILE_CARD_WIDTH if is_mobile else CARD_WIDTH
	for view in views:
		view.set_card_width(_card_width)
	for view in workshop_views:
		view.set_card_width(_card_width)
	_apply_collection_columns()


func _select_workshop_tab(index: int) -> void:
	if index < 0 or index >= workshop_views.size():
		return
	_close_detail()
	_close_collection_detail()
	_close_collection_editor()
	var target = WORKSHOP_TAB_BASE + index
	if tabs.current_tab == target:
		_on_workshop_tab_changed(index)
	else:
		tabs.current_tab = target


func _on_workshop_tab_changed(index: int) -> void:
	if index < 0 or index >= workshop_views.size():
		return
	_hide_tooltip()
	for i in range(workshop_tab_buttons.size()):
		workshop_tab_buttons[i].set_pressed_no_signal(i == index)
	if index == WORKSHOP_TAB_COLLECTIONS:
		workshop_views[index].loaded = false
	_refresh_workshop_tab(index)
	_update_footer()


func _refresh_workshop_tab(index: int) -> void:
	if index < 0 or index >= workshop_views.size():
		return
	var view = workshop_views[index]
	if view.searching or view.loaded:
		return
	_load_workshop_tab(index, true)


func _load_workshop_tab(index: int, reset: bool) -> void:
	if index < 0 or index >= workshop_views.size():
		return
	_hide_tooltip()
	var view = workshop_views[index]
	if index == WORKSHOP_TAB_COLLECTIONS:
		_render_workshop_collections(view)
		return
	if reset:
		view.offset = 0
		view.result_total = -1
	view.search = view.search_edit.text.strip_edges()
	view.clear_rows()
	view.searching = true
	_workshop_token += 1
	view.generation = _workshop_token
	view.status.text = "Loading..."
	_update_footer()
	if index == WORKSHOP_TAB_MY_ITEMS:
		if view.filter == "published":
			_workshop.request_published(view.sort, view.offset, view.generation)
		else:
			_workshop.request_subscribed(view.sort, view.offset, view.generation)
	else:
		_workshop.request_browse(view.sort, view.offset, view.generation, view.search, view.filter)


func _render_workshop_collections(view) -> void:
	view.searching = false
	view.loaded = true
	view.clear_rows()
	var collections = WORKSHOP_STORE.list_collections()
	for collection in collections:
		if typeof(collection) == TYPE_DICTIONARY:
			_add_workshop_collection_row(view, collection)
	view.result_total = collections.size()
	if collections.empty():
		view.status.text = "You have no Workshop collections yet. Open an item and press Collections to create one."
	else:
		view.status.text = "%d collection(s)" % collections.size()
	_update_footer()


func _add_workshop_collection_row(view, collection: Dictionary) -> void:
	var row = ROWS_SCRIPT.new()
	row.kind = "collection"
	view.list.add_child(row)
	row.connect("mods_pressed", self, "_on_open_collection_mods_pressed")
	row.connect("page_pressed", self, "_on_open_collection_page_pressed")
	row.setup(collection)
	row.set_page_visible(false)


func _on_workshop_link_pressed(url: String) -> void:
	_open_external(url)


func _view_at(index: int):
	if index >= WORKSHOP_TAB_BASE:
		var workshop_index = index - WORKSHOP_TAB_BASE
		if workshop_index >= 0 and workshop_index < workshop_views.size():
			return workshop_views[workshop_index]
		return null
	if index >= 0 and index < views.size():
		return views[index]
	return null


func _current_view():
	if _mode == "workshop":
		return _view_at(tabs.current_tab)
	if tabs.current_tab < 0 or tabs.current_tab >= views.size():
		return null
	return views[tabs.current_tab]


func _page_size_for(view) -> int:
	return WORKSHOP_PAGE_SIZE if view.index >= WORKSHOP_TAB_BASE else PAGE_SIZE


func _reload_index(index: int, reset: bool = true) -> void:
	if index >= WORKSHOP_TAB_BASE:
		_load_workshop_tab(index - WORKSHOP_TAB_BASE, reset)
	else:
		_load_tab(index, reset)


func _reload_current(reset: bool) -> void:
	if _mode == "workshop":
		_load_workshop_tab(tabs.current_tab - WORKSHOP_TAB_BASE, reset)
	else:
		_load_tab(tabs.current_tab, reset)


func _select_tab(index: int) -> void:
	if _mode == "workshop":
		_select_workshop_tab(index)
		return
	_close_detail()
	_close_collection_detail()
	_close_collection_editor()
	if tabs.current_tab == index:
		_on_tab_changed(index)
	else:
		tabs.current_tab = index


func _on_tab_changed(index: int) -> void:
	if tab_buttons.empty():
		return
	if index >= WORKSHOP_TAB_BASE:
		_on_workshop_tab_changed(index - WORKSHOP_TAB_BASE)
		return
	if index < 0 or index >= views.size():
		return
	_last_modio_tab = index
	_hide_tooltip()
	for i in range(tab_buttons.size()):
		tab_buttons[i].set_pressed_no_signal(i == index)
	_update_footer()
	_refresh_tab(index)


func _exit_tree() -> void:
	if is_instance_valid(_tooltip_panel):
		_tooltip_panel.queue_free()


func _on_compact_toggled(pressed: bool, _view_index: int) -> void:
	_compact = pressed
	for view in views:
		view.set_compact(pressed)
	for view in workshop_views:
		view.set_compact(pressed)
	for row in _all_rows():
		row.set_compact(pressed)
	_apply_collection_columns()
	if Global.mobile_ui:
		UIManager.reapply_menu(self)


func _apply_collection_columns() -> void:
	if _compact:
		collection_detail_list.columns = 1
		collection_detail_list.add_constant_override("v_separation", 0)
		return
	collection_detail_list.add_constant_override("v_separation", GRID_GAP)
	var scroll = collection_detail_list.get_parent()
	var width = int(scroll.rect_size.x) if scroll is Control else 0
	if width <= 0:
		collection_detail_list.columns = GRID_COLUMNS
		return
	collection_detail_list.columns = min(GRID_COLUMNS, max(1, int((width + GRID_GAP) / (_card_width + GRID_GAP))))


func _on_auth_changed() -> void:
	_subscribed_ids.clear()
	_subscribed_loaded = false
	_user_collections.clear()
	_mod_collection_ids.clear()
	_update_all_subscribe_states()
	_update_all_sign_in_states()
	if _is_logged_in():
		_load_subscribed()
	_reload_filter_views()
	if tabs.visible:
		_refresh_tab(tabs.current_tab)
	if collection_editor.visible:
		_render_collection_editor()


func _on_user_updated() -> void:
	_reload_filter_views()


func _reload_filter_views() -> void:
	for i in range(views.size()):
		var view = views[i]
		if view.author == "" and not view.subscribed_only:
			continue
		view.loaded = false
		if tabs.visible and i == tabs.current_tab:
			_reload_tab(i)


func _update_all_sign_in_states() -> void:
	var signed_in = _is_logged_in()
	for row in _all_rows():
		row.set_signed_in(signed_in)
	detail.set_signed_in(signed_in)


func _on_search_submitted(_text, index: int) -> void:
	_reload_index(index)


func _on_search_pressed(index: int) -> void:
	_reload_index(index)


func _on_sort_selected(item_index: int, view_index: int) -> void:
	var view = _view_at(view_index)
	if view == null:
		return
	if item_index < 0 or item_index >= view.sort_options.size():
		return
	view.sort = view.sort_options[item_index][1]
	_reload_index(view_index)


func _on_filter_selected(item_index: int, view_index: int) -> void:
	var view = views[view_index]
	if item_index < 0 or item_index >= view.filter_values.size():
		return
	view.filter = view.filter_values[item_index]
	_reload_tab(view_index)


func _on_workshop_filter_selected(item_index: int, view_index: int) -> void:
	var view = _view_at(view_index)
	if view == null:
		return
	if item_index < 0 or item_index >= view.filter_values.size():
		return
	view.filter = view.filter_values[item_index]
	_load_workshop_tab(view_index - WORKSHOP_TAB_BASE, true)


func _on_timespan_selected(item_index: int, view_index: int) -> void:
	var view = views[view_index]
	if item_index < 0 or item_index >= TIMESPAN_OPTIONS.size():
		return
	view.timespan = TIMESPAN_OPTIONS[item_index][1]
	view.timespan_set = true
	_reload_tab(view_index)


func _on_author_selected(item_index: int, view_index: int) -> void:
	var values = ["", "mine", "others"]
	if item_index < 0 or item_index >= values.size():
		return
	views[view_index].author = values[item_index]
	_reload_tab(view_index)


func _on_subscribed_toggled(pressed: bool, view_index: int) -> void:
	views[view_index].subscribed_only = pressed
	_reload_tab(view_index)


func _on_prev_pressed(index: int) -> void:
	var view = _view_at(index)
	if view == null:
		return
	view.offset = max(0, view.offset - _page_size_for(view))
	_reload_index(index, false)


func _on_next_pressed(index: int) -> void:
	var view = _view_at(index)
	if view == null:
		return
	view.offset += _page_size_for(view)
	_reload_index(index, false)


func _refresh_tab(index: int) -> void:
	if index < 0 or index >= views.size():
		return
	var view = views[index]
	if view.searching or view.loaded:
		return
	_load_tab(index, true)


func _reload_tab(index: int) -> void:
	if index < 0 or index >= views.size():
		return
	_load_tab(index, true)


func _load_tab(index: int, reset: bool) -> void:
	if index < 0 or index >= views.size():
		return
	_hide_tooltip()
	var view = views[index]
	view.search = view.search_edit.text.strip_edges()
	if reset:
		view.offset = 0
		view.result_total = -1
	if index == TAB_COLLECTIONS:
		_close_collection_detail()
	view.clear_rows()
	view.searching = true
	view.generation += 1
	view.status.text = "Loading..."
	_update_footer()
	if not _creator_filter_ready(view):
		return
	if index == TAB_COLLECTIONS:
		ModIO.request_collections_page(_collection_params(view), self, "_on_collections_received", [index, view.generation])
	elif index == TAB_GUIDES:
		ModIO.request_guides_page(_guide_params(view), self, "_on_guides_received", [index, view.generation])
	elif index == TAB_MODS and view.subscribed_only:
		ModIO.request_subscribed_page(_mod_params(view), self, "_on_mods_received", [index, view.generation])
	else:
		ModIO.request_mods_page(_mod_params(view), self, "_on_mods_received", [index, view.generation])


func _creator_filter_ready(view) -> bool:
	if view.author != "":
		if not _is_logged_in():
			view.searching = false
			view.status.text = "Sign in to filter by creator."
			_update_footer()
			return false
		if ModIOAuth.user_id <= 0:
			ModIOAuth.refresh_user()
			view.searching = false
			view.status.text = "Loading your mod.io profile..."
			_update_footer()
			return false
	if view.subscribed_only and not _is_logged_in():
		view.searching = false
		view.status.text = "Sign in to see your subscribed mods."
		_update_footer()
		return false
	return true


func _mod_params(view) -> Dictionary:
	var params = {"_sort": view.sort, "offset": view.offset, "limit": PAGE_SIZE}
	if view.search != "":
		params["_q"] = view.search
	if view.filter != "":
		params["tags"] = view.filter
	if view.index == TAB_FEATURED:
		var filters = _featured_filters()
		for key in filters:
			if key == "_sort" or key == "tags":
				continue
			params[key] = str(filters[key])
	if view.timespan_set:
		if view.timespan == "all_time":
			params.erase("timespan")
		else:
			params["timespan"] = view.timespan
	elif view.timespan != "all_time":
		params["timespan"] = view.timespan
	_apply_author_filter(params, view)
	return params


func _featured_filters() -> Dictionary:
	var placement = _featured_placement()
	if placement.empty():
		return {}
	var filters = placement.get("filters", {})
	if typeof(filters) != TYPE_DICTIONARY:
		return {}
	return filters


func _featured_placement() -> Dictionary:
	for placement in _placements:
		if typeof(placement) == TYPE_DICTIONARY and bool(placement.get("enabled", false)):
			return placement
	return {}


func _collection_params(view) -> Dictionary:
	var params = {"_sort": view.sort, "offset": view.offset, "limit": PAGE_SIZE}
	if view.search != "":
		params["_q"] = view.search
	if view.filter != "":
		params["collection-tags"] = view.filter
	if view.timespan_set and view.timespan != "" and view.timespan != "all_time":
		params["date_live-min"] = _timespan_timestamp(view.timespan)
	_apply_author_filter(params, view)
	return params


func _guide_params(view) -> Dictionary:
	var params = {"_sort": view.sort, "offset": view.offset, "limit": PAGE_SIZE}
	if view.search != "":
		params["_q"] = view.search
	if view.filter != "":
		params["tags"] = view.filter
	if view.timespan_set and view.timespan != "" and view.timespan != "all_time":
		params["date_live-min"] = _timespan_timestamp(view.timespan)
	_apply_author_filter(params, view)
	return params


func _apply_author_filter(params: Dictionary, view) -> void:
	if view.author == "":
		return
	if ModIOAuth.user_id <= 0:
		return
	if view.author == "mine":
		params["submitted_by"] = ModIOAuth.user_id
	elif view.author == "others":
		params["submitted_by-not"] = ModIOAuth.user_id


func _timespan_timestamp(timespan: String) -> int:
	var now = OS.get_unix_time()
	if timespan == "today":
		return now - 86400
	if timespan == "week":
		return now - 604800
	if timespan == "month":
		return now - 2592000
	if timespan == "3_months":
		return now - 7776000
	if timespan == "year":
		return now - 31536000
	return 0


func _on_mods_received(parsed, code, binds) -> void:
	var view = views[binds[0]]
	if int(binds[1]) != view.generation:
		return
	view.searching = false
	if not _valid_page(parsed):
		if code == 401:
			view.status.text = "Sign in to mod.io to see this list."
		else:
			view.status.text = "Couldn't reach mod.io (%s). %s" % [_http_label(code), _error_hint(code)]
		_update_footer()
		return
	view.loaded = true
	var mods = parsed.get("data", [])
	view.result_total = int(parsed.get("result_total", mods.size()))
	for mod in mods:
		if typeof(mod) == TYPE_DICTIONARY and mod.has("id"):
			_spawn_mod_row(view.list, mod, view.rows)
	_refresh_view_status(view)


func _on_collections_received(parsed, code, binds) -> void:
	var view = views[binds[0]]
	if int(binds[1]) != view.generation:
		return
	view.searching = false
	if not _valid_page(parsed):
		view.status.text = "Couldn't load collections (%s). %s" % [_http_label(code), _error_hint(code)]
		_update_footer()
		return
	view.loaded = true
	var collections = parsed.get("data", [])
	view.result_total = int(parsed.get("result_total", collections.size()))
	for collection in collections:
		if typeof(collection) == TYPE_DICTIONARY:
			_add_collection_row(view, collection)
	_refresh_view_status(view)


func _on_guides_received(parsed, code, binds) -> void:
	var view = views[binds[0]]
	if int(binds[1]) != view.generation:
		return
	view.searching = false
	if not _valid_page(parsed):
		view.status.text = "Couldn't load guides (%s). %s" % [_http_label(code), _error_hint(code)]
		_update_footer()
		return
	view.loaded = true
	var guides = parsed.get("data", [])
	view.result_total = int(parsed.get("result_total", guides.size()))
	for guide in guides:
		if typeof(guide) == TYPE_DICTIONARY:
			_add_guide_row(view, guide)
	_refresh_view_status(view)


func _valid_page(parsed) -> bool:
	return parsed != null and typeof(parsed) == TYPE_DICTIONARY and parsed.has("data")


func _refresh_view_status(view) -> void:
	if view.rows.empty() and view.list.get_child_count() == 0:
		view.status.text = "No results."
	else:
		var count = view.rows.size()
		if count == 0:
			count = view.list.get_child_count()
		view.status.text = "Showing %d of %d" % [count, view.result_total]
	_update_footer()


func _update_footer() -> void:
	if views.empty():
		return
	for view in views:
		_update_view_page(view)
	for view in workshop_views:
		_update_view_page(view)


func _update_view_page(view) -> void:
	var page_size = _page_size_for(view)
	var pages = int(ceil(view.result_total / float(page_size)))
	if pages < 1:
		pages = 1
	var page = int(view.offset / page_size) + 1
	view.set_page(page, pages)
	view.set_paging_enabled(view.offset > 0 and not view.searching,
		not view.searching and view.result_total > 0 and view.offset + page_size < view.result_total)


func _on_workshop_loaded(items, total, token) -> void:
	var view = _workshop_view_for_token(token)
	if view == null:
		return
	view.searching = false
	view.loaded = true
	view.result_total = int(total)
	for item in items:
		if typeof(item) == TYPE_DICTIONARY:
			_spawn_mod_row(view.list, item, view.rows)
	_refresh_view_status(view)


func _on_workshop_failed(message: String, token) -> void:
	var view = _workshop_view_for_token(token)
	if view == null:
		return
	view.searching = false
	view.status.text = message
	_update_footer()


func _workshop_view_for_token(token):
	for view in workshop_views:
		if view.generation == int(token):
			return view
	return null


func _on_workshop_install_started(item_id, _title) -> void:
	var id = str(item_id)
	_set_row_busy(id, true)
	_set_row_status(id, "Starting download...")
	_refresh_workshop_state(id)


func _on_workshop_install_progress(item_id, downloaded, total) -> void:
	var text = "..."
	if int(total) > 0:
		text = "%s / %s" % [_fmt_bytes(int(downloaded)), _fmt_bytes(int(total))]
	_set_row_status(str(item_id), text)


func _on_workshop_install_finished(item_id, entry) -> void:
	var id = str(item_id)
	_set_row_busy(id, false)
	_refresh_workshop_state(id)
	_set_row_status(id, "Subscribed - restart to load")
	if detail.visible and detail.mod_id == id:
		detail.set_status("Subscribed. Restart the game to load it.")
	status_line("Subscribed. Restart the game to load it.")


func _on_workshop_install_failed(item_id, message: String) -> void:
	var id = str(item_id)
	_set_row_busy(id, false)
	_set_row_status(id, message)
	status_line(message)


func _on_workshop_removed(item_id) -> void:
	var id = str(item_id)
	_set_row_busy(id, false)
	_set_row_status(id, "Removed")
	_refresh_workshop_state(id)
	if detail.visible and detail.mod_id == id:
		detail.set_status("Removed. Restart the game to unload it.")
	status_line("Removed. Restart the game to unload it.")


func _on_workshop_library_changed(item_id) -> void:
	var id = str(item_id)
	var was_listed = not _rows_for(id).empty()
	_refresh_workshop_state(id)
	if detail.visible and detail.mod_id == id:
		detail.set_status("Downloaded. Restart the game to load it.")
	if not was_listed:
		_reload_workshop_subscribed()


func _on_workshop_subscriptions_changed() -> void:
	for view in workshop_views:
		for row in view.rows.values():
			row.set_subscribed(_workshop.is_item_subscribed(row.mod_id))
	_reload_workshop_subscribed()


func _reload_workshop_subscribed() -> void:
	if workshop_views.size() <= WORKSHOP_TAB_MY_ITEMS:
		return
	var view = workshop_views[WORKSHOP_TAB_MY_ITEMS]
	view.loaded = false
	if _mode == "workshop" and tabs.current_tab == WORKSHOP_TAB_BASE + WORKSHOP_TAB_MY_ITEMS:
		_load_workshop_tab(WORKSHOP_TAB_MY_ITEMS, true)


func _refresh_workshop_state(item_id: String) -> void:
	var entry = WORKSHOP_STORE.get_entry(item_id)
	var state = {
		"workshop_state": str(entry.get("state", "")),
		"time_updated": int(entry.get("time_updated", 0)),
	}
	for row in _rows_for(item_id):
		row.set_install_state(state)
		row.set_subscribed(_workshop.is_item_subscribed(item_id))
	if detail.visible and detail.mod_id == item_id:
		detail.set_install_state(state)
		detail.set_subscribed(_workshop.is_item_subscribed(item_id))


func _set_all_status(text: String) -> void:
	for view in views:
		view.status.text = text


func _on_game_received(parsed, _code, _binds) -> void:
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return
	_game_data = parsed
	var placements = parsed.get("placements", [])
	_placements = placements if typeof(placements) == TYPE_ARRAY else []
	var collection_tags = parsed.get("collection_tag_options", [])
	if typeof(collection_tags) == TYPE_ARRAY and collection_tags.size() > 0:
		_fill_filter_options(views[TAB_COLLECTIONS], collection_tags)
	if not _placements.empty() and tabs.current_tab == TAB_FEATURED and views[TAB_FEATURED].loaded:
		_reload_tab(TAB_FEATURED)


func _on_tags_received(parsed, _code, _binds) -> void:
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		return
	_tags_loaded = true
	var groups = parsed.get("data", [])
	if typeof(groups) != TYPE_ARRAY:
		return
	_fill_filter_options(views[TAB_MODS], groups)
	_fill_filter_options(views[TAB_FEATURED], groups)


func _on_guide_tags_received(parsed, _code, _binds) -> void:
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		return
	_guide_tags_loaded = true
	var tags = parsed.get("data", [])
	if typeof(tags) != TYPE_ARRAY:
		return
	var labels := []
	var values := [""]
	for tag in tags:
		var name = ""
		if typeof(tag) == TYPE_DICTIONARY:
			name = str(tag.get("name", ""))
		elif typeof(tag) == TYPE_STRING:
			name = tag
		if name == "":
			continue
		labels.append(name)
		values.append(name)
	views[TAB_GUIDES].set_filter_options(labels, values)


func _fill_filter_options(view, groups: Array) -> void:
	var labels := []
	var values := [""]
	var tooltips := []
	for group in groups:
		if typeof(group) == TYPE_STRING:
			labels.append(_short_label(str(group)))
			values.append(str(group))
			tooltips.append(str(group))
			continue
		if typeof(group) != TYPE_DICTIONARY or bool(group.get("hidden", false)):
			continue
		var group_name = str(group.get("name", ""))
		var tags = group.get("tags", [])
		if typeof(tags) != TYPE_ARRAY:
			continue
		for tag in tags:
			var tag_name = str(tag)
			var label = tag_name if group_name == "" else "%s: %s" % [group_name.replace("_", " "), tag_name.replace("_", " ")]
			labels.append(_short_label(label))
			values.append(tag_name)
			tooltips.append(label)
	view.set_filter_options(labels, values)
	for i in range(tooltips.size()):
		view.filter_option.set_item_tooltip(i + 1, tooltips[i])


func _short_label(text: String, max_length: int = 28) -> String:
	if text.length() <= max_length:
		return text
	return text.left(max_length).strip_edges() + "…"


func _load_subscribed() -> void:
	ModIO.request_subscribed(0, 100, self, "_on_subscribed_received")


func _reload_subscribed_views() -> void:
	for i in range(views.size()):
		var view = views[i]
		if not view.subscribed_only:
			continue
		view.loaded = false
		if tabs.visible and i == tabs.current_tab:
			_reload_tab(i)


func _on_subscribed_received(parsed, _code, _binds) -> void:
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		return
	_subscribed_loaded = true
	_subscribed_ids.clear()
	var mods = parsed.get("data", [])
	for mod in mods:
		if typeof(mod) == TYPE_DICTIONARY and mod.has("id"):
			_subscribed_ids[str(mod.get("id"))] = true
			_cache_mod(mod)
	_update_all_subscribe_states()


func _add_detail_row(mod: Dictionary) -> void:
	_spawn_mod_row(collection_detail_list, mod, collection_detail_rows)


func _spawn_mod_row(parent: Container, mod: Dictionary, row_map: Dictionary):
	var mod_id = str(mod.get("id"))
	if row_map.has(mod_id):
		return row_map[mod_id]
	_cache_mod(mod)
	var is_workshop = bool(mod.get("workshop", false))
	var row = MOD_ROW_SCENE.instance()
	parent.add_child(row)
	_connect_mod_row(row)
	row.set_compact(_compact)
	row.setup(mod, _subscribed_ids.has(mod_id))
	row.set_workshop(is_workshop)
	row.set_square_thumb(is_workshop)
	if is_workshop:
		var entry = WORKSHOP_STORE.get_entry(mod_id)
		row.set_signed_in(true)
		row.set_subscribed(_workshop.is_item_subscribed(mod_id))
		row.set_install_state({
			"workshop_state": str(entry.get("state", "")),
			"time_updated": int(entry.get("time_updated", 0)),
		})
	else:
		row.set_signed_in(_is_logged_in())
		row.set_install_state(_install_state_for(mod_id))
	if _thumb_textures.has(mod_id):
		row.set_thumbnail(_thumb_textures[mod_id])
	row_map[mod_id] = row
	return row


func _connect_mod_row(row) -> void:
	row.connect("open_pressed", self, "_on_mod_open_pressed")
	row.connect("page_pressed", self, "_on_page_pressed")
	row.connect("subscribe_pressed", self, "_on_subscribe_pressed")
	row.connect("collections_pressed", self, "_on_collections_pressed")
	row.connect("thumbnail_requested", self, "_on_thumbnail_requested")
	row.connect("description_hovered", self, "_on_description_hovered")
	row.connect("description_clicked", self, "_on_description_clicked")
	row.connect("description_left", self, "_on_description_left")


func _add_collection_row(view, collection: Dictionary) -> void:
	var row = ROWS_SCRIPT.new()
	row.kind = "collection"
	view.list.add_child(row)
	row.connect("mods_pressed", self, "_on_open_collection_mods_pressed")
	row.connect("page_pressed", self, "_on_open_collection_page_pressed")
	row.setup(collection)


func _add_guide_row(view, guide: Dictionary) -> void:
	var row = ROWS_SCRIPT.new()
	row.kind = "guide"
	view.list.add_child(row)
	row.connect("open_pressed", self, "_on_open_guide_pressed")
	row.setup(guide)


func _on_open_collection_mods_pressed(collection: Dictionary) -> void:
	_current_collection = collection
	collection_detail_title.text = str(collection.get("name", "Collection"))
	collection_detail_status.text = "Loading mods..."
	collection_editor.visible = false
	_clear_rows_direct(collection_detail_list, collection_detail_rows)
	_apply_collection_columns()
	collection_detail.visible = true
	_hide_browser()
	_hide_tooltip()
	if _mode == "workshop" or bool(collection.get("workshop", false)):
		_render_workshop_collection_mods(collection)
		return
	ModIO.request_collection_mods(int(collection.get("id", 0)), self, "_on_collection_mods_received")


func _render_workshop_collection_mods(collection: Dictionary) -> void:
	var mods = collection.get("mods", [])
	if typeof(mods) != TYPE_ARRAY:
		mods = []
	for mod in mods:
		if typeof(mod) == TYPE_DICTIONARY and mod.has("id"):
			_add_detail_row(mod)
	collection_detail_status.text = "%d mod(s) in this collection" % collection_detail_list.get_child_count()


func _on_collection_mods_received(parsed, code, _binds) -> void:
	_clear_rows_direct(collection_detail_list, collection_detail_rows)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		collection_detail_status.text = "Couldn't load the mods of this collection (%s)." % _http_label(code)
		return
	var mods = parsed.get("data", [])
	for mod in mods:
		if typeof(mod) == TYPE_DICTIONARY and mod.has("id"):
			_add_detail_row(mod)
	collection_detail_status.text = "%d mod(s) in this collection" % collection_detail_list.get_child_count()


func _close_collection_detail() -> void:
	_current_collection = {}
	collection_detail.visible = false
	_clear_rows_direct(collection_detail_list, collection_detail_rows)
	_show_browser()


func _on_open_collection_page_pressed(collection: Dictionary) -> void:
	_hide_tooltip()
	var url = _collection_url(collection)
	if url == "":
		status_line("This collection has no mod.io page.")
		return
	ModIO.open_web_url(url)


func _collection_url(collection: Dictionary) -> String:
	var name_id = str(collection.get("name_id", ""))
	if name_id == "" or ModIO.web_url == "":
		return ""
	return ModIO.web_url + "/c/" + name_id


func _on_open_guide_pressed(guide: Dictionary) -> void:
	_hide_tooltip()
	var url = str(guide.get("url", ""))
	if url == "":
		status_line("This guide has no mod.io page.")
		return
	ModIO.open_web_url(url)


func _on_collections_pressed(mod_id: String) -> void:
	_hide_tooltip()
	if _mode == "workshop" or bool(_mod_cache.get(mod_id, {}).get("workshop", false)):
		_open_workshop_collection_editor(mod_id)
		return
	if not _require_login():
		return
	_collection_mod_id = int(mod_id)
	_show_collection_editor("mod")
	ModIO.request_collections(self, "_on_user_collections_received")
	ModIO.request_mod_collections(_collection_mod_id, self, "_on_mod_collections_received")


func _show_collection_editor(default_name: String) -> void:
	var mod = _mod_cache.get(str(_collection_mod_id), {})
	_collection_mod_name = str(mod.get("name", default_name))
	collection_editor_title.text = "Collections for \"%s\"" % _collection_mod_name
	collection_editor_status.text = "Loading your collections..."
	_return_to_detail = detail.visible
	detail.hide()
	collection_detail.visible = false
	collection_editor.visible = true
	_hide_browser()
	_clear_rows_direct(collection_editor_list)


func _open_workshop_collection_editor(mod_id: String) -> void:
	_collection_mod_id = int(mod_id)
	_show_collection_editor("item")
	_user_collections = WORKSHOP_STORE.list_collections()
	_mod_collection_ids.clear()
	for collection in _user_collections:
		var collection_id = int(collection.get("id", 0))
		if collection_id != 0 and WORKSHOP_STORE.has_item(collection_id, _collection_mod_id):
			_mod_collection_ids[collection_id] = true
	_render_collection_editor()


func _is_workshop_collections() -> bool:
	if _mode == "workshop":
		return true
	return bool(_mod_cache.get(str(_collection_mod_id), {}).get("workshop", false))


func _on_user_collections_received(parsed, code, _binds) -> void:
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		collection_editor_status.text = "Couldn't load your collections (%s)." % _http_label(code)
		return
	_user_collections = []
	for collection in parsed.get("data", []):
		if typeof(collection) == TYPE_DICTIONARY and int(collection.get("status", 0)) != 3:
			_user_collections.append(collection)
	_render_collection_editor()


func _on_mod_collections_received(parsed, code, _binds) -> void:
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		collection_editor_status.text = "Couldn't load the collections of this mod (%s)." % _http_label(code)
		return
	_mod_collection_ids.clear()
	for collection in parsed.get("data", []):
		if typeof(collection) == TYPE_DICTIONARY and collection.has("id"):
			_mod_collection_ids[int(collection.get("id"))] = true
	_render_collection_editor()


func _render_collection_editor() -> void:
	if collection_editor_list == null:
		return
	_clear_rows_direct(collection_editor_list)
	if _is_workshop_collections():
		_render_workshop_collection_editor()
		return
	if not _is_logged_in():
		collection_editor_status.text = "Sign in to manage your collections."
		return
	if _user_collections.empty():
		collection_editor_status.text = "You have no collections yet. Create one below."
		return
	collection_editor_status.text = "%d collection(s)" % _user_collections.size()
	for collection in _user_collections:
		if typeof(collection) != TYPE_DICTIONARY:
			continue
		var row = ROWS_SCRIPT.new()
		row.kind = "editor"
		collection_editor_list.add_child(row)
		row.connect("toggle_pressed", self, "_on_collection_toggle_pressed")
		row.setup(collection, _mod_collection_ids.has(int(collection.get("id", 0))))


func _render_workshop_collection_editor() -> void:
	_user_collections = WORKSHOP_STORE.list_collections()
	if _user_collections.empty():
		collection_editor_status.text = "You have no collections yet. Create one below."
		return
	collection_editor_status.text = "%d collection(s)" % _user_collections.size()
	for collection in _user_collections:
		if typeof(collection) != TYPE_DICTIONARY:
			continue
		var row = ROWS_SCRIPT.new()
		row.kind = "editor"
		collection_editor_list.add_child(row)
		row.connect("toggle_pressed", self, "_on_workshop_collection_toggle_pressed")
		row.setup(collection, _mod_collection_ids.has(int(collection.get("id", 0))))


func _on_workshop_collection_toggle_pressed(collection: Dictionary) -> void:
	var collection_id = int(collection.get("id", 0))
	if collection_id == 0 or _collection_mod_id == 0:
		return
	var name = str(collection.get("name", "collection"))
	if _mod_collection_ids.has(collection_id):
		WORKSHOP_STORE.remove_item(collection_id, _collection_mod_id)
		_mod_collection_ids.erase(collection_id)
		_invalidate_workshop_collections_tab()
		_render_collection_editor()
		collection_editor_status.text = "Removed from \"%s\"." % name
	else:
		var mod = _mod_cache.get(str(_collection_mod_id), {})
		WORKSHOP_STORE.add_item(collection_id, mod)
		_mod_collection_ids[collection_id] = true
		_invalidate_workshop_collections_tab()
		_render_collection_editor()
		collection_editor_status.text = "Added to \"%s\"." % name


func _invalidate_workshop_collections_tab() -> void:
	if workshop_views.empty():
		return
	workshop_views[WORKSHOP_TAB_COLLECTIONS].loaded = false


func _on_collection_toggle_pressed(collection: Dictionary) -> void:
	if not _require_login():
		return
	var collection_id = int(collection.get("id", 0))
	if collection_id == 0 or _collection_mod_id == 0:
		return
	if _mod_collection_ids.has(collection_id):
		ModIO.remove_collection_mod(collection_id, [_collection_mod_id], self,
			"_on_collection_membership_done", [collection, false])
	else:
		ModIO.add_collection_mod(collection_id, [_collection_mod_id], self,
			"_on_collection_membership_done", [collection, true])


func _on_collection_membership_done(_parsed, code, binds) -> void:
	var collection: Dictionary = binds[0]
	var added: bool = binds[1]
	var name = str(collection.get("name", "collection"))
	if code != 200 and code != 201 and code != 204:
		collection_editor_status.text = "Couldn't update \"%s\" (%s)." % [name, _http_label(code)]
		return
	var collection_id = int(collection.get("id", 0))
	if added:
		_mod_collection_ids[collection_id] = true
	else:
		_mod_collection_ids.erase(collection_id)
	_render_collection_editor()
	collection_editor_status.text = ("Added to \"" + name + "\".") if added else ("Removed from \"" + name + "\".")


func _on_create_collection_pressed(_text = "") -> void:
	if _is_workshop_collections():
		var title = collection_name_edit.text.strip_edges()
		if title == "":
			collection_editor_status.text = "Enter a name for your new collection."
			return
		var collection = WORKSHOP_STORE.create_collection(title)
		if _collection_mod_id != 0:
			var mod = _mod_cache.get(str(_collection_mod_id), {})
			WORKSHOP_STORE.add_item(int(collection.get("id", 0)), mod)
			_mod_collection_ids[int(collection.get("id", 0))] = true
		collection_name_edit.text = ""
		_invalidate_workshop_collections_tab()
		_render_collection_editor()
		collection_editor_status.text = "Created \"%s\"." % title
		return
	if not _require_login():
		return
	var title = collection_name_edit.text.strip_edges()
	if title == "":
		collection_editor_status.text = "Enter a name for your new collection."
		return
	var mod_ids = []
	if _collection_mod_id != 0:
		mod_ids.append(_collection_mod_id)
	collection_create_btn.disabled = true
	collection_editor_status.text = "Creating collection..."
	ModIO.create_collection(title, mod_ids, self, "_on_collection_created", [title])


func _on_collection_created(_parsed, code, binds) -> void:
	collection_create_btn.disabled = false
	var title = str(binds[0]) if binds.size() > 0 else "collection"
	if code != 200 and code != 201:
		collection_editor_status.text = "Couldn't create \"%s\" (%s)." % [title, _http_label(code)]
		return
	collection_name_edit.text = ""
	collection_editor_status.text = "Created \"%s\"." % title
	ModIO.request_collections(self, "_on_user_collections_received")
	ModIO.request_mod_collections(_collection_mod_id, self, "_on_mod_collections_received")


func _close_collection_editor() -> void:
	collection_editor.visible = false
	_clear_rows_direct(collection_editor_list)
	if _return_to_detail and detail.mod_id != "":
		_return_to_detail = false
		detail.show()
		_hide_browser()
	else:
		_show_browser()


func _on_subscribe_pressed(mod_id: String) -> void:
	_hide_tooltip()
	if _mode == "workshop" or bool(_mod_cache.get(mod_id, {}).get("workshop", false)):
		_on_workshop_subscribe(mod_id)
		return
	if not _require_login():
		return
	if not ModIO.is_configured():
		status_line("mod.io is not configured.")
		return
	_set_row_busy(mod_id, true)
	_set_row_status(mod_id, "Working...")
	var subscribed = _subscribed_ids.has(mod_id)
	ModIO.set_subscription(int(mod_id), not subscribed, self, "_on_subscription_done", [mod_id])


func _on_workshop_subscribe(mod_id: String) -> void:
	if _workshop.is_item_subscribed(mod_id):
		_remove_workshop_item(mod_id)
	else:
		_install_workshop_item(mod_id)


func _on_subscription_done(_parsed, code, binds) -> void:
	var mod_id = str(binds[0])
	if code != 200 and code != 201 and code != 204:
		_set_row_busy(mod_id, false)
		_set_row_status(mod_id, "")
		if code == 401:
			_require_login()
		status_line("Subscription change failed (%s)." % _http_label(code))
		return
	if _subscribed_ids.has(mod_id):
		_subscribed_ids.erase(mod_id)
		var had_file = not ModIO.get_installed(mod_id).empty()
		var had_pending = bool(_install_state_for(mod_id).get("pending", false))
		_delete_installed_mod(mod_id)
		_update_subscribe_state(mod_id)
		_set_row_busy(mod_id, false)
		if had_file:
			_set_row_status(mod_id, "Unsubscribed - removal applies on next launch")
			status_line("Unsubscribed. The mod file is removed the next time the game starts.")
		elif had_pending:
			_set_row_status(mod_id, "Unsubscribed")
			status_line("Unsubscribed. The pending download was discarded.")
		else:
			_set_row_status(mod_id, "Unsubscribed")
			status_line("Unsubscribed from mod.io.")
		_reload_subscribed_views()
		return
	_subscribed_ids[mod_id] = true
	_update_subscribe_state(mod_id)
	_reload_subscribed_views()
	_start_download(mod_id)


func _install_workshop_item(mod_id: String) -> void:
	var mod_data = _mod_cache.get(mod_id, {})
	var logo = mod_data.get("logo", {})
	var preview_url = ""
	if typeof(logo) == TYPE_DICTIONARY:
		preview_url = str(logo.get("original", logo.get("thumb_320x180", "")))
	_set_row_busy(mod_id, true)
	_set_row_status(mod_id, "Starting...")
	_workshop.install(int(mod_id), {
		"title": str(mod_data.get("name", "")),
		"author": str(mod_data.get("workshop_author", "")),
		"preview_url": preview_url,
		"time_updated": int(mod_data.get("workshop_time_updated", 0)),
	})


func _remove_workshop_item(mod_id: String) -> void:
	_set_row_busy(mod_id, true)
	_set_row_status(mod_id, "Removing...")
	_workshop.uninstall(int(mod_id))


func _delete_installed_mod(mod_id: String) -> void:
	WORKSHOP_STORE.modio_discard(mod_id)
	var installed = ModIO.get_installed(mod_id)
	if not installed.empty():
		var path = str(installed.get("path", ""))
		ModIO.queue_uninstall(mod_id)
		if menu != null and is_instance_valid(menu) and path != "":
			menu.remove_mod_by_zip(path)
	_refresh_row_states(mod_id)


func _start_download(mod_id: String) -> void:
	_set_row_busy(mod_id, true)
	_set_row_status(mod_id, "Downloading...")
	ModIO.request_mod_files(int(mod_id), self, "_on_mod_files_received", [mod_id])


func _on_mod_files_received(parsed, code, binds) -> void:
	var mod_id = str(binds[0])
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		_refresh_row_states(mod_id)
		_set_row_busy(mod_id, false)
		_set_row_status(mod_id, "")
		status_line("Couldn't fetch the mod files (%s). %s" % [_http_label(code), _error_hint(code)])
		return
	var files = parsed.get("data", [])
	if typeof(files) != TYPE_ARRAY or files.empty():
		_refresh_row_states(mod_id)
		_set_row_busy(mod_id, false)
		_set_row_status(mod_id, "")
		status_line("This mod has no downloadable file yet.")
		return
	files.sort_custom(self, "_sort_files_newest")
	var file = files[0]
	var binary_url = ""
	if typeof(file.get("download")) == TYPE_DICTIONARY:
		binary_url = str(file.download.get("binary_url", ""))
	if binary_url == "":
		ModIO.request_modfile_download_url(int(mod_id), int(file.get("id", 0)),
			self, "_on_modfile_received", [mod_id, file])
		return
	_begin_download(mod_id, file, binary_url)


func _on_modfile_received(parsed, code, binds) -> void:
	var mod_id = str(binds[0])
	var file = binds[1]
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("download"):
		_refresh_row_states(mod_id)
		_set_row_busy(mod_id, false)
		_set_row_status(mod_id, "")
		status_line("Couldn't fetch the download link (%s). %s" % [_http_label(code), _error_hint(code)])
		return
	_begin_download(mod_id, file, str(parsed.download.get("binary_url", "")))


func _sort_files_newest(a, b) -> bool:
	return int(a.get("date_added", 0)) > int(b.get("date_added", 0))


func _begin_download(mod_id: String, file: Dictionary, binary_url: String) -> void:
	var dest = WORKSHOP_STORE.modio_download_path(mod_id, file)
	var size = int(file.get("filesize", 0))
	var queued = not _download_jobs.empty()
	_download_jobs.append({"mod_id": mod_id, "size": size})
	_shown_bytes = -1
	_set_row_busy(mod_id, true)
	_set_row_status(mod_id, "Queued..." if queued else "Downloading...")
	ModIO.download(binary_url, dest, self, "_on_download_finished", [mod_id, file], size)


func _on_download_finished(ok: bool, payload, binds) -> void:
	var mod_id = str(binds[0])
	var file: Dictionary = binds[1]
	if not _download_jobs.empty():
		_download_jobs.pop_front()
	_shown_bytes = -1
	if not ok:
		_refresh_row_states(mod_id)
		_set_row_busy(mod_id, false)
		_set_row_status(mod_id, "Download failed")
		status_line("Download failed: %s" % str(payload))
		_start_next_download_status()
		return
	var dest = str(payload)
	var mod_data: Dictionary = _mod_cache.get(mod_id, {})
	var mod_name = str(mod_data.get("name", ""))
	WORKSHOP_STORE.modio_record_pending(mod_id, mod_data, dest, file)
	_refresh_row_states(mod_id)
	if detail.visible and str(detail.mod_id) == mod_id:
		detail.set_install_state(_install_state_for(mod_id))
	_set_row_busy(mod_id, false)
	_set_row_status(mod_id, "Queued for next launch")
	var display_name = mod_name if mod_name != "" else dest.get_file()
	status_line("Downloaded \"%s\". It installs the next time the game starts." % display_name)
	_start_next_download_status()


func _start_next_download_status() -> void:
	if _download_jobs.empty():
		return
	_set_row_status(str(_download_jobs[0].mod_id), "Downloading...")


func _on_mod_open_pressed(mod_id: String) -> void:
	_hide_tooltip()
	_close_collection_detail()
	_close_collection_editor()
	var mod_data: Dictionary = _mod_cache.get(mod_id, {})
	if mod_data.empty():
		status_line("This mod is no longer available.")
		return
	_return_to_detail = false
	var is_workshop = bool(mod_data.get("workshop", false))
	detail.set_workshop(is_workshop)
	detail.open(mod_data)
	detail.set_subscribed(_subscribed_ids.has(mod_id))
	if is_workshop:
		var entry = WORKSHOP_STORE.get_entry(mod_id)
		detail.set_signed_in(true)
		detail.set_subscribed(_workshop.is_item_subscribed(mod_id))
		detail.set_install_state({
			"workshop_state": str(entry.get("state", "")),
			"time_updated": int(entry.get("time_updated", 0)),
		})
		detail.set_comments_status("Steam Workshop comments are not available in-game.")
		_hide_browser()
		_workshop.request_vote(int(mod_id))
		return
	detail.set_signed_in(_is_logged_in())
	detail.set_install_state(_install_state_for(mod_id))
	_hide_browser()
	ModIO.request_mod(int(mod_id), self, "_on_detail_mod_received", [mod_id])
	ModIO.request_mod_comments(int(mod_id), self, "_on_detail_comments_received", [mod_id])


func _on_detail_mod_received(parsed, code, binds) -> void:
	var mod_id = str(binds[0])
	if detail.mod_id != mod_id:
		return
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("id"):
		detail.set_status("Couldn't load this mod's details (%s). %s" % [_http_label(code), _error_hint(code)])
		return
	_cache_mod(parsed)
	detail.show_mod(parsed)
	detail.set_subscribed(_subscribed_ids.has(mod_id))
	detail.set_signed_in(_is_logged_in())
	detail.set_install_state(_install_state_for(mod_id))


func _on_detail_comments_received(parsed, code, binds) -> void:
	var mod_id = str(binds[0])
	if detail.mod_id != mod_id:
		return
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("data"):
		detail.set_comments_status("Couldn't load comments (%s)." % _http_label(code))
		return
	var comments = parsed.get("data", [])
	detail.set_comments(comments if typeof(comments) == TYPE_ARRAY else [])


func _close_detail() -> void:
	detail.hide()
	_return_to_detail = false
	_show_browser()


func _hide_browser() -> void:
	tabs.visible = false
	tab_bar.visible = false
	workshop_tab_bar.visible = false
	footer.visible = false


func _show_browser() -> void:
	tabs.visible = true
	footer.visible = true
	if _mode == "workshop":
		tab_bar.visible = false
		workshop_tab_bar.visible = true
		var index = tabs.current_tab - WORKSHOP_TAB_BASE
		if index == WORKSHOP_TAB_COLLECTIONS:
			workshop_views[index].loaded = false
			_refresh_workshop_tab(index)
	else:
		tab_bar.visible = true
		workshop_tab_bar.visible = false


func _on_homepage_pressed(url: String) -> void:
	_hide_tooltip()
	if url == "":
		detail.set_status("This mod has no homepage.")
		return
	ModIO.open_web_url(url)


func _on_rate_pressed(mod_id: String, rating: int) -> void:
	_hide_tooltip()
	if _mode == "workshop" or bool(_mod_cache.get(mod_id, {}).get("workshop", false)):
		if detail.visible and detail.mod_id == mod_id:
			detail.set_status("Saving your vote...")
		_workshop.request_set_vote(int(mod_id), rating > 0)
		return
	if not _require_login():
		return
	detail.set_status("Saving your rating...")
	ModIO.set_mod_rating(int(mod_id), rating, self, "_on_rating_done", [mod_id, rating])


func _on_workshop_vote_loaded(file_id, vote_up, vote_down, _vote_skipped) -> void:
	if not detail.visible or detail.mod_id != str(file_id):
		return
	var value := 0
	if vote_up:
		value = 1
	elif vote_down:
		value = -1
	detail.set_vote(value)


func _on_workshop_vote_set(file_id, vote_up, _result) -> void:
	if not detail.visible or detail.mod_id != str(file_id):
		return
	detail.set_vote(1 if vote_up else -1)
	detail.set_status("Thanks for voting.")


func _on_workshop_vote_failed(_file_id, message: String) -> void:
	if detail.visible:
		detail.set_status(message)
	else:
		status_line(message)


func _on_rating_done(_parsed, code, binds) -> void:
	var mod_id = str(binds[0])
	if code != 200 and code != 201:
		if code == 401:
			_require_login()
		detail.set_status("Couldn't save your rating (%s)." % _http_label(code))
		return
	if detail.mod_id == mod_id:
		detail.set_status("Thanks for rating this mod.")
		ModIO.request_mod(int(mod_id), self, "_on_detail_mod_received", [mod_id])


func _on_page_pressed(mod_id: String) -> void:
	_hide_tooltip()
	if _mode == "workshop":
		var workshop_data: Dictionary = _mod_cache.get(mod_id, {})
		if detail.visible and detail.mod_id == mod_id:
			workshop_data = detail.mod_data
		_open_external(str(workshop_data.get("profile_url", "")))
		return
	var mod_data: Dictionary = _mod_cache.get(mod_id, {})
	if detail.visible and detail.mod_id == mod_id:
		mod_data = detail.mod_data
	var url = str(mod_data.get("profile_url", ""))
	if url == "":
		var row = _find_row(mod_id)
		if row != null:
			url = row.profile_url()
	if url == "":
		url = ModIO.web_url
	ModIO.open_web_url(url)


func _on_website_pressed() -> void:
	_hide_tooltip()
	if _mode == "workshop":
		_open_external(_workshop.web_url())
		return
	ModIO.open_web_url(ModIO.web_url)


func _open_external(url: String) -> void:
	if not (ModIO.is_allowed_url(url) or _is_workshop_url(url)):
		return
	if Steam.getAppID() != 0:
		Steam.activateGameOverlayToWebPage(url)
	else:
		OS.shell_open(url)


func _is_workshop_url(url: String) -> bool:
	var lower = url.to_lower()
	return lower.begins_with("https://steamcommunity.com/") \
		or lower.begins_with("https://www.steamcommunity.com/")


func _on_upload_mod_pressed() -> void:
	_hide_tooltip()
	if _mode == "workshop":
		emit_signal("upload_workshop_requested")
		return
	emit_signal("upload_mod_requested")


func _on_upload_guide_pressed() -> void:
	_hide_tooltip()
	emit_signal("upload_guide_requested")


func _on_upload_collection_pressed() -> void:
	_hide_tooltip()
	emit_signal("upload_collection_requested")


func _on_close_clicked() -> void:
	_hide_tooltip()
	hide()
	emit_signal("closed")


func status_line(text: String) -> void:
	if detail.visible:
		detail.set_status(text)
		return
	if collection_editor.visible:
		collection_editor_status.text = text
		return
	if collection_detail.visible:
		collection_detail_status.text = text
		return
	if views.empty():
		return
	var view = _current_view()
	if view != null:
		view.status.text = text


func _update_all_subscribe_states() -> void:
	for row in _all_rows():
		row.set_subscribed(_subscribed_ids.has(row.mod_id))
	if detail.mod_id != "":
		detail.set_subscribed(_subscribed_ids.has(detail.mod_id))


func _update_subscribe_state(mod_id: String) -> void:
	var subscribed = _subscribed_ids.has(mod_id)
	for row in _rows_for(mod_id):
		row.set_subscribed(subscribed)
	if detail.mod_id == mod_id:
		detail.set_subscribed(subscribed)


func _refresh_row_states(mod_id: String) -> void:
	var state = _install_state_for(mod_id)
	for row in _rows_for(mod_id):
		row.set_install_state(state)


func _install_state_for(mod_id: String) -> Dictionary:
	var state = ModIO.get_installed(mod_id)
	var pending = WORKSHOP_STORE.modio_pending().get(mod_id, {})
	if typeof(pending) == TYPE_DICTIONARY and not pending.empty():
		state = state.duplicate()
		state["pending"] = true
	return state


func _set_row_busy(mod_id: String, value: bool) -> void:
	for row in _rows_for(mod_id):
		row.set_busy(value)
	if detail.mod_id == mod_id:
		detail.subscribe_btn.disabled = value


func _set_row_status(mod_id: String, text: String) -> void:
	for row in _rows_for(mod_id):
		row.set_status(text)
	if detail.mod_id == mod_id:
		detail.set_status(text)


func _cache_mod(mod: Dictionary) -> void:
	_mod_cache[str(mod.get("id"))] = mod


func _find_row(mod_id: String):
	var rows = _rows_for(mod_id)
	return rows[0] if not rows.empty() else null


func _rows_for(mod_id: String) -> Array:
	var result := []
	for view in views:
		if view.rows.has(mod_id):
			result.append(view.rows[mod_id])
	for view in workshop_views:
		if view.rows.has(mod_id):
			result.append(view.rows[mod_id])
	if collection_detail_rows.has(mod_id):
		result.append(collection_detail_rows[mod_id])
	return result


func _all_rows() -> Array:
	var result := []
	for view in views:
		for row in view.rows.values():
			result.append(row)
	for view in workshop_views:
		for row in view.rows.values():
			result.append(row)
	for row in collection_detail_rows.values():
		result.append(row)
	return result


func _clear_rows_direct(parent: Container, row_map = null) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
	if row_map != null:
		row_map.clear()


func _on_thumbnail_requested(mod_id: String, url: String) -> void:
	if url == "":
		return
	var tex = MODIO_IMAGE.read_cached_texture(MODIO_IMAGE.thumb_path(mod_id), THUMB_SIZE)
	if tex != null:
		_apply_thumbnail(mod_id, tex)
		return
	for entry in _img_queue:
		if str(entry.mod_id) == mod_id:
			return
	_img_queue.append({"mod_id": mod_id, "url": url})
	_pump_thumb_queue()


func _apply_thumbnail(mod_id: String, texture) -> void:
	if texture == null:
		return
	_thumb_textures[mod_id] = texture
	for row in _rows_for(mod_id):
		row.set_thumbnail(texture)


func _pump_thumb_queue() -> void:
	if _img_queue.empty() or _img_busy:
		return
	var next = _img_queue.front()
	if not ModIO.is_allowed_image_url(str(next.url)) or _img_request.request(next.url) != OK:
		_img_queue.pop_front()
		_pump_thumb_queue()
	else:
		_img_busy = true


func _on_thumb_received(result, code, _headers, body) -> void:
	_img_busy = false
	var current = _img_queue.pop_front() if _img_queue.size() > 0 else null
	if current != null and result == HTTPRequest.RESULT_SUCCESS and code == 200 \
	and body.size() <= ModIO.MAX_IMAGE_BYTES:
		var mod_id = str(current.mod_id)
		var f = File.new()
		if f.open(MODIO_IMAGE.thumb_path(mod_id), File.WRITE) == OK:
			f.store_buffer(body)
			f.close()
		_apply_thumbnail(mod_id, MODIO_IMAGE.texture_from_bytes(body, THUMB_SIZE))
	_pump_thumb_queue()


func _fmt_bytes(value: int) -> String:
	return "%.1f MB" % (value / 1048576.0)


func _http_label(code: int) -> String:
	if code == 0:
		return "no connection"
	return "HTTP %d" % code


func _error_hint(code: int) -> String:
	if code == 401:
		return "The API key was rejected - check modio.cfg."
	if code == 400:
		return "The request was rejected - check the game_id in modio.cfg."
	if code == 429:
		return "Too many requests, wait a moment and try again."
	return "Check your connection and try again."


func _wrap_tooltip_text(text: String) -> String:
	var font = _tooltip_label.get_font("font")
	var lines := []
	for raw_line in text.split("\n"):
		var words = raw_line.split(" ", false)
		if words.empty():
			lines.append("")
			continue
		var line = ""
		for word in words:
			var candidate = word if line == "" else line + " " + word
			if line != "" and font.get_string_size(candidate).x > TOOLTIP_WIDTH:
				lines.append(line)
				line = word
			else:
				line = candidate
		lines.append(line)
	if lines.size() > TOOLTIP_MAX_LINES:
		lines = lines.slice(0, TOOLTIP_MAX_LINES)
		lines[TOOLTIP_MAX_LINES - 1] = lines[TOOLTIP_MAX_LINES - 1] + "..."
	var out := PoolStringArray()
	for line in lines:
		out.append(line)
	return out.join("\n")


func _on_description_hovered(mod_id: String, text: String, pos: Vector2) -> void:
	if _tooltip_pinned and _tooltip_mod_id == mod_id:
		return
	_tooltip_mod_id = mod_id
	_tooltip_pinned = false
	_show_tooltip(text, pos)


func _on_description_clicked(mod_id: String, text: String, pos: Vector2) -> void:
	if _tooltip_pinned and _tooltip_mod_id == mod_id:
		_hide_tooltip()
		return
	_tooltip_mod_id = mod_id
	_tooltip_pinned = true
	_show_tooltip(text, pos)


func _on_description_left(mod_id: String) -> void:
	if _tooltip_pinned:
		return
	if _tooltip_mod_id == mod_id:
		_hide_tooltip()


func _show_tooltip(text: String, pos: Vector2) -> void:
	if text == "":
		return
	_tooltip_label.rect_size = Vector2(TOOLTIP_WIDTH, 0)
	_tooltip_label.text = _wrap_tooltip_text(text)
	var height = _tooltip_label.get_minimum_size().y
	_tooltip_label.rect_position = Vector2(TOOLTIP_PAD, TOOLTIP_PAD)
	_tooltip_label.rect_size = Vector2(TOOLTIP_WIDTH, height)
	var size = Vector2(TOOLTIP_WIDTH + TOOLTIP_PAD * 2, height + TOOLTIP_PAD * 2)
	_tooltip_panel.rect_size = size
	_tooltip_panel.visible = true
	_tooltip_panel.raise()
	var view_size = get_viewport_rect().size
	var target = pos + Vector2(14, 14)
	target.x = clamp(target.x, 0, max(0, view_size.x - size.x))
	target.y = clamp(target.y, 0, max(0, view_size.y - size.y))
	_tooltip_panel.rect_global_position = target


func _hide_tooltip() -> void:
	_tooltip_mod_id = ""
	_tooltip_pinned = false
	_tooltip_panel.visible = false


func _gui_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		_hide_tooltip()
	elif event is InputEventScreenTouch and event.pressed:
		_hide_tooltip()
