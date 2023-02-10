extends Node

class_name UGCItem

signal item_created
signal item_updated
signal item_creation_failed
signal item_update_failed

var _app_id  : int = SteamHustle.APP_ID
var _item_id : int
var _update_handler

func _init(p_item_id   : int = 0,
		   p_file_type : int = Steam.WORKSHOP_FILE_TYPE_COMMUNITY) -> void:

	Steam.connect("item_created", self, "_on_item_created")
	Steam.connect("item_updated", self, "_on_item_updated")

	if p_item_id == 0:
		Steam.createItem(_app_id, p_file_type)
	else:
		_item_id = p_item_id
		start_update(p_item_id)


func start_update(p_item_id : int) -> void:
	_update_handler = Steam.startItemUpdate(_app_id, p_item_id)


func update(p_update_description : String = "Initial commit") -> void:
	Steam.submitItemUpdate(_update_handler, p_update_description)


func set_title(p_title : String) -> void:
	if Steam.setItemTitle(_update_handler, p_title) == false:
		# Here your code to log/display errors
		pass

func set_description(p_description : String = "") -> void:
	if Steam.setItemDescription(_update_handler, p_description) == false:
		pass
		# Here your code to log/display errors


func set_update_language(p_language : String) -> void:
	if Steam.setItemUpdateLanguage(_update_handler, p_language) == false:
		# Here your code to log/display errors
		pass

func set_visibility(p_visibility : int = 2) -> void:
	if Steam.setItemVisibility(_update_handler, p_visibility) == false:
		# Here your code to log/display errors
		pass

func set_tags(p_tags : Array = []) -> void:
	if Steam.setItemTags(_update_handler, p_tags) == false:
		# Here your code to log/display errors
		pass

func set_content(p_content : String) -> void:
	if Steam.setItemContent(_update_handler, p_content) == false:
		# Here your code to log/display errors
		pass

func set_preview(p_image_preview : String = "") -> void:
	if Steam.setItemPreview(_update_handler, p_image_preview) == false:
		# Here your code to log/display errors
		pass

func set_metadata(p_metadata : String = "") -> void:
	if Steam.setItemMetadata(_update_handler, p_metadata) == false:
		# Here your code to log/display errors
		pass

func get_id() -> int:
	return _item_id

func _on_item_created(p_result : int, p_file_id : int, p_accept_tos : bool) -> void:
	if p_result == Steam.RESULT_OK:
		_item_id = p_file_id
		# Here your code to log/display success
		emit_signal("item_created", p_file_id)
	else:
		var error = "Failed creating workshop item. Error: " + String(p_result)
		# Here your code to log/display errors
		emit_signal("item_creation_failed", error)

	if p_accept_tos:
		SteamWorkshop.open_tos()


func _on_item_updated(p_result : int, p_accept_tos : bool) -> void:
	if p_result == Steam.RESULT_OK:
		var item_url = "Steam://url/CommunityFilePage/" + String(_item_id)
		# Here your code to log/display success
		Steam.activateGameOverlayToWebPage(item_url)
#		print(item_url)
		emit_signal("item_updated", item_url)
	else:
		var error = "Failed updated workshop item. Error: " + String(p_result)
		# Here your code to log/display errors
		emit_signal("item_update_failed", error)

	if p_accept_tos:
		SteamWorkshop.open_tos()
