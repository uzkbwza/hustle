# ==============================================================================
# steam.gd - Mock Definitivo da API Steam para Godot
# INCLUI: CORE, STATS, ACHIEVEMENTS, WORKSHOP, LOBBIES E CONTATOS/AMIGOS
# ==============================================================================
extends Node

# --- VARIÁVEIS INTERNAS DE CONTROLE DUMMY ---
var _current_app_id: int = 480

# --- SINAIS (SIGNALS) ---
signal steam_api_ready
signal achievement_stored(achievement_name)
signal leaderboard_loaded(leaderboard_name)

# Sinais de Estatísticas e Conquistas
signal current_stats_received(game_id, result, user_id)
signal user_stats_received(game_id, result, user_id)

# Sinais da Oficina (Workshop / UGC)
signal ugc_query_completed(handle, num_results, result_code)
signal item_installed(app_id, file_id)

# Sinais de Matchmaking & Lobbies
signal lobby_created(connect_id, lobby_id)
signal lobby_match_list(lobbies)
signal lobby_joined(lobby_id, permissions, locked, response)
signal lobby_chat_update(lobby_id, changed_id, making_change_id, chat_state)
signal lobby_message(lobby_id, user_id, text, type)

# Sinais de Amigos e Social
signal persona_state_change(steam_id, flags)

# --- ENUMS DUMMY ---
enum {
	RESULT_OK = 1,
	RESULT_FAIL = 2,
	AVATAR_MEDIUM = 2,
	AVATAR_LARGE = 3,
	LOBBY_TYPE_PRIVATE = 0,
	LOBBY_TYPE_FRIENDS_ONLY = 1,
	LOBBY_TYPE_PUBLIC = 2,
	LOBBY_TYPE_INVISIBLE = 3,
	FRIEND_FLAG_IMMEDIATE = 1,
	FRIEND_RELATIONSHIP_NONE = 0,
	FRIEND_RELATIONSHIP_FRIEND = 3
}

# --- INICIALIZAÇÃO E CORE ---
func steamInit(app_id: int = 480) -> Dictionary:
	_current_app_id = app_id
	print("[Steam Mock] steamInit chamado com AppID: ", app_id)
	return {"status": RESULT_OK, "verbal": "Steamworks active (Mock)"}

func steamInitEx(app_id: int = 480) -> Dictionary:
	return steamInit(app_id)

func run_callbacks() -> void:
	pass

func isSteamRunning() -> bool:
	return true

func is_steam_running() -> bool:
	return true

# --- RELACIONAMENTOS E AMIGOS (Onde entram os métodos ausentes) ---

func getFriendCount(friend_flags: int = 1) -> int:
	return 3

func get_friend_count(friend_flags: int = 1) -> int:
	return getFriendCount(friend_flags)

func getFriendByIndex(friend_index: int, friend_flags: int = 1) -> int:
	# Retorna IDs sequenciais simulados baseados no index
	return 76561197960287931 + friend_index

func get_friend_by_index(friend_index: int, friend_flags: int = 1) -> int:
	return getFriendByIndex(friend_index, friend_flags)

func getFriendPersonaName(steam_id: int) -> String:
	return "Amigo_Dummy_" + str(steam_id % 100)

func get_friend_persona_name(steam_id: int) -> String:
	return getFriendPersonaName(steam_id)

func getFriendPersonaState(steam_id: int) -> int:
	return 1 # Status 1 geralmente representa Online

func get_friend_persona_state(steam_id: int) -> int:
	return getFriendPersonaState(steam_id)

func getFriendRelationship(steam_id: int) -> int:
	return FRIEND_RELATIONSHIP_FRIEND

func get_friend_relationship(steam_id: int) -> int:
	return getFriendRelationship(steam_id)

func hasFriend(steam_id: int, friend_flags: int = 1) -> bool:
	return true

func has_friend(steam_id: int, friend_flags: int = 1) -> bool:
	return hasFriend(steam_id, friend_flags)

func getFriendGamePlayed(steam_id: int) -> Dictionary:
	# Retorna uma simulação se o amigo está jogando algo (id zero significa que não está jogando)
	return {"id": 0, "lobby_id": 0, "ip": 0, "port": 0}

func get_friend_game_played(steam_id: int) -> Dictionary:
	return getFriendGamePlayed(steam_id)

# --- MATCHMAKING & LOBBIES ---

func createLobby(lobby_type: int, max_members: int) -> void:
	print("[Steam Mock] Criando lobby dummy do tipo: ", lobby_type)
	emit_signal("lobby_created", RESULT_OK, 123456789)

func create_lobby(lobby_type: int, max_members: int) -> void:
	createLobby(lobby_type, max_members)

func joinLobby(lobby_id: int) -> void:
	print("[Steam Mock] Entrando no lobby: ", lobby_id)
	emit_signal("lobby_joined", lobby_id, 1, false, RESULT_OK)

func join_lobby(lobby_id: int) -> void:
	joinLobby(lobby_id)

func leaveLobby(lobby_id: int) -> void:
	print("[Steam Mock] Saindo do lobby: ", lobby_id)

func leave_lobby(lobby_id: int) -> void:
	leaveLobby(lobby_id)

func requestLobbyList() -> void:
	print("[Steam Mock] Requisitando lista de lobbies...")
	emit_signal("lobby_match_list")

func request_lobby_list() -> void:
	requestLobbyList()

func addRequestLobbyListDistanceFilter(distance_filter: int) -> void:
	pass

func add_request_lobby_list_distance_filter(distance_filter: int) -> void:
	pass

func addRequestLobbyListNumericalFilter(key: String, value: int, comparison: int) -> void:
	pass

func add_request_lobby_list_numerical_filter(key: String, value: int, comparison: int) -> void:
	pass

func addRequestLobbyListStringFilter(key: String, value: String, comparison: int) -> void:
	pass

func add_request_lobby_list_string_filter(key: String, value: String, comparison: int) -> void:
	pass

func getLobbyMemberData(lobby_id: int, steam_id: int, key: String) -> String:
	if key == "name":
		return getFriendPersonaName(steam_id)
	return "dummy_member_value"

func get_lobby_member_data(lobby_id: int, steam_id: int, key: String) -> String:
	return getLobbyMemberData(lobby_id, steam_id, key)

func setLobbyMemberData(lobby_id: int, key: String, value: String) -> void:
	pass

func set_lobby_member_data(lobby_id: int, key: String, value: String) -> void:
	setLobbyMemberData(lobby_id, key, value)

func getLobbyData(lobby_id: int, key: String) -> String:
	if key == "name" or key == "title":
		return "Lobby de Teste Dummy"
	return "dummy_lobby_value"

func get_lobby_data(lobby_id: int, key: String) -> String:
	return getLobbyData(lobby_id, key)

func setLobbyData(lobby_id: int, key: String, value: String) -> bool:
	return true

func set_lobby_data(lobby_id: int, key: String, value: String) -> bool:
	return setLobbyData(lobby_id, key, value)

func getNumLobbyMembers(lobby_id: int) -> int:
	return 1

func get_num_lobby_members(lobby_id: int) -> int:
	return 1

func getLobbyMemberByIndex(lobby_id: int, member_index: int) -> int:
	return getSteamID()

func get_lobby_member_by_index(lobby_id: int, member_index: int) -> int:
	return getLobbyMemberByIndex(lobby_id, member_index)

func getLobbyOwner(lobby_id: int) -> int:
	return getSteamID()

func get_lobby_owner(lobby_id: int) -> int:
	return getLobbyOwner(lobby_id)

func setLobbyOwner(lobby_id: int, steam_id: int) -> bool:
	return true

func set_lobby_owner(lobby_id: int, steam_id: int) -> bool:
	return true

func sendLobbyChatMsg(lobby_id: int, message_body: String) -> bool:
	return true

func send_lobby_chat_msg(lobby_id: int, message_body: String) -> bool:
	return true

# --- REQUISIÇÃO DE ESTATÍSTICAS ---

func requestCurrentStats() -> bool:
	var dummy_steam_id = getSteamID()
	emit_signal("current_stats_received", _current_app_id, RESULT_OK, dummy_steam_id)
	emit_signal("user_stats_received", _current_app_id, RESULT_OK, dummy_steam_id)
	return true

func request_current_stats() -> bool:
	return requestCurrentStats()

func requestUserStats(steam_id: int) -> bool:
	emit_signal("user_stats_received", _current_app_id, RESULT_OK, steam_id)
	return true

func request_user_stats(steam_id: int) -> bool:
	return requestUserStats(steam_id)

# --- CONQUISTAS E ESTATÍSTICAS ---

func setAchievement(api_name: String) -> bool:
	emit_signal("achievement_stored", api_name)
	return true

func set_achievement(api_name: String) -> bool:
	return setAchievement(api_name)

func clearAchievement(api_name: String) -> bool:
	return true

func isAchievementAchieved(api_name: String) -> Dictionary:
	return {"achieved": false, "unlock_time": 0}

func getStatInt(stat_name: String) -> int:
	return 100

func setStatInt(stat_name: String, value: int) -> bool:
	return true

func storeStats() -> bool:
	return true

func store_stats() -> bool:
	return true

# --- ITENS INSCRITOS E OFICINA (WORKSHOP / UGC) ---

func getSubscribedItems() -> Array:
	return []

func get_subscribed_items() -> Array:
	return getSubscribedItems()

func getNumSubscribedItems() -> int:
	return 0

func get_num_subscribed_items() -> int:
	return 0

func getItemState(file_id: int) -> int:
	return 4

func get_item_state(file_id: int) -> int:
	return getItemState(file_id)

func getItemInstallInfo(file_id: int) -> Dictionary:
	return {
		"ret": true,
		"size_on_disk": 1024,
		"folder": "user://mock_workshop/item_" + str(file_id),
		"timestamp": 1600000000
	}

# --- APPS, IDS E IDIOMA ---

func getAppID() -> int:
	return _current_app_id

func get_app_id() -> int:
	return _current_app_id

func getAppBuildId() -> int:
	return 123456

func get_app_build_id() -> int:
	return 123456

func getCurrentGameLanguage() -> String:
	return "english"

func get_current_game_language() -> String:
	return "english"

func getAvailableGameLanguages() -> String:
	return "english,portuguese"

func isSubscribed() -> bool:
	return true

func is_subscribed() -> bool:
	return true

# --- INFORMAÇÕES DO USUÁRIO (USER) ---

func getSteamID() -> int:
	return 76561197960287930

func get_steam_id() -> int:
	return 76561197960287930

func getPersonaName() -> String:
	return "Jogador_Dummy"

func get_persona_name() -> String:
	return "Jogador_Dummy"

func loggedOn() -> bool:
	return true

func is_logged_on() -> bool:
	return true

func getPlayerSteamLevel() -> int:
	return 42

func getLargeFriendAvatar(steam_id: int = 0) -> int:
	return 1

# --- PLACAR DE LÍDERES (LEADERBOARDS) ---

func findLeaderboard(leaderboard_name: String) -> void:
	emit_signal("leaderboard_loaded", leaderboard_name)

func uploadLeaderboardScore(score: int, force_update: bool = false, leaderboard_handle: int = 0) -> void:
	pass

func downloadLeaderboardEntries(start: int = 1, end: int = 10, type: int = 0, leaderboard_handle: int = 0) -> Array:
	return [{"score": 9999, "steam_id": 76561197960287930, "global_rank": 1, "username": "Jogador_Dummy"}]

# --- ARQUIVOS EM NUVEM (STEAM CLOUD) ---

func isCloudEnabledForAccount() -> bool:
	return true

