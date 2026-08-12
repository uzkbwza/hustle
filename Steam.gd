extends Node

# Vibecoded? ever heard of Vinecoded? :3c𐚁

signal lobby_created
signal lobby_match_list
signal lobby_joined
signal lobby_chat_update
signal lobby_message
signal lobby_data_update
signal lobby_invite
signal join_requested
signal persona_state_change
signal p2p_session_request
signal p2p_session_connect_fail
signal get_auth_session_ticket_response
signal validate_auth_ticket_response
signal ugc_query_completed
signal current_stats_received
signal item_created
signal item_updated
signal avatar_loaded


const P2P_SEND_RELIABLE := 0
const RESULT_OK := 1
const USERUGCLISTSORTORDER_CREATIONORDERDESC := 0
const USER_UGC_LIST_PUBLISHED := 0
const WORKSHOP_FILE_TYPE_COMMUNITY := 0


func steamInit(_retry_on_fail: bool = false, _app_id: int = 0):
	return {"status": 2, "verbal": "Dummy Steam"}


func activateGameOverlayToWebPage(_url: String, _mode: int = 0):
	pass


func activateGameOverlayToUser(_type: String, _steam_id: int):
	pass


func getFriendPersonaName(_steam_id: int):
	return "Player"


func getLobbyData(_lobby_id: int, _key: String):
	return ""


func getLobbyOwner(_lobby_id: int):
	return 0


func getLobbyMemberLimit(_lobby_id: int):
	return 0


func getNumLobbyMembers(_lobby_id: int):
	return 0


func getLobbyMemberByIndex(_lobby_id: int, _index: int):
	return 0


func getLobbyMemberData(_lobby_id: int, _steam_id: int, _key: String):
	return ""


func setLobbyMemberData(_lobby_id: int, _key: String, _value: String):
	return true


func getAvailableP2PPacketSize(_channel: int = 0):
	return 0


func readP2PPacket(_packet_size: int, _channel: int = 0):
	return {}


func getSubscribedItems():
	return []


func isSubscribed(_item_id: int = 0):
	return false


func getItemInstallInfo(_item_id: int):
	return {"ret": false, "size_on_disk": 0, "folder": "", "timestamp": 0}


func createItem(_app_id: int, _file_type: int):
	pass


func startItemUpdate(_app_id: int, _item_id: int):
	return 0


func submitItemUpdate(_update_handle: int, _change_note: String = ""):
	pass


func setItemTitle(_update_handle: int, _title: String):
	return true


func setItemDescription(_update_handle: int, _description: String):
	return true


func setItemUpdateLanguage(_update_handle: int, _language: String):
	return true


func setItemVisibility(_update_handle: int, _visibility: int):
	return true


func setItemTags(_update_handle: int, _tags: Array):
	return true


func setItemContent(_update_handle: int, _content_folder: String):
	return true


func setItemPreview(_update_handle: int, _preview_file: String):
	return true


func setItemMetadata(_update_handle: int, _metadata: String):
	return true


func createQueryUserUGCRequest(_steam_id: int, _list_type: int = 0, _match_type: int = 0, _sort_order: int = 0, creator_id: int = 0, consumer_id: int = 0, _page: int = 1):
	return 0


func setReturnOnlyIDs(_query_handle: int, _return_only_ids: bool):
	pass


func sendQueryUGCRequest(_query_handle: int):
	return 0


func getQueryUGCResult(_query_handle: int, _index: int):
	return {}


func releaseQueryUGCRequest(_query_handle: int):
	return true


func getAppID():
	return 0


func getSteamID():
	return 0


func getPersonaName():
	return "Player"


func loggedOn():
	return false


func userHasLicenseForApp(_steam_id: int, _app_id: int):
	return RESULT_OK


func requestCurrentStats() -> bool:
	return true


func run_callbacks():
	pass


func getStatInt(_stat_name: String):
	return 0


func setStatInt(_stat_name: String, _value: int):
	return true


func storeStats():
	return true


func getNumAchievements():
	return 0


func getAchievementName(_index: int):
	return ""


func getAchievement(_achievement_name: String):
	return {"ret": false, "achieved": false}


func setAchievement(_achievement_name: String):
	return true


func clearAchievement(_achievement_name: String):
	return true


func createLobby(_lobby_type: int, _max_members: int):
	pass


func joinLobby(_lobby_id: int):
	pass


func leaveLobby(_lobby_id: int):
	pass


func setLobbyData(_lobby_id: int, _key: String, _value: String):
	return true


func setLobbyJoinable(_lobby_id: int, _joinable: bool):
	return true


func setLobbyOwner(_lobby_id: int, _new_owner_id: int):
	return true


func sendLobbyChatMsg(_lobby_id: int, _message: String):
	return true


func requestLobbyList():
	pass


func addRequestLobbyListDistanceFilter(_distance_filter: int):
	pass


func addRequestLobbyListResultCountFilter(_max_results: int):
	pass


func addRequestLobbyListStringFilter(_key: String, _value: String, _comparison: int):
	pass


func sendP2PPacket(_steam_id: int, _data: PoolByteArray, _send_type: int = 0, _channel: int = 0):
	return true


func acceptP2PSessionWithUser(_steam_id: int):
	return true


func closeP2PSessionWithUser(_steam_id: int):
	return true


func allowP2PPacketRelay(_allow: bool):
	return true


func getAuthSessionTicket():
	return {"id": 0, "buffer": PoolByteArray(), "size": 0}


func beginAuthSession(_ticket_buffer, _ticket_size: int, _steam_id: int):
	return RESULT_OK


func endAuthSession(_steam_id: int):
	pass


func cancelAuthTicket(_ticket_id: int):
	pass
