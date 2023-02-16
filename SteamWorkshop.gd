extends Node

class_name SteamWorkshop

signal query_request_success

var published_items  : Array

var _app_id        : int
var _query_handler : int
var _page_number   : int = 1
var _subscribed_items : Dictionary

func _init() -> void:
	Steam.connect("ugc_query_completed", self, "_on_query_completed")
	_app_id = Steam.getAppID()
	for item in Steam.getSubscribedItems():
		var info : Dictionary
		info = get_item_install_info(item)
		if info["ret"] == true:
			_subscribed_items[item] = info

static func open_tos() -> void:
	var tos_url = "https://steamcommunity.com/sharedfiles/workshoplegalagreement"
	Steam.activateGameOverlayToWebPage(tos_url)

func get_item_install_info(p_item_id : int) -> Dictionary:
	var info : Dictionary
	info = Steam.getItemInstallInfo(p_item_id)

	if info["ret"] == false:
		var warning = "Item " + String(p_item_id) + " isn't installed or has no content"
		print(warning)
		# Here your code to log/display errors

	return info


func get_published_items(p_page : int = 1, p_only_ids : bool = false) -> void:
	var user_id : int = Steam.getSteamID()
	var list    : int = Steam.USER_UGC_LIST_PUBLISHED
	var type    : int = Steam.WORKSHOP_FILE_TYPE_COMMUNITY
	var sort    : int = Steam.USERUGCLISTSORTORDER_CREATIONORDERDESC

	_query_handler = Steam.createQueryUserUGCRequest(user_id,
													 list,
													 type,
													 sort,
													 _app_id,
													 _app_id,
													 p_page)
	Steam.setReturnOnlyIDs(_query_handler, p_only_ids)
	Steam.sendQueryUGCRequest(_query_handler)

func get_item_folder(p_item_id : int) -> String:
	return _subscribed_items[p_item_id]["folder"]

func fetch_query_result(p_number_results : int) -> void:
	var result : Dictionary
	for i in range(p_number_results):
		result = Steam.getQueryUGCResult(_query_handler, i)
		published_items.append(result)

	Steam.releaseQueryUGCRequest(_query_handler)


func _on_query_completed(p_query_handler    : int,
						 p_result           : int,
						 p_results_returned : int,
						 p_total_matching   : int,
						 p_cached           : bool) -> void:

	if p_result == Steam.RESULT_OK:
		fetch_query_result(p_results_returned)
	else:
		var warning = "Couldn't get published items. Error: " + String(p_result)
		# Here your code to log/display errors

	if p_result == 50:
		_page_number ++ 1
		get_published_items(_page_number)

	elif p_result < 50:
		emit_signal("query_request_success",
					p_results_returned,
					_page_number)
