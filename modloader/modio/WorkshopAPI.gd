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

const WORKSHOP_STORE := preload("res://modloader/modio/WorkshopStore.gd")

const WORKSHOP_APP_ID := 2212330

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


func _ready() -> void:
	Steam.connect("ugc_query_completed", self, "_on_query_completed")
	Steam.connect("get_item_vote_result", self, "_on_get_item_vote_result")
	Steam.connect("set_user_item_vote", self, "_on_set_user_item_vote")


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


func request_subscribed(sort_key: String, offset: int, token: int) -> void:
	if not is_available():
		emit_signal("browse_failed", "Steam Workshop is not available.", token)
		return
	var page = int(offset / PAGE_SIZE) + 1
	var handle = Steam.createQueryUserUGCRequest(Steam.getSteamID(), LIST_SUBSCRIBED,
		MATCH_ITEMS, _user_sort(sort_key), app_id(), app_id(), page)
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


func _read_result(index: int) -> Dictionary:
	var result = Steam.getQueryUGCResult(_query_handle, index)
	if typeof(result) != TYPE_DICTIONARY or result.empty():
		return {}
	if int(result.get("result", 1)) != 1:
		return {}
	var item_id = int(result.get("file_id", result.get("published_file_id", 0)))
	if item_id == 0:
		return {}

	var preview_url := str(Steam.getQueryUGCPreviewURL(_query_handle, index))
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
	var staged = WORKSHOP_STORE.stage_item(item_id, meta, folder)
	if not staged:
		_fail_job(key, item_id, "This item has no mod or style files.")
		return

	if not job.get("was_subscribed", false):
		Steam.unsubscribeItem(item_id)
	refresh_subscriptions()
	_jobs.erase(key)
	emit_signal("install_finished", item_id, WORKSHOP_STORE.get_entry(item_id))


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


func _short_text(text: String) -> String:
	var clean = text.replace("\r", " ").replace("\n", " ").strip_edges()
	if clean.length() <= 240:
		return clean
	return clean.left(240).strip_edges() + "..."
