extends Node

signal browse_loaded(items, total, token)
signal browse_failed(message, token)
signal install_started(item_id, title)
signal install_progress(item_id, downloaded, total)
signal install_finished(item_id, entry)
signal install_failed(item_id, message)
signal removed(item_id)
signal vote_loaded(file_id, vote_up, vote_down, vote_skipped)
signal vote_set(file_id, vote_up, result)
signal vote_failed(file_id, message)
signal subscriptions_changed
signal library_changed(item_id)
signal details_loaded(item_id, details)
signal details_failed(item_id, message)
signal comments_loaded(item_id, comments)
signal comments_failed(item_id, message)
signal item_deleted(item_id)
signal delete_failed(item_id, message)

const WORKSHOP_STORE := preload("res://modloader/modio/WorkshopStore.gd")

const WORKSHOP_APP_ID := 2212330
const COMMENTS_URL := "https://steamcommunity.com/sharedfiles/filedetails/?id=%d&l=english"
const MAX_COMMENTS_BYTES := 4 * 1024 * 1024
const MAX_COMMENTS := 15

const QUERY_RANKED_BY_VOTE := 0
const QUERY_RANKED_BY_PUBLICATION := 1
const QUERY_RANKED_BY_TREND := 3

const MATCH_ITEMS := 0

const LIST_PUBLISHED := 0
const LIST_SUBSCRIBED := 6

const SORT_CREATION_DESC := 0
const SORT_TITLE_ASC := 2
const SORT_LAST_UPDATED_DESC := 3
const SORT_SUBSCRIPTION_DESC := 4

const STATE_SUBSCRIBED := 1
const STATE_INSTALLED := 4
const STATE_NEEDS_UPDATE := 8
const STATE_DOWNLOADING := 16
const STATE_DOWNLOAD_PENDING := 32

const PAGE_SIZE := 50
const POLL_INTERVAL := 0.5

var _query_handle := -1
var _query_token := 0
var _subscribed := {}
var _jobs := {}
var _poll_elapsed := 0.0
var _pending_vote_id := 0

var _detail_handle := -1
var _detail_item_id := 0
var _detail_target = null
var _detail_callback := ""
var _detail_binds := []

var _comment_requests := {}
var _comment_cache := {}


func _ready() -> void:
	Steam.connect("ugc_query_completed", self, "_on_query_completed")
	Steam.connect("get_item_vote_result", self, "_on_get_item_vote_result")
	Steam.connect("set_user_item_vote", self, "_on_set_user_item_vote")
	if Steam.has_signal("item_installed"):
		Steam.connect("item_installed", self, "_on_item_installed")
	if Steam.has_signal("item_downloaded"):
		Steam.connect("item_downloaded", self, "_on_item_downloaded")
	if Steam.has_signal("user_subscribed_items_list_changed"):
		Steam.connect("user_subscribed_items_list_changed", self, "_on_subscriptions_changed")
	if Steam.has_signal("item_deleted"):
		Steam.connect("item_deleted", self, "_on_item_delete_result")


func is_available() -> bool:
	if Global.is_mobile_device:
		return false
	if not SteamHustle.STARTED:
		return false
	if not SteamHustle.WORKSHOP_ENABLED:
		return false
	if not SteamHustle.IS_OWNED:
		return false
	if int(Steam.getAppID()) != WORKSHOP_APP_ID:
		return false
	if not Engine.has_singleton("Steam"):
		return false
	var native = Engine.get_singleton("Steam")
	for method in ["createQueryAllUGCRequest", "getItemState", "getItemInstallInfo"]:
		if not native.has_method(method):
			return false
	return true


func app_id() -> int:
	return WORKSHOP_APP_ID


func web_url() -> String:
	return "https://steamcommunity.com/app/%d/workshop/" % WORKSHOP_APP_ID


func refresh_subscriptions() -> void:
	_subscribed.clear()
	var items = Steam.getSubscribedItems()
	if items == null:
		return
	for item in items:
		_subscribed[str(item)] = true


func is_item_subscribed(item_id) -> bool:
	return _subscribed.has(str(item_id))


func request_vote(item_id: int) -> void:
	if not is_available():
		return
	_pending_vote_id = item_id
	Steam.getUserItemVote(item_id)


func request_set_vote(item_id: int, vote_up: bool) -> void:
	if not is_available():
		emit_signal("vote_failed", item_id, "Steam Workshop is not available.")
		return
	Steam.setUserItemVote(item_id, vote_up)


func request_browse(sort_key: String, offset: int, token: int, search: String = "", tag: String = "") -> void:
	if not is_available():
		emit_signal("browse_failed", "Steam Workshop is not available.", token)
		return
	var query = QUERY_RANKED_BY_TREND
	if sort_key == "vote":
		query = QUERY_RANKED_BY_VOTE
	elif sort_key == "publication":
		query = QUERY_RANKED_BY_PUBLICATION
	var page = int(offset / PAGE_SIZE) + 1
	var handle = Steam.createQueryAllUGCRequest(query, MATCH_ITEMS, app_id(), app_id(), page)
	if int(handle) > 0 and search != "":
		Steam.setSearchText(handle, search)
	if int(handle) > 0 and tag != "":
		Steam.addRequiredTag(handle, tag)
	_start_query(handle, token)


func request_subscribed(sort_key: String, offset: int, token: int, search: String = "", tag: String = "") -> void:
	if not is_available():
		emit_signal("browse_failed", "Steam Workshop is not available.", token)
		return
	var page = int(offset / PAGE_SIZE) + 1
	var handle = Steam.createQueryUserUGCRequest(Steam.getSteamID(), LIST_SUBSCRIBED,
		MATCH_ITEMS, _user_sort(sort_key), app_id(), app_id(), page)
	if int(handle) > 0 and search != "":
		Steam.setSearchText(handle, search)
	if int(handle) > 0 and tag != "":
		Steam.addRequiredTag(handle, tag)
	_start_query(handle, token)


func request_published(sort_key: String, offset: int, token: int) -> void:
	if not is_available():
		emit_signal("browse_failed", "Steam Workshop is not available.", token)
		return
	var page = int(offset / PAGE_SIZE) + 1
	var handle = Steam.createQueryUserUGCRequest(Steam.getSteamID(), LIST_PUBLISHED,
		MATCH_ITEMS, _user_sort(sort_key), app_id(), app_id(), page)
	_start_query(handle, token)


func _user_sort(sort_key: String) -> int:
	if sort_key == "title":
		return SORT_TITLE_ASC
	if sort_key == "updated":
		return SORT_LAST_UPDATED_DESC
	if sort_key == "subscription":
		return SORT_SUBSCRIPTION_DESC
	return SORT_CREATION_DESC


func _start_query(handle, token: int) -> void:
	if int(handle) <= 0:
		emit_signal("browse_failed", "Couldn't start the Workshop query.", token)
		return
	if _query_handle >= 0:
		Steam.releaseQueryUGCRequest(_query_handle)
	_query_handle = int(handle)
	_query_token = token
	Steam.sendQueryUGCRequest(_query_handle)


func _on_query_completed(handle, result, results_returned, total_matching, _cached) -> void:
	if int(handle) == _detail_handle:
		_finish_detail_query(int(handle), int(result), int(results_returned))
		return
	if int(handle) != _query_handle:
		return
	var token = _query_token
	var items := []
	if int(result) == 1:
		for index in range(int(results_returned)):
			var item = _read_result(index)
			if not item.empty():
				items.append(item)
		Steam.releaseQueryUGCRequest(_query_handle)
		_query_handle = -1
		emit_signal("browse_loaded", items, int(total_matching), token)
		return
	Steam.releaseQueryUGCRequest(_query_handle)
	_query_handle = -1
	emit_signal("browse_failed", "Steam returned an error (%s)." % str(result), token)


func _on_get_item_vote_result(result, file_id, vote_up, vote_down, vote_skipped) -> void:
	if int(result) != 1:
		return
	if int(file_id) != _pending_vote_id:
		return
	_pending_vote_id = 0
	emit_signal("vote_loaded", int(file_id), bool(vote_up), bool(vote_down), bool(vote_skipped))


func _on_set_user_item_vote(result, file_id, vote_up) -> void:
	if int(result) == 1:
		emit_signal("vote_set", int(file_id), bool(vote_up), int(result))
	else:
		emit_signal("vote_failed", int(file_id), "Couldn't save your vote (%s)." % str(result))


func _on_item_installed(_app_id, file_id) -> void:
	refresh_subscriptions()
	emit_signal("library_changed", int(file_id))


func _on_item_downloaded(_result, file_id, _app_id) -> void:
	refresh_subscriptions()
	emit_signal("library_changed", int(file_id))


func _on_subscriptions_changed(_app_id) -> void:
	refresh_subscriptions()
	emit_signal("subscriptions_changed")


func _read_result(index: int, handle: int = -1) -> Dictionary:
	var query = _query_handle if handle < 0 else handle
	var result = Steam.getQueryUGCResult(query, index)
	if typeof(result) != TYPE_DICTIONARY or result.empty():
		return {}
	if int(result.get("result", 1)) != 1:
		return {}
	var item_id = int(result.get("file_id", result.get("published_file_id", 0)))
	if item_id == 0:
		return {}

	var preview_url := str(Steam.getQueryUGCPreviewURL(query, index))
	if preview_url == "":
		preview_url = str(result.get("preview_url", result.get("file_url", "")))

	var owner_id = int(result.get("steam_id_owner", result.get("creator", 0)))
	var author := ""
	if owner_id != 0:
		author = str(Steam.getFriendPersonaName(owner_id)).strip_edges()
	if author == "":
		author = "Steam user"

	var tags := []
	var raw_tags = result.get("tags", [])
	if typeof(raw_tags) == TYPE_ARRAY:
		for tag in raw_tags:
			var tag_text = str(tag).strip_edges()
			if tag_text != "":
				tags.append(tag_text)
	elif typeof(raw_tags) == TYPE_STRING:
		for tag in str(raw_tags).split(",", false):
			var tag_text = tag.strip_edges()
			if tag_text != "":
				tags.append(tag_text)

	var votes_up = int(result.get("votes_up", result.get("num_votes_up", 0)))
	var votes_down = int(result.get("votes_down", result.get("num_votes_down", 0)))
	var rating_total = votes_up + votes_down
	if rating_total == 0:
		var score = int(result.get("vote_score", 0))
		if score > 0:
			votes_up = score
			rating_total = score

	var title = str(result.get("title", "Untitled"))
	var stored = WORKSHOP_STORE.get_entry(item_id)
	return {
		"id": str(item_id),
		"name": title,
		"summary": _short_text(str(result.get("description", ""))),
		"description_plaintext": str(result.get("description", "")),
		"submitted_by": {"display_name": author},
		"stats": {
			"downloads_total": 0,
			"ratings_total": rating_total,
			"ratings_positive": votes_up,
		},
		"tags": tags,
		"date_updated": int(result.get("time_updated", 0)),
		"modfile": {"filesize": int(result.get("file_size", 0))},
		"logo": {"thumb_320x180": preview_url, "original": preview_url},
		"profile_url": "https://steamcommunity.com/sharedfiles/filedetails/?id=%d" % item_id,
		"homepage_url": "",
		"workshop": true,
		"workshop_time_updated": int(result.get("time_updated", 0)),
		"workshop_author": author,
		"workshop_owner": owner_id,
		"workshop_votes_up": votes_up,
		"workshop_votes_down": votes_down,
		"workshop_installed": stored,
	}


func install(item_id: int, meta: Dictionary) -> void:
	if not is_available():
		emit_signal("install_failed", item_id, "Steam Workshop is not available.")
		return
	var key = str(item_id)
	var was_subscribed = _subscribed.has(key)
	_jobs[key] = {
		"id": item_id,
		"meta": meta,
		"was_subscribed": was_subscribed,
	}
	if not was_subscribed:
		_subscribe(item_id)
	_subscribed[key] = true
	emit_signal("install_started", item_id, str(meta.get("title", "Workshop item")))
	call_deferred("_poll_job", key)


func uninstall(item_id: int) -> void:
	_jobs.erase(str(item_id))
	WORKSHOP_STORE.uninstall(item_id)
	_subscribed.erase(str(item_id))
	Steam.unsubscribeItem(item_id)
	emit_signal("removed", item_id)


func _process(delta) -> void:
	if _jobs.empty():
		return
	_poll_elapsed += delta
	if _poll_elapsed < POLL_INTERVAL:
		return
	_poll_elapsed = 0.0
	for key in _jobs.keys():
		_poll_job(key)


func _poll_job(key: String) -> void:
	var job = _jobs.get(key, {})
	if typeof(job) != TYPE_DICTIONARY or job.empty():
		return
	var item_id = int(job.get("id", 0))
	var state = int(Steam.getItemState(item_id))

	if not job.get("was_subscribed", false) and (state & STATE_SUBSCRIBED) == 0:
		_subscribe(item_id)
		return

	if (state & STATE_INSTALLED) == 0 or (state & STATE_NEEDS_UPDATE) != 0:
		var downloading = state & (STATE_DOWNLOADING | STATE_DOWNLOAD_PENDING)
		if downloading == 0:
			Steam.downloadItem(item_id, true)
		_emit_progress(item_id)
		return

	var info = Steam.getItemInstallInfo(item_id)
	var folder := ""
	if typeof(info) == TYPE_DICTIONARY:
		folder = str(info.get("folder", ""))
	if folder == "":
		_fail_job(key, item_id, "Steam hasn't downloaded this item yet.")
		return

	var meta = job.get("meta", {})
	if typeof(meta) != TYPE_DICTIONARY:
		meta = {}
	var info_time = int(info.get("timestamp", 0))
	if info_time > 0:
		meta["time_updated"] = max(int(meta.get("time_updated", 0)), info_time)

	var entry = WORKSHOP_STORE.record_subscription(item_id, meta)
	refresh_subscriptions()
	_jobs.erase(key)
	emit_signal("install_finished", item_id, entry)


func _subscribe(item_id: int) -> void:
	Steam.subscribeItem(item_id)


func _emit_progress(item_id: int) -> void:
	var downloaded := 0
	var total := 0
	var info = Steam.getItemDownloadInfo(item_id)
	if typeof(info) == TYPE_DICTIONARY:
		downloaded = int(info.get("downloaded", info.get("nBytesDownloaded", 0)))
		total = int(info.get("total", info.get("nBytesTotal", 0)))
	emit_signal("install_progress", item_id, downloaded, total)


func _fail_job(key: String, item_id: int, message: String) -> void:
	_jobs.erase(key)
	emit_signal("install_failed", item_id, message)


func request_item_details(item_id: int, target: Object = null, callback: String = "", binds: Array = []) -> void:
	if not is_available():
		emit_signal("details_failed", item_id, "Steam Workshop is not available.")
		return
	if _detail_handle > 0:
		Steam.releaseQueryUGCRequest(_detail_handle)
	_detail_handle = -1
	var handle = int(Steam.createQueryUGCDetailsRequest([item_id]))
	if handle <= 0:
		emit_signal("details_failed", item_id, "Couldn't request item details.")
		return
	_detail_handle = handle
	_detail_item_id = item_id
	_detail_target = target
	_detail_callback = callback
	_detail_binds = binds
	Steam.sendQueryUGCRequest(handle)


func _finish_detail_query(handle: int, result: int, results_returned: int) -> void:
	var item_id = _detail_item_id
	var target = _detail_target
	var callback = _detail_callback
	var binds = _detail_binds
	_detail_handle = -1
	_detail_target = null
	_detail_callback = ""
	_detail_binds = []

	if result != 1 or results_returned < 1:
		Steam.releaseQueryUGCRequest(handle)
		emit_signal("details_failed", item_id, "Steam returned an error (%s)." % str(result))
		return

	var details = _read_result(0, handle)
	if details.empty():
		Steam.releaseQueryUGCRequest(handle)
		emit_signal("details_failed", item_id, "Couldn't read this item's details.")
		return

	var tag_names := []
	var tag_count = int(Steam.getQueryUGCNumTags(handle, 0))
	for i in range(tag_count):
		var tag = str(Steam.getQueryUGCTagDisplayName(handle, 0, i)).strip_edges()
		if tag != "":
			tag_names.append(tag)
	if not tag_names.empty():
		details["tags"] = tag_names

	var previews := []
	for i in range(8):
		var preview = Steam.getQueryUGCAdditionalPreview(handle, 0, i)
		if typeof(preview) != TYPE_DICTIONARY or preview.empty():
			continue
		var url = str(preview.get("url", preview.get("video_url", "")))
		if url == "":
			continue
		previews.append(url)
	if not previews.empty():
		details["additional_previews"] = previews
		details["logo"] = {"thumb_320x180": previews[0], "original": previews[0]}

	var stats = details.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		stats = {}
	stats["subscribers_total"] = _read_stat(handle, Steam.ITEM_STATISTIC_NUM_SUBSCRIPTIONS)
	stats["favorites"] = _read_stat(handle, Steam.ITEM_STATISTIC_NUM_FAVORITES)
	stats["unique_visitors"] = _read_stat(handle, Steam.ITEM_STATISTIC_NUM_UNIQUE_WEBSITE_VIEWS)
	stats["comments_total"] = _read_stat(handle, Steam.ITEM_STATISTIC_NUM_COMMENTS)
	details["stats"] = stats

	Steam.releaseQueryUGCRequest(handle)
	emit_signal("details_loaded", item_id, details)
	if target != null and is_instance_valid(target) and callback != "":
		target.call(callback, details, binds)


func _read_stat(handle: int, stat_type: int) -> int:
	var info = Steam.getQueryUGCStatistic(handle, 0, stat_type)
	if typeof(info) != TYPE_DICTIONARY:
		return 0
	return int(info.get("stat_value", info.get("value", info.get("result_value", 0))))


func request_comments(item_id: int) -> void:
	if not is_available():
		emit_signal("comments_failed", item_id, "Steam Workshop is not available.")
		return
	if _comment_cache.has(str(item_id)):
		emit_signal("comments_loaded", item_id, _comment_cache[str(item_id)].duplicate(true))
		return
	for request in _comment_requests.values():
		if int(request.get("item_id", 0)) == item_id:
			return
	var req = HTTPRequest.new()
	add_child(req)
	req.use_threads = true
	req.timeout = 20.0
	var key = str(item_id)
	_comment_requests[key] = {"item_id": item_id, "req": req}
	req.connect("request_completed", self, "_on_comments_completed", [key])
	var err = req.request(COMMENTS_URL % item_id)
	if err != OK:
		_comment_requests.erase(key)
		req.queue_free()
		emit_signal("comments_failed", item_id, "Couldn't request comments (error %d)." % err)


func _on_comments_completed(result, code, _headers, body, key) -> void:
	var job = _comment_requests.get(key, {})
	_comment_requests.erase(key)
	var item_id = int(job.get("item_id", 0))
	var req = job.get("req", null)
	if req != null and is_instance_valid(req):
		req.queue_free()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		emit_signal("comments_failed", item_id, "Couldn't load comments (HTTP %s)." % str(code))
		return
	if body.size() > MAX_COMMENTS_BYTES:
		emit_signal("comments_failed", item_id, "The comments page was too large to read.")
		return
	var comments = _parse_comments_html(body.get_string_from_utf8())
	_comment_cache[key] = comments
	emit_signal("comments_loaded", item_id, comments)


func _parse_comments_html(html: String) -> Array:
	var comments := []
	var markers = html.split("class=\"commentthread_comment ", false)
	for i in range(1, markers.size()):
		if comments.size() >= MAX_COMMENTS:
			break
		var block = markers[i]
		var author := "anonymous"
		var author_start = block.find("commentthread_author_link")
		if author_start >= 0:
			var bdi_start = block.find("<bdi>", author_start)
			var bdi_end = block.find("</bdi>", bdi_start + 5) if bdi_start >= 0 else -1
			if bdi_start >= 0 and bdi_end > bdi_start:
				author = _html_unescape(block.substr(bdi_start + 5, bdi_end - bdi_start - 5)).strip_edges()
		var stamp := 0
		var stamp_start = block.find("data-timestamp=\"", author_start if author_start >= 0 else 0)
		if stamp_start >= 0:
			var stamp_end = block.find("\"", stamp_start + 16)
			if stamp_end > stamp_start:
				stamp = int(block.substr(stamp_start + 16, stamp_end - stamp_start - 16))
		var text := ""
		var text_start = block.find("commentthread_comment_text")
		if text_start >= 0:
			var gt = block.find(">", text_start)
			var close = block.find("</div>", gt + 1) if gt >= 0 else -1
			if gt >= 0 and close > gt:
				text = _strip_tags(block.substr(gt + 1, close - gt - 1))
		text = text.strip_edges()
		if author == "" or text == "":
			continue
		comments.append({"author": author, "date_added": stamp, "content": text})
	return comments


func _strip_tags(value: String) -> String:
	var out := ""
	var in_tag := false
	for i in range(value.length()):
		var c = value.substr(i, 1)
		if c == "<":
			in_tag = true
		elif c == ">":
			in_tag = false
		elif not in_tag:
			out += c
	return _html_unescape(out).replace("\t", " ").strip_edges()


func _html_unescape(value: String) -> String:
	return value.replace("&nbsp;", " ").replace("&amp;", "&").replace("&lt;", "<") \
		.replace("&gt;", ">").replace("&quot;", "\"").replace("&#39;", "'")


func delete_item(item_id: int) -> void:
	if not is_available():
		emit_signal("delete_failed", item_id, "Steam Workshop is not available.")
		return
	Steam.deleteItem(item_id)


func _on_item_delete_result(result, file_id) -> void:
	if int(result) != 1:
		emit_signal("delete_failed", int(file_id), "Steam couldn't delete this item (%s)." % str(result))
		return
	emit_signal("item_deleted", int(file_id))


func get_outdated_items() -> Array:
	var ids := []
	if not is_available():
		return ids
	var subscribed = Steam.getSubscribedItems()
	if subscribed == null:
		return ids
	for item in subscribed:
		var item_id = int(item)
		var state = int(Steam.getItemState(item_id))
		if (state & STATE_NEEDS_UPDATE) != 0:
			ids.append(item_id)
		elif (state & STATE_INSTALLED) == 0 and (state & STATE_DOWNLOADING) == 0 \
				and (state & STATE_DOWNLOAD_PENDING) == 0:
			ids.append(item_id)
	return ids


func update_all() -> void:
	for item_id in get_outdated_items():
		Steam.downloadItem(item_id, true)
		emit_signal("install_started", item_id, "Updating item %d" % item_id)


func _short_text(text: String) -> String:
	var clean = text.replace("\r", " ").replace("\n", " ").strip_edges()
	if clean.length() <= 240:
		return clean
	return clean.left(240).strip_edges() + "..."
