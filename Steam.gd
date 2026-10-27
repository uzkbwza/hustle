extends Node

# Vibecoded? ever heard of Vinecoded? :3c𐚁

signal lobby_created(connect_id, lobby_id)
signal lobby_match_list(lobbies)
signal lobby_joined(lobby, permissions, locked, response)
signal lobby_chat_update(lobby_id, changed_id, making_change_id, chat_state)
signal lobby_message(lobby_id, user, message, chat_type)
signal lobby_data_update
signal lobby_invite(inviter, lobby, game)
signal join_requested(lobby_id, steam_id)
signal persona_state_change(steam_id, flags)
signal p2p_session_request(steam_id_remote)
signal p2p_session_connect_fail(steam_id_remote, session_error)
signal get_auth_session_ticket_response(auth_ticket, result)
signal validate_auth_ticket_response(auth_id, response, owner_id)
signal ugc_query_completed(handle, result, results_returned, total_matching, cached)
signal current_stats_received(game_id, result, user_id)
signal item_created(result, file_id, accept_tos)
signal item_updated(result, accept_tos)
signal avatar_loaded(avatar_id, size, data)
signal encrypted_app_ticket_response(result)
signal get_item_vote_result(result, file_id, vote_up, vote_down, vote_skipped)
signal set_user_item_vote(result, file_id, vote_up)
signal active_beacons_updated
signal add_app_dependency_result(result, file_id, app_id)
signal add_ugc_dependency_result(result, file_id, child_id)
signal app_installed(app_id, install_folder_index)
signal app_resuming_from_suspend
signal app_uninstalled(app_id, install_folder_index)
signal available_beacon_locations_updated
signal avatar_image_loaded(avatar_id, avatar_index, width, height)
signal change_num_open_slots(result)
signal change_server_requested(server, password)
signal check_file_signature(signature)
signal clan_activity_downloaded(activity)
signal client_game_server_deny(app_id, ip, server_port, secure, reason)
signal connected_chat_join(chat_id, steam_id)
signal connected_chat_leave(chat_id, steam_id, kicked, dropped)
signal connected_clan_chat_message(chat)
signal connected_friend_chat_message(chat)
signal create_beacon(result, beacon_id)
signal dlc_installed(app)
signal download_ugc_result(result, download_data)
signal duration_control(result, duration)
signal end_game_result(result, game_id)
signal enumerate_following_list(message, following)
signal equipped_profile_items(result, steam_id, profile_data)
signal equipped_profile_items_changed(steam_id)
signal fake_ip_result(result, identity, fake_ip, port_list)
signal favorites_list_accounts_updated(result)
signal favorites_list_changed(favorite)
signal file_details_result(result, file_size, file_hash, flags)
signal file_read_async_complete(file_read)
signal file_share_result(result, handle, name)
signal file_write_async_complete(result)
signal filter_text_dictionary_changed(language)
signal floating_gamepad_text_input_dismissed
signal friend_rich_presence_update(steam_id, app_id)
signal game_web_callback(url)
signal gamepad_text_input_dismissed(submitted, entered_text, app_id)
signal get_app_dependencies_result(result, file_id, app_dependencies, total_app_dependencies)
signal get_follower_count(result, steam_id, count)
signal get_opf_settings_result(result, app_id)
signal get_ticket_for_web_api(auth_ticket, result, ticket_size, ticket_buffer)
signal get_video_result(result, app_id, url)
signal global_achievement_percentages_ready(game_id, result)
signal global_stats_received(game_id, result)
signal html_browser_ready(browser_handle)
signal html_can_go_backandforward(browser_handle, go_back, go_forward)
signal html_changed_title(browser_handle, title)
signal html_close_browser(browser_handle)
signal html_file_open_dialog(browser_handle, title, initial_file)
signal html_finished_request(browser_handle, url, title)
signal html_hide_tooltip(browser_handle, scroll_data)
signal html_horizontal_scroll(browser_handle, scroll_data)
signal html_js_alert(browser_handle, message)
signal html_js_confirm(browser_handle, message)
signal html_link_at_position(browser_handle, link_data)
signal html_needs_paint(browser_handle, page_data)
signal html_new_window(browser_handle, window_data)
signal html_open_link_in_new_tab(browser_handle, url)
signal html_search_results(browser_handle, results, current_match)
signal html_set_cursor(browser_handle, mouse_cursor)
signal html_show_tooltip(browser_handle, message)
signal html_start_request(browser_handle, url, target, post_data, redirect)
signal html_status_text(browser_handle, message)
signal html_update_tooltip(browser_handle, message)
signal html_url_changed(browser_handle, url_data)
signal html_vertical_scroll(browser_handle, scroll_data)
signal http_request_completed(cookie_handle, context_value, request_success, status_code, body_size)
signal http_request_data_received(cookie_handle, context_value, offset, bytes_received)
signal http_request_headers_received(cookie_handle, context_value)
signal input_action_event
signal input_configuration_loaded(app_id, device_handle, config_data)
signal input_device_connected(input_handle)
signal input_device_disconnected(input_handle)
signal input_gamepad_slot_change(app_id, device_handle, device_type, old_gamepad_slot, new_gamepad_slot)
signal inventory_definition_update(definitions)
signal inventory_eligible_promo_item(result, cached, definitions)
signal inventory_full_update(inventory_handle)
signal inventory_request_prices_result(result, currency)
signal inventory_result_ready(result, inventory_handle)
signal inventory_start_purchase_result(result, order_id, transaction_id)
signal ip_country
signal ipc_failure(type)
signal is_following(result, steam_id, following)
signal item_deleted(result, file_id)
signal item_downloaded(result, file_id, app_id)
signal item_installed(app_id, file_id)
signal join_clan_chat_complete(chat_id, response)
signal join_game_requested(user, connect)
signal join_party(result, beacon_id, steam_id, connect_string)
signal leaderboard_find_result(leaderboard_handle, found)
signal leaderboard_score_uploaded(success, this_handle, this_score)
signal leaderboard_scores_downloaded(message, leaderboard_entries)
signal leaderboard_ugc_set(leaderboard_handle, result)
signal licenses_updated
signal lobby_game_created(lobby_id, server_id, server_ip, port)
signal lobby_kicked(lobby_id, admin_id, due_to_disconnect)
signal local_file_changed
signal low_power(power)
signal microtransaction_auth_response(app_id, order_id, authorized)
signal music_player_remote_to_front
signal music_player_remote_will_activate
signal music_player_remote_will_deactivate
signal music_player_selects_playlist_entry(entry)
signal music_player_selects_queue_entry(entry)
signal music_player_wants_looped(looped)
signal music_player_wants_pause
signal music_player_wants_play
signal music_player_wants_play_next
signal music_player_wants_play_previous
signal music_player_wants_playing_repeat_status(status)
signal music_player_wants_shuffled(shuffled)
signal music_player_wants_volume(volume)
signal music_player_will_quit
signal name_changed(success, local_success, result)
signal network_authentication_status(available, debug_message)
signal network_connection_status_changed(connect_handle, connection, old_state)
signal network_messages_session_failed(reason)
signal network_messages_session_request(identity)
signal new_launch_url_parameters
signal number_of_current_players(success, players)
signal overlay_browser_protocol(uri)
signal overlay_toggled(active, user_initiated, app_id)
signal parental_setting_changed
signal relay_network_status(available, ping_measurement, available_config, available_relay, debug_message)
signal remote_play_session_connected(session_id)
signal remote_play_session_disconnected(session_id)
signal remove_app_dependency_result(result, file_id, app_id)
signal remove_ugc_dependency_result(result, file_id, child_id)
signal request_clan_officer_list(message, officer_list)
signal request_players_for_game_final_result(result, search_id, game_id)
signal request_players_for_game_progress(result, search_id)
signal request_players_for_game_result(result, search_id, player_data)
signal reservation_notification(beacon_id, steam_id)
signal screenshot_ready(handle, result)
signal screenshot_requested
signal search_for_game_progress(result, search_id, search_progress)
signal search_for_game_result(result, search_id, search_result)
signal server_connect_failure(result, retrying)
signal server_connected
signal server_disconnected(result)
signal server_failed_to_respond
signal server_responded
signal start_playtime_tracking(result)
signal steam_api_call_completed(async_call, callback, parameter)
signal steam_server_connect_failed(result, retrying)
signal steam_server_connected
signal steam_server_disconnected
signal steam_shutdown
signal steamworks_error(failed_signal, io_failure)
signal stop_playtime_tracking(result)
signal store_auth_url_response(url)
signal submit_player_result(result, game_id, player_id)
signal subscribe_item(result, file_id)
signal timed_trial_status(app_id, is_offline, seconds_allowed, seconds_played)
signal unread_chat_messages_changed
signal unsubscribe_item(result, file_id)
signal user_achievement_stored(game_id, group_achieve, achievement_name, current_progress, max_progress)
signal user_favorite_items_list_changed(result, file_id, was_add_request)
signal user_stats_received(game_id, result, user_id)
signal user_stats_stored(game_id, result)
signal user_stats_unloaded(user_id)
signal user_subscribed_items_list_changed(app_id)
signal workshop_eula_status(result, app_id, eula_data)
signal music_playback_status_has_changed
signal music_volume_has_changed
signal ping_server_failed_to_respond
signal ping_server_responded(server_details)
signal player_details_failed_to_respond
signal player_details_player_added(name, score, time_played)
signal player_details_refresh_complete
signal request_server_list_refresh_complete(request_handle, response)
signal request_server_list_server_failed_to_respond(request_handle, server)
signal request_server_list_server_responded(request_handle, server)
signal server_rules_failed_to_respond
signal server_rules_refresh_complete
signal server_rules_responded(rule, value)
signal broadcast_upload_start(is_rtmp)
signal broadcast_upload_stop(result)
signal market_eligibility_response(is_allowed, disallow_reason, allowed_at_time, steam_guard_required_days, new_device_cooldown)
signal published_file_subscribed(file_id, app_id)
signal published_file_unsubscribed(file_id, app_id)
signal remote_play_guest_invite(invite_url)
signal timeline_event_recording_exists(event_id, recording_exists)
signal timeline_game_phase_recording_exists(phase_id, recording_ms, longest_clip_ms, clip_count, screenshot_count)
signal user_achievement_icon_fetched(game_id, achievement_name, was_achieved, icon_handle)

const P2P_SEND_RELIABLE := 2
const RESULT_OK := 1
const USERUGCLISTSORTORDER_CREATIONORDERDESC := 0
const USER_UGC_LIST_PUBLISHED := 0
const WORKSHOP_FILE_TYPE_COMMUNITY := 0
const AVATAR_SMALL := 1
const AVATAR_MEDIUM := 2
const AVATAR_LARGE := 3
const ACCOUNT_ID_INVALID := 0
const ACCOUNT_TYPE_ANON_GAME_SERVER := 4
const ACCOUNT_TYPE_ANON_USER := 10
const ACCOUNT_TYPE_CHAT := 8
const ACCOUNT_TYPE_CLAN := 7
const ACCOUNT_TYPE_CONSOLE_USER := 9
const ACCOUNT_TYPE_CONTENT_SERVER := 6
const ACCOUNT_TYPE_GAME_SERVER := 3
const ACCOUNT_TYPE_INDIVIDUAL := 1
const ACCOUNT_TYPE_INVALID := 0
const ACCOUNT_TYPE_MAX := 11
const ACCOUNT_TYPE_MULTISEAT := 2
const ACCOUNT_TYPE_PENDING := 5
const API_CALL_INVALID := 0
const APP_ID_INVALID := 0
const AUDIO_PLAYBACK_IDLE := 3
const AUDIO_PLAYBACK_PAUSED := 2
const AUDIO_PLAYBACK_PLAYING := 1
const AUDIO_PLAYBACK_UNDEFINED := 0
const AUTH_SESSION_RESPONSE_AUTH_TICKET_CANCELED := 6
const AUTH_SESSION_RESPONSE_AUTH_TICKET_INVALID := 8
const AUTH_SESSION_RESPONSE_AUTH_TICKET_INVALID_ALREADY_USED := 7
const AUTH_SESSION_RESPONSE_AUTH_TICKET_NETWORK_IDENTITY_FAILURE := 10
const AUTH_SESSION_RESPONSE_LOGGED_IN_ELSEWHERE := 4
const AUTH_SESSION_RESPONSE_NO_LICENSE_OR_EXPIRED := 2
const AUTH_SESSION_RESPONSE_OK := 0
const AUTH_SESSION_RESPONSE_PUBLISHER_ISSUED_BAN := 9
const AUTH_SESSION_RESPONSE_USER_NOT_CONNECTED_TO_STEAM := 1
const AUTH_SESSION_RESPONSE_VAC_BANNED := 3
const AUTH_SESSION_RESPONSE_VAC_CHECK_TIMED_OUT := 5
const AUTH_TICKET_INVALID := 0
const BEGIN_AUTH_SESSION_RESULT_DUPLICATE_REQUEST := 2
const BEGIN_AUTH_SESSION_RESULT_EXPIRED_TICKET := 5
const BEGIN_AUTH_SESSION_RESULT_GAME_MISMATCH := 4
const BEGIN_AUTH_SESSION_RESULT_INVALID_TICKET := 1
const BEGIN_AUTH_SESSION_RESULT_INVALID_VERSION := 3
const BEGIN_AUTH_SESSION_RESULT_OK := 0
const BETA_BRANCH_AVAILABLE := 2
const BETA_BRANCH_DEFAULT := 1
const BETA_BRANCH_INSTALLED := 16
const BETA_BRANCH_NONE := 0
const BETA_BRANCH_PRIVATE := 4
const BETA_BRANCH_SELECTED := 8
const BROADCAST_UPLOAD_RESULT_ALREADY_ACTIVE := 17
const BROADCAST_UPLOAD_RESULT_AUDIO_BEHIND := 19
const BROADCAST_UPLOAD_RESULT_AUDIO_INIT_FAILED := 23
const BROADCAST_UPLOAD_RESULT_BANDWIDTH_EXCEEDED := 5
const BROADCAST_UPLOAD_RESULT_BANNED := 16
const BROADCAST_UPLOAD_RESULT_BUSY := 15
const BROADCAST_UPLOAD_RESULT_DISCONNECT := 21
const BROADCAST_UPLOAD_RESULT_FORCED_OFF := 18
const BROADCAST_UPLOAD_RESULT_FRAME_FAILED := 3
const BROADCAST_UPLOAD_RESULT_INIT_FAILED := 2
const BROADCAST_UPLOAD_RESULT_LOW_FPS := 6
const BROADCAST_UPLOAD_RESULT_MISSING_AUDIO := 11
const BROADCAST_UPLOAD_RESULT_MISSING_KEYFRAMES := 7
const BROADCAST_UPLOAD_RESULT_NONE := 0
const BROADCAST_UPLOAD_RESULT_NOT_ALLOWED_TO_PLAY := 14
const BROADCAST_UPLOAD_RESULT_NO_CONNECTION := 8
const BROADCAST_UPLOAD_RESULT_OK := 1
const BROADCAST_UPLOAD_RESULT_RELAY_FAILED := 9
const BROADCAST_UPLOAD_RESULT_SETTINGS_CHANGED := 10
const BROADCAST_UPLOAD_RESULT_SHUTDOWN := 20
const BROADCAST_UPLOAD_RESULT_TIME_OUT := 4
const BROADCAST_UPLOAD_RESULT_TOO_FAR_BEHIND := 12
const BROADCAST_UPLOAD_RESULT_TRANSCODE_BEHIND := 13
const BROADCAST_UPLOAD_RESULT_VIDEO_INIT_FAILED := 22
const CHAT_ACCOUNT_INSTANCE_MASK := 4095
const CHAT_ENTRY_TYPE_CHAT_MSG := 1
const CHAT_ENTRY_TYPE_DISCONNECTED := 10
const CHAT_ENTRY_TYPE_EMOTE := 4
const CHAT_ENTRY_TYPE_ENTERED := 7
const CHAT_ENTRY_TYPE_HISTORICAL_CHAT := 11
const CHAT_ENTRY_TYPE_INVALID := 0
const CHAT_ENTRY_TYPE_INVITE_GAME := 3
const CHAT_ENTRY_TYPE_LEFT_CONVERSATION := 6
const CHAT_ENTRY_TYPE_LINK_BLOCKED := 14
const CHAT_ENTRY_TYPE_TYPING := 2
const CHAT_ENTRY_TYPE_WAS_BANNED := 9
const CHAT_ENTRY_TYPE_WAS_KICKED := 8
const CHAT_INSTANCE_FLAG_CLAN := 524288
const CHAT_INSTANCE_FLAG_LOBBY := 262144
const CHAT_INSTANCE_FLAG_MMS_LOBBY := 131072
const CHAT_MEMBER_STATE_CHANGE_BANNED := 16
const CHAT_MEMBER_STATE_CHANGE_DISCONNECTED := 4
const CHAT_MEMBER_STATE_CHANGE_ENTERED := 1
const CHAT_MEMBER_STATE_CHANGE_KICKED := 8
const CHAT_MEMBER_STATE_CHANGE_LEFT := 2
const CHAT_METADATA_MAX := 8192
const CHAT_ROOM_ENTER_RESPONSE_BANNED := 6
const CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED := 8
const CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN := 9
const CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST := 2
const CHAT_ROOM_ENTER_RESPONSE_ERROR := 5
const CHAT_ROOM_ENTER_RESPONSE_FULL := 4
const CHAT_ROOM_ENTER_RESPONSE_LIMITED := 7
const CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU := 10
const CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED := 3
const CHAT_ROOM_ENTER_RESPONSE_RATE_LIMIT_EXCEEDED := 15
const CHAT_ROOM_ENTER_RESPONSE_SUCCESS := 1
const CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER := 11
const CHECK_FILE_SIGNATURE_FILE_NOT_FOUND := 2
const CHECK_FILE_SIGNATURE_INVALID_SIGNATURE := 0
const CHECK_FILE_SIGNATURE_NO_SIGNATURES_FOUND_FOR_THIS_APP := 3
const CHECK_FILE_SIGNATURE_NO_SIGNATURES_FOUND_FOR_THIS_FILE := 4
const CHECK_FILE_SIGNATURE_VALID_SIGNATURE := 1
const CONNECTION_END_APP_EXCEPTION_GENERIC := 2000
const CONNECTION_END_APP_EXCEPTION_MAX := 2999
const CONNECTION_END_APP_EXCEPTION_MIN := 2000
const CONNECTION_END_APP_GENERIC := 1000
const CONNECTION_END_APP_MAX := 1999
const CONNECTION_END_APP_MIN := 1000
const CONNECTION_END_BAD_PROTOCOL_VERSION := 4006
const CONNECTION_END_FORCE32BIT := 2147483647
const CONNECTION_END_INVALID := 0
const CONNECTION_END_LOCAL_HOSTED_SERVER_PRIMARY_RELAY := 3003
const CONNECTION_END_LOCAL_MANY_RELAY_CONNECTIVITY := 3002
const CONNECTION_END_LOCAL_MAX := 3999
const CONNECTION_END_LOCAL_MIN := 3000
const CONNECTION_END_LOCAL_NETWORK_CONFIG := 3004
const CONNECTION_END_LOCAL_OFFLINE_MODE := 3001
const CONNECTION_END_LOCAL_RIGHTS := 3005
const CONNECTION_END_MISC_GENERIC := 5001
const CONNECTION_END_MISC_INTERNAL_ERROR := 5002
const CONNECTION_END_MISC_MAX := 5999
const CONNECTION_END_MISC_MIN := 5000
const CONNECTION_END_MISC_NO_RELAY_SESSIONS_TO_CLIENT := 5006
const CONNECTION_END_MISC_P2P_NAT_FIREWALL := 5009
const CONNECTION_END_MISC_P2P_RENDEZVOUS := 5008
const CONNECTION_END_MISC_PEER_SENT_NO_CONNECTION := 5010
const CONNECTION_END_MISC_STEAM_CONNECTIVITY := 5005
const CONNECTION_END_MISC_TIMEOUT := 5003
const CONNECTION_END_NO_PUBLIC_ADDRESS := 3006
const CONNECTION_END_REMOTE_BAD_CERT := 4003
const CONNECTION_END_REMOTE_BAD_CRYPT := 4002
const CONNECTION_END_REMOTE_MAX := 4999
const CONNECTION_END_REMOTE_P2P_ICE_NO_PUBLIC_ADDRESSES := 4007
const CONNECTION_END_REMOTE_TIMEOUT := 4001
const CONNECTION_END_REMOVE_MIN := 4000
const CONNECTION_STATE_CLOSED_BY_PEER := 4
const CONNECTION_STATE_CONNECTED := 3
const CONNECTION_STATE_CONNECTING := 1
const CONNECTION_STATE_DEAD := -3
const CONNECTION_STATE_FINDING_ROUTE := 2
const CONNECTION_STATE_FIN_WAIT := -1
const CONNECTION_STATE_FORCE_32BIT := 2147483647
const CONNECTION_STATE_LINGER := -2
const CONNECTION_STATE_NONE := 0
const CONNECTION_STATE_PROBLEM_DETECTED_LOCALLY := 5
const CONTROLLER_HAPTIC_LOCATION_BOTH := 3
const CONTROLLER_HAPTIC_LOCATION_LEFT := 1
const CONTROLLER_HAPTIC_LOCATION_RIGHT := 2
const CONTROLLER_HAPTIC_TYPE_CLICK := 2
const CONTROLLER_HAPTIC_TYPE_OFF := 0
const CONTROLLER_HAPTIC_TYPE_TICK := 1
const DC_ALIAS := 31
const DC_ARROW := 2
const DC_BLANK := 21
const DC_CELL := 32
const DC_COL_RESIZE := 33
const DC_COPY_CUR := 34
const DC_CROSSHAIR := 6
const DC_CUSTOM := 40
const DC_EAST_PAN := 25
const DC_HAND := 20
const DC_HELP := 39
const DC_HOUR_GLASS := 4
const DC_IBEAM := 3
const DC_LAST := 41
const DC_MIDDLE_PAN := 22
const DC_NO := 19
const DC_NONE := 1
const DC_NORTH_EAST_PAN := 24
const DC_NORTH_PAN := 23
const DC_NORTH_WEST_PAN := 30
const DC_ROW_RESIZE := 36
const DC_SIZE_ALL := 18
const DC_SIZE_E := 13
const DC_SIZE_N := 14
const DC_SIZE_NE := 10
const DC_SIZE_NS := 17
const DC_SIZE_NW := 8
const DC_SIZE_S := 15
const DC_SIZE_SE := 9
const DC_SIZE_SW := 11
const DC_SIZE_W := 12
const DC_SIZE_WE := 16
const DC_SOUTH_EAST_PAN := 26
const DC_SOUTH_PAN := 27
const DC_SOUTH_WEST_PAN := 28
const DC_UP := 7
const DC_USER := 0
const DC_VERTICAL_TEXT := 35
const DC_WAIT_ARROW := 5
const DC_WEST_PAN := 29
const DC_ZOOM_IN := 37
const DC_ZOOM_OUT := 38
const DENY_CHEATER := 5
const DENY_GENERIC := 2
const DENY_INCOMPATIBLE_ANTI_CHEAT := 8
const DENY_INCOMPATIBLE_SOFTWARE := 10
const DENY_INVALID := 0
const DENY_INVALID_VERSION := 1
const DENY_LOGGED_IN_ELSEWHERE := 6
const DENY_MEMORY_CORRUPTION := 9
const DENY_NOT_LOGGED_ON := 3
const DENY_NO_LICENSE := 4
const DENY_STEAM_CONNECTION_ERROR := 12
const DENY_STEAM_CONNECTION_LOST := 11
const DENY_STEAM_OWNER_LEFT_GUEST_USER := 15
const DENY_STEAM_RESPONSE_TIMED_OUT := 13
const DENY_STEAM_VALIDATION_STALLED := 14
const DENY_UNKNOWN_TEXT := 7
const DEPOT_ID_INVALID := 0
const DEVELOPER_METADATA_MAX := 5000
const DEVICE_FORM_FACTOR_COMPUTER := 3
const DEVICE_FORM_FACTOR_PHONE := 1
const DEVICE_FORM_FACTOR_TABLET := 2
const DEVICE_FORM_FACTOR_TV := 4
const DEVICE_FORM_FACTOR_UNKNOWN := 0
const DURATION_CONTROL_EXIT_SOON_3H := 3
const DURATION_CONTROL_EXIT_SOON_5H := 4
const DURATION_CONTROL_EXIT_SOON_NIGHT := 5
const DURATION_CONTROL_NOTIFICATION_1_HOUR := 1
const DURATION_CONTROL_NOTIFICATION_3_HOURS := 2
const DURATION_CONTROL_NOTIFICATION_EXIT_SOON_3H := 5
const DURATION_CONTROL_NOTIFICATION_EXIT_SOON_5H := 6
const DURATION_CONTROL_NOTIFICATION_EXIT_SOON_NIGHT := 7
const DURATION_CONTROL_NOTIFICATION_HALF_PROGRESS := 3
const DURATION_CONTROL_NOTIFICATION_NONE := 0
const DURATION_CONTROL_NOTIFICATION_NO_PROGRESS := 4
const DURATION_CONTROL_ONLINE_STATE_INVALID := 0
const DURATION_CONTROL_ONLINE_STATE_OFFLINE := 1
const DURATION_CONTROL_ONLINE_STATE_ONLINE := 2
const DURATION_CONTROL_ONLINE_STATE_ONLINE_HIGH_PRIORITY := 3
const DURATION_CONTROL_PROGRESS_FULL := 0
const DURATION_CONTROL_PROGRESS_HALF := 1
const DURATION_CONTROL_PROGRESS_NONE := 2
const ENUMERATED_FOLLOWERS_MAX := 50
const ENUMERATE_PUBLISHED_FILES_MAX_RESULTS := 50
const FAILURE_FLUSHED_CALLBACK_QUEUE := 0
const FAILURE_PIPE_FAIL := 1
const FAKE_IP_TYPE_FORCE32BIT := 2147483647
const FAKE_IP_TYPE_GLOBAL_IPV4 := 2
const FAKE_IP_TYPE_INVALID := 0
const FAKE_IP_TYPE_LOCAL_IPV4 := 3
const FAKE_IP_TYPE_NOT_FAKE := 1
const FAVORITE_FLAG_FAVORITE := 1
const FAVORITE_FLAG_HISTORY := 2
const FAVORITE_FLAG_NONE := 0
const FEATURE_BLOCK_ALWAYS := 15
const FEATURE_BROWSER := 9
const FEATURE_COMMUNITY := 2
const FEATURE_CONSOLE := 8
const FEATURE_FRIENDS := 4
const FEATURE_INVALID := 0
const FEATURE_KIOSK_MODE := 14
const FEATURE_LIBRARY := 11
const FEATURE_MAX := 15
const FEATURE_NEWS := 5
const FEATURE_PARENTAL_SETUP := 10
const FEATURE_PROFILE := 3
const FEATURE_SETTINGS := 7
const FEATURE_SITE_LICENSE := 13
const FEATURE_STORE := 1
const FEATURE_TEST := 12
const FEATURE_TRADING := 6
const FILENAME_MAX := 260
const FILE_NAME_MAX := 260
const FILE_PATH_TYPE_ABSOLUTE := 1
const FILE_PATH_TYPE_API_FILENAME := 2
const FILE_PATH_TYPE_INVALID := 0
const FLOATING_GAMEPAD_TEXT_INPUT_MODE_EMAIL := 2
const FLOATING_GAMEPAD_TEXT_INPUT_MODE_MULTIPLE_LINES := 1
const FLOATING_GAMEPAD_TEXT_INPUT_MODE_NUMERIC := 3
const FLOATING_GAMEPAD_TEXT_INPUT_MODE_SINGLE_LINE := 0
const FORM_FACTOR_COMPUTER := 3
const FORM_FACTOR_PHONE := 1
const FORM_FACTOR_TABLET := 2
const FORM_FACTOR_TV := 4
const FORM_FACTOR_UNKNOWN := 0
const FORM_FACTOR_VR_HEADSET := 5
const FRIENDS_GROUP_LIMIT := 100
const FRIEND_FLAG_ALL := 65535
const FRIEND_FLAG_BLOCKED := 1
const FRIEND_FLAG_CHAT_MEMBER := 4096
const FRIEND_FLAG_CLAN_MEMBER := 8
const FRIEND_FLAG_FRIENDSHIP_REQUESTED := 2
const FRIEND_FLAG_IGNORED := 512
const FRIEND_FLAG_IGNORED_FRIEND := 1024
const FRIEND_FLAG_IMMEDIATE := 4
const FRIEND_FLAG_NONE := 0
const FRIEND_FLAG_ON_GAME_SERVER := 16
const FRIEND_FLAG_REQUESTING_FRIENDSHIP := 128
const FRIEND_FLAG_REQUESTING_INFO := 256
const FRIEND_GAME_INFO_QUERY_PORT_ERROR := 65534
const FRIEND_GAME_INFO_QUERY_PORT_NOT_INITIALIZED := 65535
const FRIEND_RELATION_BLOCKED := 1
const FRIEND_RELATION_FRIEND := 3
const FRIEND_RELATION_IGNORED := 5
const FRIEND_RELATION_IGNORED_FRIEND := 6
const FRIEND_RELATION_MAX := 8
const FRIEND_RELATION_NONE := 0
const FRIEND_RELATION_REQUEST_INITIATOR := 4
const FRIEND_RELATION_REQUEST_RECIPIENT := 2
const FRIEND_RELATION_SUGGESTED := 7
const GAMEPAD_TEXT_INPUT_LINE_MODE_MULTIPLE_LINES := 1
const GAMEPAD_TEXT_INPUT_LINE_MODE_SINGLE_LINE := 0
const GAMEPAD_TEXT_INPUT_MODE_NORMAL := 0
const GAMEPAD_TEXT_INPUT_MODE_PASSWORD := 1
const GAME_EXTRA_INFO_MAX := 64
const GAME_SEARCH_ERROR_CODE_NOT_AUTHORIZED := 8
const GAME_SEARCH_ERROR_CODE_NOT_LOBBY_LEADER := 4
const GAME_SEARCH_ERROR_CODE_NO_HOST_AVAILABLE := 5
const GAME_SEARCH_ERROR_CODE_NO_SEARCH_IN_PROGRESS := 3
const GAME_SEARCH_ERROR_CODE_OFFLINE := 7
const GAME_SEARCH_ERROR_CODE_OK := 1
const GAME_SEARCH_ERROR_CODE_SEARCH_AREADY_IN_PROGRESS := 2
const GAME_SEARCH_ERROR_CODE_SEARCH_PARAMS_INVALID := 6
const GAME_SEARCH_ERROR_CODE_UNKNOWN_ERROR := 9
const GAME_TYPE_APP := 0
const GAME_TYPE_GAME_MOD := 1
const GAME_TYPE_P2P := 3
const GAME_TYPE_SHORTCUT := 2
const HTML_KEY_MODIFIER_ALT_DOWN := 1
const HTML_KEY_MODIFIER_CTRL_DOWN := 2
const HTML_KEY_MODIFIER_NONE := 0
const HTML_KEY_MODIFIER_SHIFT_DOWN := 4
const HTML_MOUSE_BUTTON_LEFT := 0
const HTML_MOUSE_BUTTON_MIDDLE := 2
const HTML_MOUSE_BUTTON_RIGHT := 1
const HTML_MOUSE_CURSOR_ALIAS := 31
const HTML_MOUSE_CURSOR_ARROW := 2
const HTML_MOUSE_CURSOR_CELL := 32
const HTML_MOUSE_CURSOR_COL_RESIZE := 33
const HTML_MOUSE_CURSOR_COPY_CUR := 34
const HTML_MOUSE_CURSOR_CROSSHAIR := 6
const HTML_MOUSE_CURSOR_CURSOR_BLANK := 21
const HTML_MOUSE_CURSOR_CURSOR_HAND := 20
const HTML_MOUSE_CURSOR_CURSOR_NO := 19
const HTML_MOUSE_CURSOR_CUSTOM := 40
const HTML_MOUSE_CURSOR_EAST_PAN := 25
const HTML_MOUSE_CURSOR_HELP := 39
const HTML_MOUSE_CURSOR_HOURGLASS := 4
const HTML_MOUSE_CURSOR_IBEAM := 3
const HTML_MOUSE_CURSOR_LAST := 43
const HTML_MOUSE_CURSOR_MIDDLE_PAN := 22
const HTML_MOUSE_CURSOR_NONE := 1
const HTML_MOUSE_CURSOR_NORTH_EAST_PAN := 24
const HTML_MOUSE_CURSOR_NORTH_PAN := 23
const HTML_MOUSE_CURSOR_NORTH_WEST_PAN := 30
const HTML_MOUSE_CURSOR_ROW_RESIZE := 36
const HTML_MOUSE_CURSOR_SIZE_ALL := 18
const HTML_MOUSE_CURSOR_SIZE_E := 13
const HTML_MOUSE_CURSOR_SIZE_N := 14
const HTML_MOUSE_CURSOR_SIZE_NE := 10
const HTML_MOUSE_CURSOR_SIZE_NESW := 42
const HTML_MOUSE_CURSOR_SIZE_NS := 17
const HTML_MOUSE_CURSOR_SIZE_NW := 8
const HTML_MOUSE_CURSOR_SIZE_NWSE := 41
const HTML_MOUSE_CURSOR_SIZE_S := 15
const HTML_MOUSE_CURSOR_SIZE_SE := 9
const HTML_MOUSE_CURSOR_SIZE_SW := 11
const HTML_MOUSE_CURSOR_SIZE_W := 12
const HTML_MOUSE_CURSOR_SIZE_WE := 16
const HTML_MOUSE_CURSOR_SOUTH_EAST_PAN := 26
const HTML_MOUSE_CURSOR_SOUTH_PAN := 27
const HTML_MOUSE_CURSOR_SOUTH_WEST_PAN := 28
const HTML_MOUSE_CURSOR_UP := 7
const HTML_MOUSE_CURSOR_USER := 0
const HTML_MOUSE_CURSOR_VERTICAL_TEXT := 35
const HTML_MOUSE_CURSOR_WAIT_ARROW := 5
const HTML_MOUSE_CURSOR_WEST_PAN := 29
const HTML_MOUSE_CURSOR_ZOOM_IN := 37
const HTML_MOUSE_CURSOR_ZOOM_OUT := 38
const HTTPCOOKIE_INVALID_HANDLE := 0
const HTTPREQUEST_INVALID_HANDLE := 0
const HTTP_METHOD_DELETE := 5
const HTTP_METHOD_GET := 1
const HTTP_METHOD_HEAD := 2
const HTTP_METHOD_INVALID := 0
const HTTP_METHOD_OPTIONS := 6
const HTTP_METHOD_PATCH := 7
const HTTP_METHOD_POST := 3
const HTTP_METHOD_PUT := 4
const HTTP_STATUS_CODE_100_CONTINUE := 100
const HTTP_STATUS_CODE_101_SWITCHING_PROTOCOLS := 101
const HTTP_STATUS_CODE_200_OK := 200
const HTTP_STATUS_CODE_201_CREATED := 201
const HTTP_STATUS_CODE_202_ACCEPTED := 202
const HTTP_STATUS_CODE_203_NON_AUTHORITATIVE := 203
const HTTP_STATUS_CODE_204_NO_CONTENT := 204
const HTTP_STATUS_CODE_205_RESET_CONTENT := 205
const HTTP_STATUS_CODE_206_PARTIAL_CONTENT := 206
const HTTP_STATUS_CODE_300_MULTIPLE_CHOICES := 300
const HTTP_STATUS_CODE_301_MOVED_PERMANENTLY := 301
const HTTP_STATUS_CODE_302_FOUND := 302
const HTTP_STATUS_CODE_303_SEE_OTHER := 303
const HTTP_STATUS_CODE_304_NOT_MODIFIED := 304
const HTTP_STATUS_CODE_305_USE_PROXY := 305
const HTTP_STATUS_CODE_307_TEMPORARY_REDIRECT := 307
const HTTP_STATUS_CODE_308_PERMANENT_REDIRECT := 308
const HTTP_STATUS_CODE_400_BAD_REQUEST := 400
const HTTP_STATUS_CODE_401_UNAUTHORIZED := 401
const HTTP_STATUS_CODE_402_PAYMENT_REQUIRED := 402
const HTTP_STATUS_CODE_403_FORBIDDEN := 403
const HTTP_STATUS_CODE_404_NOT_FOUND := 404
const HTTP_STATUS_CODE_405_METHOD_NOT_ALLOWED := 405
const HTTP_STATUS_CODE_406_NOT_ACCEPTABLE := 406
const HTTP_STATUS_CODE_407_PROXY_AUTH_REQUIRED := 407
const HTTP_STATUS_CODE_408_REQUEST_TIMEOUT := 408
const HTTP_STATUS_CODE_409_CONFLICT := 409
const HTTP_STATUS_CODE_410_GONE := 410
const HTTP_STATUS_CODE_411_LENGTH_REQUIRED := 411
const HTTP_STATUS_CODE_412_PRECONDITION_FAILED := 412
const HTTP_STATUS_CODE_413_REQUEST_ENTITY_TOO_LARGE := 413
const HTTP_STATUS_CODE_414_REQUEST_URI_TOO_LONG := 414
const HTTP_STATUS_CODE_415_UNSUPPORTED_MEDIA_TYPE := 415
const HTTP_STATUS_CODE_416_REQUESTED_RANGE_NOT_SATISFIABLE := 416
const HTTP_STATUS_CODE_417_EXPECTATION_FAILED := 417
const HTTP_STATUS_CODE_421_MISDIRECT_REQUEST := 421
const HTTP_STATUS_CODE_422_UNPROCESSABLE_CONTENT := 422
const HTTP_STATUS_CODE_423_LOCKED := 423
const HTTP_STATUS_CODE_424_FAILED_DEPENDENCY := 424
const HTTP_STATUS_CODE_425_TOO_EARLY := 425
const HTTP_STATUS_CODE_426_UPGRADE_REQUIRED := 426
const HTTP_STATUS_CODE_428_PRECONDITION_REQUIRED := 428
const HTTP_STATUS_CODE_429_TOO_MANY_REQUESTS := 429
const HTTP_STATUS_CODE_431_REQUEST_HEADER_FIELDS_TOO_LARGE := 431
const HTTP_STATUS_CODE_444_CONNECTION_CLOSED := 444
const HTTP_STATUS_CODE_451_UNAVAILABLE_FOR_LEGAL_AREASONS := 451
const HTTP_STATUS_CODE_4XX_UNKNOWN := 418
const HTTP_STATUS_CODE_500_INTERNAL_SERVER_ERROR := 500
const HTTP_STATUS_CODE_501_NOT_IMPLEMENTED := 501
const HTTP_STATUS_CODE_502_BAD_GATEWAY := 502
const HTTP_STATUS_CODE_503_SERVICE_UNAVAILABLE := 503
const HTTP_STATUS_CODE_504_GATEWAY_TIMEOUT := 504
const HTTP_STATUS_CODE_505_HTTP_VERSION_NOT_SUPPORTED := 505
const HTTP_STATUS_CODE_506_VARIANT_ALSO_NEGOTIATES := 506
const HTTP_STATUS_CODE_507_INSUFFICIENT_STORAGE := 507
const HTTP_STATUS_CODE_508_LOOP_DETECTED := 508
const HTTP_STATUS_CODE_510_NOT_EXTENDED := 510
const HTTP_STATUS_CODE_511_NETWORK_AUTHENTICATION_REQUIRED := 511
const HTTP_STATUS_CODE_5XX_UNKNOWN := 599
const HTTP_STATUS_CODE_INVALID := 0
const IDENTITY_TYPE_FORCE_32BIT := 2147483647
const IDENTITY_TYPE_GENERIC_BYTES := 3
const IDENTITY_TYPE_GENERIC_STRING := 2
const IDENTITY_TYPE_GOOGLE_STADIA := 19
const IDENTITY_TYPE_INVALID := 0
const IDENTITY_TYPE_IP_ADDRESS := 1
const IDENTITY_TYPE_SONY_PSN := 18
const IDENTITY_TYPE_STEAMID := 16
const IDENTITY_TYPE_UNKNOWN_TYPE := 4
const IDENTITY_TYPE_XBOX_PAIRWISE := 17
const INPUT_ACTION_EVENT_TYPE_ANALOG_ACTION := 1
const INPUT_ACTION_EVENT_TYPE_DIGITAL_ACTION := 0
const INPUT_ACTION_ORIGIN_COUNT := 406
const INPUT_ACTION_ORIGIN_GENERIC_C := 485
const INPUT_ACTION_ORIGIN_GENERIC_L4 := 479
const INPUT_ACTION_ORIGIN_GENERIC_L5 := 481
const INPUT_ACTION_ORIGIN_GENERIC_MISC1 := 487
const INPUT_ACTION_ORIGIN_GENERIC_MISC2 := 488
const INPUT_ACTION_ORIGIN_GENERIC_MISC3 := 489
const INPUT_ACTION_ORIGIN_GENERIC_MISC4 := 490
const INPUT_ACTION_ORIGIN_GENERIC_MISC5 := 491
const INPUT_ACTION_ORIGIN_GENERIC_MISC6 := 492
const INPUT_ACTION_ORIGIN_GENERIC_MISC7 := 493
const INPUT_ACTION_ORIGIN_GENERIC_MISC8 := 494
const INPUT_ACTION_ORIGIN_GENERIC_PL := 483
const INPUT_ACTION_ORIGIN_GENERIC_PR := 484
const INPUT_ACTION_ORIGIN_GENERIC_R4 := 480
const INPUT_ACTION_ORIGIN_GENERIC_R5 := 482
const INPUT_ACTION_ORIGIN_GENERIC_Z := 486
const INPUT_ACTION_ORIGIN_HORIPAD_L4 := 408
const INPUT_ACTION_ORIGIN_HORIPAD_M1 := 406
const INPUT_ACTION_ORIGIN_HORIPAD_M2 := 407
const INPUT_ACTION_ORIGIN_HORIPAD_R4 := 409
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_A := 410
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_B := 411
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_DPAD_EAST := 454
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_DPAD_MOVE := 450
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_DPAD_NORTH := 451
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_DPAD_SOUTH := 452
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_DPAD_WEST := 453
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_GYRO_MOVE := 455
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_GYRO_PITCH := 456
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_GYRO_ROLL := 458
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_GYRO_YAW := 457
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LB := 414
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_CLICK := 420
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_DPAD_EAST := 424
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_DPAD_NORTH := 421
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_DPAD_SOUTH := 422
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_DPAD_WEST := 423
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_SWIPE := 419
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTPAD_TOUCH := 418
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTSTICK_DPAD_EAST := 441
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTSTICK_DPAD_NORTH := 438
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTSTICK_DPAD_SOUTH := 439
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTSTICK_DPAD_WEST := 440
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LEFTSTICK_MOVE := 436
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LS := 437
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LT := 433
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_LT_SOFTPULL := 432
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_MENU := 416
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RB := 415
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED1 := 459
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED10 := 468
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED11 := 469
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED12 := 470
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED13 := 471
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED14 := 472
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED15 := 473
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED16 := 474
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED17 := 475
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED18 := 476
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED19 := 477
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED2 := 460
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED20 := 478
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED3 := 461
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED4 := 462
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED5 := 463
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED6 := 464
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED7 := 465
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED8 := 466
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RESERVED9 := 467
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_CLICK := 427
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_DPAD_EAST := 431
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_DPAD_NORTH := 428
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_DPAD_SOUTH := 429
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_DPAD_WEST := 430
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_SWIPE := 426
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTPAD_TOUCH := 425
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTSTICK_DPAD_EAST := 447
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTSTICK_DPAD_NORTH := 444
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTSTICK_DPAD_SOUTH := 445
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTSTICK_DPAD_WEST := 446
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RIGHTSTICK_MOVE := 442
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RS := 443
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RT := 435
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_RT_SOFTPULL := 434
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_VIEW := 417
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_X := 412
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_Y := 413
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_Y1 := 448
const INPUT_ACTION_ORIGIN_LENOVO_LEGION_GO_Y2 := 449
const INPUT_ACTION_ORIGIN_MAXIMUM_POSSIBLE_VALUE := 32767
const INPUT_ACTION_ORIGIN_NONE := 0
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_CLICK := 74
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_DPADEAST := 78
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_DPADNORTH := 75
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_DPADSOUTH := 76
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_DPADWEST := 77
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_SWIPE := 73
const INPUT_ACTION_ORIGIN_PS4_CENTERPAD_TOUCH := 72
const INPUT_ACTION_ORIGIN_PS4_CIRCLE := 51
const INPUT_ACTION_ORIGIN_PS4_DPAD_EAST := 98
const INPUT_ACTION_ORIGIN_PS4_DPAD_MOVE := 103
const INPUT_ACTION_ORIGIN_PS4_DPAD_NORTH := 95
const INPUT_ACTION_ORIGIN_PS4_DPAD_SOUTH := 96
const INPUT_ACTION_ORIGIN_PS4_DPAD_WEST := 97
const INPUT_ACTION_ORIGIN_PS4_GYRO_MOVE := 99
const INPUT_ACTION_ORIGIN_PS4_GYRO_PITCH := 100
const INPUT_ACTION_ORIGIN_PS4_GYRO_ROLL := 102
const INPUT_ACTION_ORIGIN_PS4_GYRO_YAW := 101
const INPUT_ACTION_ORIGIN_PS4_LEFTBUMPER := 54
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_CLICK := 60
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_DPADEAST := 64
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_DPADNORTH := 61
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_DPADSOUTH := 62
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_DPADWEST := 63
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_SWIPE := 59
const INPUT_ACTION_ORIGIN_PS4_LEFTPAD_TOUCH := 58
const INPUT_ACTION_ORIGIN_PS4_LEFTSTICK_CLICK := 84
const INPUT_ACTION_ORIGIN_PS4_LEFTSTICK_DPADEAST := 88
const INPUT_ACTION_ORIGIN_PS4_LEFTSTICK_DPADNORTH := 85
const INPUT_ACTION_ORIGIN_PS4_LEFTSTICK_DPADSOUTH := 86
const INPUT_ACTION_ORIGIN_PS4_LEFTSTICK_DPADWEST := 87
const INPUT_ACTION_ORIGIN_PS4_LEFTSTICK_MOVE := 83
const INPUT_ACTION_ORIGIN_PS4_LEFTTRIGGER_CLICK := 80
const INPUT_ACTION_ORIGIN_PS4_LEFTTRIGGER_PULL := 79
const INPUT_ACTION_ORIGIN_PS4_OPTIONS := 56
const INPUT_ACTION_ORIGIN_PS4_RESERVED1 := 104
const INPUT_ACTION_ORIGIN_PS4_RESERVED10 := 113
const INPUT_ACTION_ORIGIN_PS4_RESERVED2 := 105
const INPUT_ACTION_ORIGIN_PS4_RESERVED3 := 106
const INPUT_ACTION_ORIGIN_PS4_RESERVED4 := 107
const INPUT_ACTION_ORIGIN_PS4_RESERVED5 := 108
const INPUT_ACTION_ORIGIN_PS4_RESERVED6 := 109
const INPUT_ACTION_ORIGIN_PS4_RESERVED7 := 110
const INPUT_ACTION_ORIGIN_PS4_RESERVED8 := 111
const INPUT_ACTION_ORIGIN_PS4_RESERVED9 := 112
const INPUT_ACTION_ORIGIN_PS4_RIGHTBUMPER := 55
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_CLICK := 67
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_DPADEAST := 71
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_DPADNORTH := 68
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_DPADSOUTH := 69
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_DPADWEST := 70
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_SWIPE := 66
const INPUT_ACTION_ORIGIN_PS4_RIGHTPAD_TOUCH := 65
const INPUT_ACTION_ORIGIN_PS4_RIGHTSTICK_CLICK := 90
const INPUT_ACTION_ORIGIN_PS4_RIGHTSTICK_DPADEAST := 94
const INPUT_ACTION_ORIGIN_PS4_RIGHTSTICK_DPADNORTH := 91
const INPUT_ACTION_ORIGIN_PS4_RIGHTSTICK_DPADSOUTH := 92
const INPUT_ACTION_ORIGIN_PS4_RIGHTSTICK_DPADWEST := 93
const INPUT_ACTION_ORIGIN_PS4_RIGHTSTICK_MOVE := 89
const INPUT_ACTION_ORIGIN_PS4_RIGHTTRIGGER_CLICK := 82
const INPUT_ACTION_ORIGIN_PS4_RIGHTTRIGGER_PULL := 81
const INPUT_ACTION_ORIGIN_PS4_SHARE := 57
const INPUT_ACTION_ORIGIN_PS4_SQUARE := 53
const INPUT_ACTION_ORIGIN_PS4_TRIANGLE := 52
const INPUT_ACTION_ORIGIN_PS4_X := 50
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_CLICK := 283
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_DPADEAST := 287
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_DPADNORTH := 284
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_DPADSOUTH := 285
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_DPADWEST := 286
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_SWIPE := 282
const INPUT_ACTION_ORIGIN_PS5_CENTERPAD_TOUCH := 281
const INPUT_ACTION_ORIGIN_PS5_CIRCLE := 259
const INPUT_ACTION_ORIGIN_PS5_CREATE := 265
const INPUT_ACTION_ORIGIN_PS5_DPAD_EAST := 307
const INPUT_ACTION_ORIGIN_PS5_DPAD_MOVE := 312
const INPUT_ACTION_ORIGIN_PS5_DPAD_NORTH := 304
const INPUT_ACTION_ORIGIN_PS5_DPAD_SOUTH := 305
const INPUT_ACTION_ORIGIN_PS5_DPAD_WEST := 306
const INPUT_ACTION_ORIGIN_PS5_GYRO_MOVE := 308
const INPUT_ACTION_ORIGIN_PS5_GYRO_PITCH := 309
const INPUT_ACTION_ORIGIN_PS5_GYRO_ROLL := 311
const INPUT_ACTION_ORIGIN_PS5_GYRO_YAW := 310
const INPUT_ACTION_ORIGIN_PS5_LEFTBUMPER := 262
const INPUT_ACTION_ORIGIN_PS5_LEFTFN := 315
const INPUT_ACTION_ORIGIN_PS5_LEFTGRIP := 313
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_CLICK := 269
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_DPADEAST := 273
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_DPADNORTH := 270
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_DPADSOUTH := 271
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_DPADWEST := 272
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_SWIPE := 268
const INPUT_ACTION_ORIGIN_PS5_LEFTPAD_TOUCH := 267
const INPUT_ACTION_ORIGIN_PS5_LEFTSTICK_CLICK := 293
const INPUT_ACTION_ORIGIN_PS5_LEFTSTICK_DPADEAST := 297
const INPUT_ACTION_ORIGIN_PS5_LEFTSTICK_DPADNORTH := 294
const INPUT_ACTION_ORIGIN_PS5_LEFTSTICK_DPADSOUTH := 295
const INPUT_ACTION_ORIGIN_PS5_LEFTSTICK_DPADWEST := 296
const INPUT_ACTION_ORIGIN_PS5_LEFTSTICK_MOVE := 292
const INPUT_ACTION_ORIGIN_PS5_LEFTTRIGGER_CLICK := 289
const INPUT_ACTION_ORIGIN_PS5_LEFTTRIGGER_PULL := 288
const INPUT_ACTION_ORIGIN_PS5_MUTE := 266
const INPUT_ACTION_ORIGIN_PS5_OPTION := 264
const INPUT_ACTION_ORIGIN_PS5_RESERVED10 := 322
const INPUT_ACTION_ORIGIN_PS5_RESERVED11 := 323
const INPUT_ACTION_ORIGIN_PS5_RESERVED12 := 324
const INPUT_ACTION_ORIGIN_PS5_RESERVED13 := 325
const INPUT_ACTION_ORIGIN_PS5_RESERVED14 := 326
const INPUT_ACTION_ORIGIN_PS5_RESERVED15 := 327
const INPUT_ACTION_ORIGIN_PS5_RESERVED16 := 328
const INPUT_ACTION_ORIGIN_PS5_RESERVED17 := 329
const INPUT_ACTION_ORIGIN_PS5_RESERVED18 := 330
const INPUT_ACTION_ORIGIN_PS5_RESERVED19 := 331
const INPUT_ACTION_ORIGIN_PS5_RESERVED20 := 332
const INPUT_ACTION_ORIGIN_PS5_RESERVED5 := 317
const INPUT_ACTION_ORIGIN_PS5_RESERVED6 := 318
const INPUT_ACTION_ORIGIN_PS5_RESERVED7 := 319
const INPUT_ACTION_ORIGIN_PS5_RESERVED8 := 320
const INPUT_ACTION_ORIGIN_PS5_RESERVED9 := 321
const INPUT_ACTION_ORIGIN_PS5_RIGHTBUMPER := 263
const INPUT_ACTION_ORIGIN_PS5_RIGHTFN := 316
const INPUT_ACTION_ORIGIN_PS5_RIGHTGRIP := 314
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_CLICK := 276
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_DPADEAST := 280
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_DPADNORTH := 277
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_DPADSOUTH := 278
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_DPADWEST := 279
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_SWIPE := 275
const INPUT_ACTION_ORIGIN_PS5_RIGHTPAD_TOUCH := 274
const INPUT_ACTION_ORIGIN_PS5_RIGHTSTICK_CLICK := 299
const INPUT_ACTION_ORIGIN_PS5_RIGHTSTICK_DPADEAST := 303
const INPUT_ACTION_ORIGIN_PS5_RIGHTSTICK_DPADNORTH := 300
const INPUT_ACTION_ORIGIN_PS5_RIGHTSTICK_DPADSOUTH := 301
const INPUT_ACTION_ORIGIN_PS5_RIGHTSTICK_DPADWEST := 302
const INPUT_ACTION_ORIGIN_PS5_RIGHTSTICK_MOVE := 298
const INPUT_ACTION_ORIGIN_PS5_RIGHTTRIGGER_CLICK := 291
const INPUT_ACTION_ORIGIN_PS5_RIGHTTRIGGER_PULL := 290
const INPUT_ACTION_ORIGIN_PS5_SQUARE := 261
const INPUT_ACTION_ORIGIN_PS5_TRIANGLE := 260
const INPUT_ACTION_ORIGIN_PS5_X := 258
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_A := 1
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_B := 2
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_BACK := 10
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_GYRO_MOVE := 35
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_GYRO_PITCH := 36
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_GYRO_ROLL := 38
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_GYRO_YAW := 37
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTBUMPER := 5
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTGRIP := 7
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_CLICK := 13
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_DPADEAST := 17
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_DPADNORTH := 14
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_DPADSOUTH := 15
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_DPADWEST := 16
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_SWIPE := 12
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTPAD_TOUCH := 11
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTSTICK_CLICK := 30
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTSTICK_DPADEAST := 34
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTSTICK_DPADNORTH := 31
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTSTICK_DPADSOUTH := 32
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTSTICK_DPADWEST := 33
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTSTICK_MOVE := 29
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTTRIGGER_CLICK := 26
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_LEFTTRIGGER_PULL := 25
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED0 := 39
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED1 := 40
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED10 := 49
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED2 := 41
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED3 := 42
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED4 := 43
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED5 := 44
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED6 := 45
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED7 := 46
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED8 := 47
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RESERVED9 := 48
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTBUMPER := 6
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTGRIP := 8
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_CLICK := 20
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_DPADEAST := 24
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_DPADNORTH := 21
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_DPADSOUTH := 22
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_DPADWEST := 23
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_SWIPE := 19
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTPAD_TOUCH := 18
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTTRIGGER_CLICK := 28
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_RIGHTTRIGGER_PULL := 27
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_START := 9
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_X := 3
const INPUT_ACTION_ORIGIN_STEAMCONTROLLER_Y := 4
const INPUT_ACTION_ORIGIN_STEAMDECK_A := 333
const INPUT_ACTION_ORIGIN_STEAMDECK_B := 334
const INPUT_ACTION_ORIGIN_STEAMDECK_DPAD_EAST := 381
const INPUT_ACTION_ORIGIN_STEAMDECK_DPAD_MOVE := 377
const INPUT_ACTION_ORIGIN_STEAMDECK_DPAD_NORTH := 378
const INPUT_ACTION_ORIGIN_STEAMDECK_DPAD_SOUTH := 379
const INPUT_ACTION_ORIGIN_STEAMDECK_DPAD_WEST := 380
const INPUT_ACTION_ORIGIN_STEAMDECK_GYRO_MOVE := 382
const INPUT_ACTION_ORIGIN_STEAMDECK_GYRO_PITCH := 383
const INPUT_ACTION_ORIGIN_STEAMDECK_GYRO_ROLL := 385
const INPUT_ACTION_ORIGIN_STEAMDECK_GYRO_YAW := 384
const INPUT_ACTION_ORIGIN_STEAMDECK_L1 := 337
const INPUT_ACTION_ORIGIN_STEAMDECK_L2 := 356
const INPUT_ACTION_ORIGIN_STEAMDECK_L2_SOFTPULL := 355
const INPUT_ACTION_ORIGIN_STEAMDECK_L3 := 360
const INPUT_ACTION_ORIGIN_STEAMDECK_L4 := 373
const INPUT_ACTION_ORIGIN_STEAMDECK_L5 := 375
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_CLICK := 343
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_DPADEAST := 347
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_DPADNORTH := 344
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_DPADSOUTH := 345
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_DPADWEST := 346
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_SWIPE := 342
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTPAD_TOUCH := 341
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTSTICK_DPADEAST := 364
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTSTICK_DPADNORTH := 361
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTSTICK_DPADSOUTH := 362
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTSTICK_DPADWEST := 363
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTSTICK_MOVE := 359
const INPUT_ACTION_ORIGIN_STEAMDECK_LEFTSTICK_TOUCH := 365
const INPUT_ACTION_ORIGIN_STEAMDECK_MENU := 339
const INPUT_ACTION_ORIGIN_STEAMDECK_R1 := 338
const INPUT_ACTION_ORIGIN_STEAMDECK_R2 := 358
const INPUT_ACTION_ORIGIN_STEAMDECK_R2_SOFTPULL := 357
const INPUT_ACTION_ORIGIN_STEAMDECK_R3 := 367
const INPUT_ACTION_ORIGIN_STEAMDECK_R4 := 374
const INPUT_ACTION_ORIGIN_STEAMDECK_R5 := 376
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED1 := 386
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED10 := 395
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED11 := 396
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED12 := 397
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED13 := 398
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED14 := 399
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED15 := 400
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED16 := 401
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED17 := 402
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED18 := 403
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED19 := 404
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED2 := 387
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED20 := 405
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED3 := 388
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED4 := 389
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED5 := 390
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED6 := 391
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED7 := 392
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED8 := 393
const INPUT_ACTION_ORIGIN_STEAMDECK_RESERVED9 := 394
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_CLICK := 350
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_DPADEAST := 354
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_DPADNORTH := 351
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_DPADSOUTH := 352
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_DPADWEST := 353
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_SWIPE := 349
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTPAD_TOUCH := 348
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTSTICK_DPADEAST := 371
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTSTICK_DPADNORTH := 368
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTSTICK_DPADSOUTH := 369
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTSTICK_DPADWEST := 370
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTSTICK_MOVE := 366
const INPUT_ACTION_ORIGIN_STEAMDECK_RIGHTSTICK_TOUCH := 372
const INPUT_ACTION_ORIGIN_STEAMDECK_VIEW := 340
const INPUT_ACTION_ORIGIN_STEAMDECK_X := 335
const INPUT_ACTION_ORIGIN_STEAMDECK_Y := 336
const INPUT_ACTION_ORIGIN_SWITCH_A := 192
const INPUT_ACTION_ORIGIN_SWITCH_B := 193
const INPUT_ACTION_ORIGIN_SWITCH_CAPTURE := 200
const INPUT_ACTION_ORIGIN_SWITCH_DPAD_EAST := 220
const INPUT_ACTION_ORIGIN_SWITCH_DPAD_MOVE := 225
const INPUT_ACTION_ORIGIN_SWITCH_DPAD_NORTH := 217
const INPUT_ACTION_ORIGIN_SWITCH_DPAD_SOUTH := 218
const INPUT_ACTION_ORIGIN_SWITCH_DPAD_WEST := 219
const INPUT_ACTION_ORIGIN_SWITCH_JOYCON_BUTTON_E := 249
const INPUT_ACTION_ORIGIN_SWITCH_JOYCON_BUTTON_N := 248
const INPUT_ACTION_ORIGIN_SWITCH_JOYCON_BUTTON_S := 250
const INPUT_ACTION_ORIGIN_SWITCH_JOYCON_BUTTON_W := 251
const INPUT_ACTION_ORIGIN_SWITCH_LEFTBUMPER := 196
const INPUT_ACTION_ORIGIN_SWITCH_LEFTGRIP_LOWER := 244
const INPUT_ACTION_ORIGIN_SWITCH_LEFTGRIP_UPPER := 245
const INPUT_ACTION_ORIGIN_SWITCH_LEFTGYRO_MOVE := 240
const INPUT_ACTION_ORIGIN_SWITCH_LEFTGYRO_PITCH := 241
const INPUT_ACTION_ORIGIN_SWITCH_LEFTGYRO_ROLL := 243
const INPUT_ACTION_ORIGIN_SWITCH_LEFTGYRO_YAW := 242
const INPUT_ACTION_ORIGIN_SWITCH_LEFTSTICK_CLICK := 206
const INPUT_ACTION_ORIGIN_SWITCH_LEFTSTICK_DPADEAST := 210
const INPUT_ACTION_ORIGIN_SWITCH_LEFTSTICK_DPADNORTH := 207
const INPUT_ACTION_ORIGIN_SWITCH_LEFTSTICK_DPADSOUTH := 208
const INPUT_ACTION_ORIGIN_SWITCH_LEFTSTICK_DPADWEST := 209
const INPUT_ACTION_ORIGIN_SWITCH_LEFTSTICK_MOVE := 205
const INPUT_ACTION_ORIGIN_SWITCH_LEFTTRIGGER_CLICK := 202
const INPUT_ACTION_ORIGIN_SWITCH_LEFTTRIGGER_PULL := 201
const INPUT_ACTION_ORIGIN_SWITCH_MINUS := 199
const INPUT_ACTION_ORIGIN_SWITCH_PLUS := 198
const INPUT_ACTION_ORIGIN_SWITCH_PROGYRO_MOVE := 221
const INPUT_ACTION_ORIGIN_SWITCH_PROGYRO_PITCH := 222
const INPUT_ACTION_ORIGIN_SWITCH_PROGYRO_ROLL := 224
const INPUT_ACTION_ORIGIN_SWITCH_PROGYRO_YAW := 223
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED1 := 226
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED10 := 235
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED15 := 252
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED16 := 253
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED17 := 254
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED18 := 255
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED19 := 256
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED2 := 227
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED20 := 257
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED3 := 228
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED4 := 229
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED5 := 230
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED6 := 231
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED7 := 232
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED8 := 233
const INPUT_ACTION_ORIGIN_SWITCH_RESERVED9 := 234
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTBUMPER := 197
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTGRIP_LOWER := 246
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTGRIP_UPPER := 247
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTGYRO_MOVE := 236
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTGYRO_PITCH := 237
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTGYRO_ROLL := 239
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTGYRO_YAW := 238
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTSTICK_CLICK := 212
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTSTICK_DPADEAST := 216
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTSTICK_DPADNORTH := 213
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTSTICK_DPADSOUTH := 214
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTSTICK_DPADWEST := 215
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTSTICK_MOVE := 211
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTTRIGGER_CLICK := 204
const INPUT_ACTION_ORIGIN_SWITCH_RIGHTTRIGGER_PULL := 203
const INPUT_ACTION_ORIGIN_SWITCH_X := 194
const INPUT_ACTION_ORIGIN_SWITCH_Y := 195
const INPUT_ACTION_ORIGIN_XBOX360_A := 153
const INPUT_ACTION_ORIGIN_XBOX360_B := 154
const INPUT_ACTION_ORIGIN_XBOX360_BACK := 160
const INPUT_ACTION_ORIGIN_XBOX360_DPAD_EAST := 180
const INPUT_ACTION_ORIGIN_XBOX360_DPAD_MOVE := 181
const INPUT_ACTION_ORIGIN_XBOX360_DPAD_NORTH := 177
const INPUT_ACTION_ORIGIN_XBOX360_DPAD_SOUTH := 178
const INPUT_ACTION_ORIGIN_XBOX360_DPAD_WEST := 179
const INPUT_ACTION_ORIGIN_XBOX360_LEFTBUMPER := 157
const INPUT_ACTION_ORIGIN_XBOX360_LEFTSTICK_CLICK := 166
const INPUT_ACTION_ORIGIN_XBOX360_LEFTSTICK_DPADEAST := 170
const INPUT_ACTION_ORIGIN_XBOX360_LEFTSTICK_DPADNORTH := 167
const INPUT_ACTION_ORIGIN_XBOX360_LEFTSTICK_DPADSOUTH := 168
const INPUT_ACTION_ORIGIN_XBOX360_LEFTSTICK_DPADWEST := 169
const INPUT_ACTION_ORIGIN_XBOX360_LEFTSTICK_MOVE := 165
const INPUT_ACTION_ORIGIN_XBOX360_LEFTTRIGGER_CLICK := 162
const INPUT_ACTION_ORIGIN_XBOX360_LEFTTRIGGER_PULL := 161
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED1 := 182
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED10 := 191
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED2 := 183
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED3 := 184
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED4 := 185
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED5 := 186
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED6 := 187
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED7 := 188
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED8 := 189
const INPUT_ACTION_ORIGIN_XBOX360_RESERVED9 := 190
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTBUMPER := 158
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTSTICK_CLICK := 172
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTSTICK_DPADEAST := 176
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTSTICK_DPADNORTH := 173
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTSTICK_DPADSOUTH := 174
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTSTICK_DPADWEST := 175
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTSTICK_MOVE := 171
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTTRIGGER_CLICK := 164
const INPUT_ACTION_ORIGIN_XBOX360_RIGHTTRIGGER_PULL := 163
const INPUT_ACTION_ORIGIN_XBOX360_START := 159
const INPUT_ACTION_ORIGIN_XBOX360_X := 155
const INPUT_ACTION_ORIGIN_XBOX360_Y := 156
const INPUT_ACTION_ORIGIN_XBOXONE_A := 114
const INPUT_ACTION_ORIGIN_XBOXONE_B := 115
const INPUT_ACTION_ORIGIN_XBOXONE_DPAD_EAST := 141
const INPUT_ACTION_ORIGIN_XBOXONE_DPAD_MOVE := 142
const INPUT_ACTION_ORIGIN_XBOXONE_DPAD_NORTH := 138
const INPUT_ACTION_ORIGIN_XBOXONE_DPAD_SOUTH := 139
const INPUT_ACTION_ORIGIN_XBOXONE_DPAD_WEST := 140
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTBUMPER := 118
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTGRIP_LOWER := 143
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTGRIP_UPPER := 144
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTSTICK_CLICK := 127
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTSTICK_DPADEAST := 131
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTSTICK_DPADNORTH := 128
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTSTICK_DPADSOUTH := 129
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTSTICK_DPADWEST := 130
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTSTICK_MOVE := 126
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTTRIGGER_CLICK := 123
const INPUT_ACTION_ORIGIN_XBOXONE_LEFTTRIGGER_PULL := 122
const INPUT_ACTION_ORIGIN_XBOXONE_MENU := 120
const INPUT_ACTION_ORIGIN_XBOXONE_RESERVED10 := 152
const INPUT_ACTION_ORIGIN_XBOXONE_RESERVED6 := 148
const INPUT_ACTION_ORIGIN_XBOXONE_RESERVED7 := 149
const INPUT_ACTION_ORIGIN_XBOXONE_RESERVED8 := 150
const INPUT_ACTION_ORIGIN_XBOXONE_RESERVED9 := 151
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTBUMPER := 119
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTGRIP_LOWER := 145
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTGRIP_UPPER := 146
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTSTICK_CLICK := 133
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTSTICK_DPADEAST := 137
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTSTICK_DPADNORTH := 134
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTSTICK_DPADSOUTH := 135
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTSTICK_DPADWEST := 136
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTSTICK_MOVE := 132
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTTRIGGER_CLICK := 125
const INPUT_ACTION_ORIGIN_XBOXONE_RIGHTTRIGGER_PULL := 124
const INPUT_ACTION_ORIGIN_XBOXONE_SHARE := 147
const INPUT_ACTION_ORIGIN_XBOXONE_VIEW := 121
const INPUT_ACTION_ORIGIN_XBOXONE_X := 116
const INPUT_ACTION_ORIGIN_XBOXONE_Y := 117
const INPUT_CONFIGURATION_ENABLE_TYPE_GENERIC := 4
const INPUT_CONFIGURATION_ENABLE_TYPE_NONE := 0
const INPUT_CONFIGURATION_ENABLE_TYPE_PLAYSTATION := 1
const INPUT_CONFIGURATION_ENABLE_TYPE_SWITCH := 8
const INPUT_CONFIGURATION_ENABLE_TYPE_XBOX := 2
const INPUT_GLYPH_SIZE_COUNT := 3
const INPUT_GLYPH_SIZE_LARGE := 2
const INPUT_GLYPH_SIZE_MEDIUM := 1
const INPUT_GLYPH_SIZE_SMALL := 0
const INPUT_GLYPH_STYLE_DARK := 2
const INPUT_GLYPH_STYLE_KNOCKOUT := 0
const INPUT_GLYPH_STYLE_LIGHT := 1
const INPUT_GLYPH_STYLE_NEUTRAL_COLOR_ABXY := 16
const INPUT_GLYPH_STYLE_SOLID_ABXY := 32
const INPUT_HANDLE_ALL_CONTROLLERS := -1
const INPUT_LED_FLAG_RESTORE_USER_DEFAULT := 1
const INPUT_LED_FLAG_SET_COLOR := 0
const INPUT_MAX_ACTIVE_LAYERS := 16
const INPUT_MAX_ANALOG_ACTIONS := 24
const INPUT_MAX_ANALOG_ACTION_DATA := 1
const INPUT_MAX_COUNT := 16
const INPUT_MAX_DIGITAL_ACTIONS := 256
const INPUT_MAX_ORIGINS := 8
const INPUT_MIN_ANALOG_ACTION_DATA := -1
const INPUT_SOURCE_MODE_ABSOLUTE_MOUSE := 4
const INPUT_SOURCE_MODE_BUTTONS := 2
const INPUT_SOURCE_MODE_DPAD := 1
const INPUT_SOURCE_MODE_FOUR_BUTTONS := 3
const INPUT_SOURCE_MODE_JOYSTICK_CAMERA := 8
const INPUT_SOURCE_MODE_JOYSTICK_MOUSE := 7
const INPUT_SOURCE_MODE_JOYSTICK_MOVE := 6
const INPUT_SOURCE_MODE_MOUSE_JOYSTICK := 12
const INPUT_SOURCE_MODE_MOUSE_REGION := 13
const INPUT_SOURCE_MODE_NONE := 0
const INPUT_SOURCE_MODE_RADIAL_MENU := 14
const INPUT_SOURCE_MODE_RELATIVE_MOUSE := 5
const INPUT_SOURCE_MODE_SCROLL_WHEEL := 9
const INPUT_SOURCE_MODE_SINGLE_BUTTON := 15
const INPUT_SOURCE_MODE_SWITCH := 16
const INPUT_SOURCE_MODE_TOUCH_MENU := 11
const INPUT_SOURCE_MODE_TRIGGER := 10
const INPUT_TYPE_ANDROID_CONTROLLER := 7
const INPUT_TYPE_APPLE_MFI_CONTROLLER := 6
const INPUT_TYPE_COUNT := 15
const INPUT_TYPE_GENERIC_XINPUT := 4
const INPUT_TYPE_MAXIMUM_POSSIBLE_VALUE := 255
const INPUT_TYPE_MOBILE_TOUCH := 11
const INPUT_TYPE_PS3_CONTROLLER := 12
const INPUT_TYPE_PS4_CONTROLLER := 5
const INPUT_TYPE_PS5_CONTROLLER := 13
const INPUT_TYPE_STEAM_CONTROLLER := 1
const INPUT_TYPE_STEAM_DECK_CONTROLLER := 14
const INPUT_TYPE_SWITCH_JOYCON_PAIR := 8
const INPUT_TYPE_SWITCH_JOYCON_SINGLE := 9
const INPUT_TYPE_SWITCH_PRO_CONTROLLER := 10
const INPUT_TYPE_UNKNOWN := 0
const INPUT_TYPE_XBOX360_CONTROLLER := 2
const INPUT_TYPE_XBOXONE_CONTROLLER := 3
const INVALID_BREAKPAD_HANDLE := 0
const INVALID_FRIEND_GROUP_ID := -1
const INVALID_HTMLBROWSER := 0
const INVALID_HTTPCOOKIE_HANDLE := 0
const INVALID_HTTPREQUEST_HANDLE := 0
const INVALID_SCREENSHOT_HANDLE := 0
const INVENTORY_RESULT_INVALID := -1
const IPV6_CONNECTIVITY_PROTOCOL_HTTP := 1
const IPV6_CONNECTIVITY_PROTOCOL_INVALID := 0
const IPV6_CONNECTIVITY_PROTOCOL_UDP := 2
const IPV6_CONNECTIVITY_STATE_BAD := 2
const IPV6_CONNECTIVITY_STATE_GOOD := 1
const IPV6_CONNECTIVITY_STATE_UNKNOWN := 0
const IP_TYPE_IPV4 := 0
const IP_TYPE_IPV6 := 1
const ITEM_INSTANCE_ID_INVALID := 0
const ITEM_PREVIEW_TYPE_CLIP := 5
const ITEM_PREVIEW_TYPE_ENVIRONMENTMAP_HORIZONTAL_CROSS := 3
const ITEM_PREVIEW_TYPE_ENVIRONMENTMAP_LAT_LONG := 4
const ITEM_PREVIEW_TYPE_IMAGE := 0
const ITEM_PREVIEW_TYPE_RESERVED_MAX := 255
const ITEM_PREVIEW_TYPE_SKETCHFAB := 2
const ITEM_PREVIEW_TYPE_YOUTUBE_VIDEO := 1
const ITEM_STATE_DISABLED_LOCALLY := 64
const ITEM_STATE_DOWNLOADING := 16
const ITEM_STATE_DOWNLOAD_PENDING := 32
const ITEM_STATE_INSTALLED := 4
const ITEM_STATE_LEGACY_ITEM := 2
const ITEM_STATE_NEEDS_UPDATE := 8
const ITEM_STATE_NONE := 0
const ITEM_STATE_SUBSCRIBED := 1
const ITEM_STATISTIC_NUM_COMMENTS := 10
const ITEM_STATISTIC_NUM_FAVORITES := 1
const ITEM_STATISTIC_NUM_FOLLOWERS := 2
const ITEM_STATISTIC_NUM_PLAYTIME_SESSIONS := 9
const ITEM_STATISTIC_NUM_PLAYTIME_SESSIONS_DURING_TIME_PERIOD := 12
const ITEM_STATISTIC_NUM_SECONDS_PLAYED := 8
const ITEM_STATISTIC_NUM_SECONDS_PLAYED_DURING_TIME_PERIOD := 11
const ITEM_STATISTIC_NUM_SUBSCRIPTIONS := 0
const ITEM_STATISTIC_NUM_UNIQUE_FAVORITES := 4
const ITEM_STATISTIC_NUM_UNIQUE_FOLLOWERS := 5
const ITEM_STATISTIC_NUM_UNIQUE_SUBSCRIPTIONS := 3
const ITEM_STATISTIC_NUM_UNIQUE_WEBSITE_VIEWS := 6
const ITEM_STATISTIC_REPORT_SCORE := 7
const ITEM_UPDATE_STATUS_COMMITTING_CHANGES := 5
const ITEM_UPDATE_STATUS_INVALID := 0
const ITEM_UPDATE_STATUS_PREPARING_CONFIG := 1
const ITEM_UPDATE_STATUS_PREPARING_CONTENT := 2
const ITEM_UPDATE_STATUS_UPLOADING_CONTENT := 3
const ITEM_UPDATE_STATUS_UPLOADING_PREVIEW_FILE := 4
const LEADERBOARD_DATA_REQUEST_FRIENDS := 2
const LEADERBOARD_DATA_REQUEST_GLOBAL := 0
const LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER := 1
const LEADERBOARD_DATA_REQUEST_USERS := 3
const LEADERBOARD_DETAILS_MAX := 64
const LEADERBOARD_DETAIL_MAX := 64
const LEADERBOARD_DISPLAY_TYPE_NONE := 0
const LEADERBOARD_DISPLAY_TYPE_NUMERIC := 1
const LEADERBOARD_DISPLAY_TYPE_TIME_MILLISECONDS := 3
const LEADERBOARD_DISPLAY_TYPE_TIME_SECONDS := 2
const LEADERBOARD_NAME_MAX := 128
const LEADERBOARD_SORT_METHOD_ASCENDING := 1
const LEADERBOARD_SORT_METHOD_DESCENDING := 2
const LEADERBOARD_SORT_METHOD_NONE := 0
const LEADERBOARD_UPLOAD_SCORE_METHOD_FORCE_UPDATE := 2
const LEADERBOARD_UPLOAD_SCORE_METHOD_KEEP_BEST := 1
const LEADERBOARD_UPLOAD_SCORE_METHOD_NONE := 0
const LISTEN_SOCKET_INVALID := 0
const LOBBY_COMPARISON_EQUAL := 0
const LOBBY_COMPARISON_EQUAL_TO_GREATER_THAN := 2
const LOBBY_COMPARISON_EQUAL_TO_OR_LESS_THAN := -2
const LOBBY_COMPARISON_GREATER_THAN := 1
const LOBBY_COMPARISON_LESS_THAN := -1
const LOBBY_COMPARISON_NOT_EQUAL := 3
const LOBBY_DISTANCE_FILTER_CLOSE := 0
const LOBBY_DISTANCE_FILTER_DEFAULT := 1
const LOBBY_DISTANCE_FILTER_FAR := 2
const LOBBY_DISTANCE_FILTER_WORLDWIDE := 3
const LOBBY_TYPE_FRIENDS_ONLY := 1
const LOBBY_TYPE_INVISIBLE := 3
const LOBBY_TYPE_PRIVATE := 0
const LOBBY_TYPE_PRIVATE_UNIQUE := 4
const LOBBY_TYPE_PUBLIC := 2
const LOCAL_FILE_CHANGE_FILE_DELETED := 2
const LOCAL_FILE_CHANGE_FILE_UPDATED := 1
const LOCAL_FILE_CHANGE_INVALID := 0
const MARKET_NOT_ALLOWED_REASON_ACCEPTED_WALLET_GIFT := 32768
const MARKET_NOT_ALLOWED_REASON_ACCOUNT_DISABLED := 2
const MARKET_NOT_ALLOWED_REASON_ACCOUNT_LIMITED := 8
const MARKET_NOT_ALLOWED_REASON_ACCOUNT_LOCKED_DOWN := 4
const MARKET_NOT_ALLOWED_REASON_ACCOUNT_NOT_TRUSTED := 32
const MARKET_NOT_ALLOWED_REASON_INVALID_COOKIE := 1024
const MARKET_NOT_ALLOWED_REASON_NEW_PAYMENT_METHOD := 512
const MARKET_NOT_ALLOWED_REASON_NEW_PAYMENT_METHOD_CANNOT_BE_VERIFIED := 8192
const MARKET_NOT_ALLOWED_REASON_NONE := 0
const MARKET_NOT_ALLOWED_REASON_NO_RECENT_PURCHASES := 16384
const MARKET_NOT_ALLOWED_REASON_RECENT_PASSWORD_RESET := 256
const MARKET_NOT_ALLOWED_REASON_RECENT_SELF_REFUND := 4096
const MARKET_NOT_ALLOWED_REASON_STEAM_GAURD_ONLY_RECENTLY_ENABLED := 128
const MARKET_NOT_ALLOWED_REASON_STEAM_GUARD_NOT_ENABLED := 64
const MARKET_NOT_ALLOWED_REASON_STEAM_GUARD_ONLY_RECENTLY_ENABLED := 128
const MARKET_NOT_ALLOWED_REASON_TEMPORARY_FAILURE := 1
const MARKET_NOT_ALLOWED_REASON_TRADE_BANNED := 16
const MARKET_NOT_ALLOWED_REASON_TRADE_COOLDOWN := 65536
const MARKET_NOT_ALLOWED_REASON_USING_NEW_DEVICE := 2048
const MAX_CLOUD_FILE_CHUNK_SIZE := 104857600
const MAX_FRIENDS_GROUP_NAME := 64
const MAX_GAME_SERVER_GAME_DATA := 2048
const MAX_GAME_SERVER_GAME_DESCRIPTION := 64
const MAX_GAME_SERVER_GAME_DIR := 32
const MAX_GAME_SERVER_MAP_NAME := 32
const MAX_GAME_SERVER_NAME := 64
const MAX_GAME_SERVER_TAGS := 128
const MAX_LOBBY_KEY_LENGTH := 255
const MAX_NETWORKING_ERROR_MESSAGE := 1024
const MAX_NETWORKING_PING_LOCATION_STRING := 1024
const MAX_RICH_PRESENCE_KEYS := 20
const MAX_RICH_PRESENCE_KEY_LENGTH := 64
const MAX_RICH_PRESENCE_VALUE_LENTH := 256
const MAX_STEAM_PACKET_SIZE := 524288
const MAX_TAGGED_PUBLISHED_FILES := 32
const MAX_TAGGED_USERS := 32
const MUSIC_NAME_MAX_LENGTH := 255
const MUSIC_PNG_MAX_LENGTH := 65535
const NETWORKING_AVAILABILITY_ATTEMPTING := 3
const NETWORKING_AVAILABILITY_CANNOT_TRY := -102
const NETWORKING_AVAILABILITY_CURRENT := 100
const NETWORKING_AVAILABILITY_FAILED := -101
const NETWORKING_AVAILABILITY_FORCE_32BIT := 2147483647
const NETWORKING_AVAILABILITY_NEVER_TRIED := 1
const NETWORKING_AVAILABILITY_PREVIOUSLY := -100
const NETWORKING_AVAILABILITY_RETRYING := -10
const NETWORKING_AVAILABILITY_UNKNOWN := 0
const NETWORKING_AVAILABILITY_WAITING := 2
const NETWORKING_CONFIG_CALLBACK_AUTH_STATUS_CHANGED := 202
const NETWORKING_CONFIG_CALLBACK_CONNECTION_STATUS_CHANGED := 201
const NETWORKING_CONFIG_CALLBACK_CREATE_CONNECTION_SIGNALING := 206
const NETWORKING_CONFIG_CALLBACK_FAKE_IP_RESULT := 207
const NETWORKING_CONFIG_CALLBACK_MESSAGES_SESSION_FAILED := 205
const NETWORKING_CONFIG_CALLBACK_MESSAGE_SESSION_REQUEST := 204
const NETWORKING_CONFIG_CALLBACK_RELAY_NETWORK_STATUS_CHANGED := 203
const NETWORKING_CONFIG_CONNECTION_USER_DATA := 40
const NETWORKING_CONFIG_DUAL_WIFI_ENABLE := 39
const NETWORKING_CONFIG_ECN := 999
const NETWORKING_CONFIG_ENABLE_DIAGNOSTICS_UI := 46
const NETWORKING_CONFIG_FAKE_PACKET_DUP_REVC := 27
const NETWORKING_CONFIG_FAKE_PACKET_DUP_SEND := 26
const NETWORKING_CONFIG_FAKE_PACKET_DUP_TIME_MAX := 28
const NETWORKING_CONFIG_FAKE_PACKET_LAG_RECV := 5
const NETWORKING_CONFIG_FAKE_PACKET_LAG_SEND := 4
const NETWORKING_CONFIG_FAKE_PACKET_LOSS_RECV := 3
const NETWORKING_CONFIG_FAKE_PACKET_LOSS_SEND := 2
const NETWORKING_CONFIG_FAKE_PACKET_REORDER_RECV := 7
const NETWORKING_CONFIG_FAKE_PACKET_REORDER_SEND := 6
const NETWORKING_CONFIG_FAKE_PACKET_REORDER_TIME := 8
const NETWORKING_CONFIG_FAKE_RATE_LIMIT_RECV_BURST := 45
const NETWORKING_CONFIG_FAKE_RATE_LIMIT_RECV_RATE := 44
const NETWORKING_CONFIG_FAKE_RATE_LIMIT_SEND_BURST := 43
const NETWORKING_CONFIG_FAKE_RATE_LIMIT_SEND_RATE := 42
const NETWORKING_CONFIG_INVALID := 0
const NETWORKING_CONFIG_IP_ALLOW_WITHOUT_AUTH := 23
const NETWORKING_CONFIG_IP_LOCAL_HOST_ALLOW_WITHOUT_AUTH := 52
const NETWORKING_CONFIG_LOCAL_VIRTUAL_PORT := 38
const NETWORKING_CONFIG_LOG_LEVEL_ACK_RTT := 13
const NETWORKING_CONFIG_LOG_LEVEL_MESSAGE := 15
const NETWORKING_CONFIG_LOG_LEVEL_P2P_RENDEZVOUS := 17
const NETWORKING_CONFIG_LOG_LEVEL_PACKET_DECODE := 14
const NETWORKING_CONFIG_LOG_LEVEL_PACKET_GAPS := 16
const NETWORKING_CONFIG_LOG_LEVEL_SRD_RELAY_PINGS := 18
const NETWORKING_CONFIG_MTU_DATA_SIZE := 33
const NETWORKING_CONFIG_MTU_PACKET_SIZE := 32
const NETWORKING_CONFIG_NAGLE_TIME := 12
const NETWORKING_CONFIG_OUT_OF_ORDER_CORRECTION_WINDOW_MICROSECONDS := 51
const NETWORKING_CONFIG_P2P_STUN_SERVER_LIST := 103
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_ALL := 2147483647
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_DEFAULT := -1
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_DISABLE := 0
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_ENABLE := 104
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_IMPLEMENTATION := 110
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_PENALTY := 105
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_PRIVATE := 2
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_PUBLIC := 4
const NETWORKING_CONFIG_P2P_TRANSPORT_ICE_RELAY := 1
const NETWORKING_CONFIG_P2P_TRANSPORT_SDR_PENALTY := 106
const NETWORKING_CONFIG_P2P_TURN_PASS_LIST := 109
const NETWORKING_CONFIG_P2P_TURN_SERVER_LIST := 107
const NETWORKING_CONFIG_P2P_TURN_USER_LIST := 108
const NETWORKING_CONFIG_PACKET_TRACE_MAX_BYTES := 41
const NETWORKING_CONFIG_RECV_BUFFER_MESSAGES := 48
const NETWORKING_CONFIG_RECV_BUFFER_SIZE := 47
const NETWORKING_CONFIG_RECV_MAX_MESSAGE_SIZE := 49
const NETWORKING_CONFIG_RECV_MAX_SEGMENTS_PER_PACKET := 50
const NETWORKING_CONFIG_SCOPE_CONNECTION := 4
const NETWORKING_CONFIG_SCOPE_FORCE_32BIT := 2147483647
const NETWORKING_CONFIG_SCOPE_GLOBAL := 1
const NETWORKING_CONFIG_SCOPE_LISTEN_SOCKET := 3
const NETWORKING_CONFIG_SCOPE_SOCKETS_INTERFACE := 2
const NETWORKING_CONFIG_SDR_CLIENT_CONSEC_PING_TIMEOUT_FAIL := 20
const NETWORKING_CONFIG_SDR_CLIENT_CONSEC_PING_TIMEOUT_FAIL_INITIAL := 19
const NETWORKING_CONFIG_SDR_CLIENT_DEBUG_TICKET_ADDRESS := 30
const NETWORKING_CONFIG_SDR_CLIENT_DEV_TICKET := 30
const NETWORKING_CONFIG_SDR_CLIENT_FAKE_CLUSTER_PING := 36
const NETWORKING_CONFIG_SDR_CLIENT_FORCE_PROXY_ADDR := 31
const NETWORKING_CONFIG_SDR_CLIENT_FORCE_RELAY_CLUSTER := 29
const NETWORKING_CONFIG_SDR_CLIENT_LIMIT_PING_PROBES_TO_NEAREST_N := 60
const NETWORKING_CONFIG_SDR_CLIENT_MIN_PINGS_BEFORE_PING_ACCURATE := 21
const NETWORKING_CONFIG_SDR_CLIENT_SINGLE_SOCKET := 22
const NETWORKING_CONFIG_SEND_BUFFER_SIZE := 9
const NETWORKING_CONFIG_SEND_RATE_MAX := 11
const NETWORKING_CONFIG_SEND_RATE_MIN := 10
const NETWORKING_CONFIG_SEND_TIME_SINCE_PREVIOUS_PACKET := 59
const NETWORKING_CONFIG_SYMMETRIC_CONNECT := 37
const NETWORKING_CONFIG_TIMEOUT_CONNECTED := 25
const NETWORKING_CONFIG_TIMEOUT_INITIAL := 24
const NETWORKING_CONFIG_TYPE_FLOAT := 3
const NETWORKING_CONFIG_TYPE_FORCE_32BIT := 2147483647
const NETWORKING_CONFIG_TYPE_FUNCTION_PTR := 5
const NETWORKING_CONFIG_TYPE_INT32 := 1
const NETWORKING_CONFIG_TYPE_INT64 := 2
const NETWORKING_CONFIG_TYPE_STRING := 4
const NETWORKING_CONFIG_UNENCRYPTED := 34
const NETWORKING_CONFIG_VALUE_FORCE32BIT := 2147483647
const NETWORKING_CONNECTION_INFO_FLAG_DUALWIFI := 32
const NETWORKING_CONNECTION_INFO_FLAG_FAST := 8
const NETWORKING_CONNECTION_INFO_FLAG_LOOPBACK_BUFFERS := 4
const NETWORKING_CONNECTION_INFO_FLAG_RELAYED := 16
const NETWORKING_CONNECTION_INFO_FLAG_UNAUTHENTICATED := 1
const NETWORKING_CONNECTION_INFO_FLAG_UNENCRYPTED := 2
const NETWORKING_CONNECTION_INVALID := 0
const NETWORKING_GET_CONFIG_VALUE_BAD_SCOPE_OBJ := -2
const NETWORKING_GET_CONFIG_VALUE_BAD_VALUE := -1
const NETWORKING_GET_CONFIG_VALUE_BUFFER_TOO_SMALL := -3
const NETWORKING_GET_CONFIG_VALUE_FORCE_32BIT := 2147483647
const NETWORKING_GET_CONFIG_VALUE_OK := 1
const NETWORKING_GET_CONFIG_VALUE_OK_INHERITED := 2
const NETWORKING_MAX_CONNECTION_APP_NAME := 32
const NETWORKING_MAX_CONNECTION_CLOSE_REASON := 128
const NETWORKING_MAX_CONNECTION_DESCRIPTION := 128
const NETWORKING_PING_FAILED := -1
const NETWORKING_PING_UNKNOWN := -2
const NETWORKING_SEND_AUTORESTART_BROKEN_SESSION := 32
const NETWORKING_SEND_NO_DELAY := 4
const NETWORKING_SEND_NO_NAGLE := 1
const NETWORKING_SEND_RELIABLE := 8
const NETWORKING_SEND_RELIABLE_NO_NAGLE := 9
const NETWORKING_SEND_UNRELIABLE := 0
const NETWORKING_SEND_UNRELIABLE_NO_DELAY := 5
const NETWORKING_SEND_URELIABLE_NO_NAGLE := 1
const NETWORKING_SEND_USE_CURRENT_THREAD := 16
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_BUG := 1
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_DEBUG := 7
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_ERROR := 2
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_EVERYTHING := 8
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_FORCE_32BIT := 2147483647
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_IMPORTANT := 3
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_MSG := 5
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_NONE := 0
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_VERBOSE := 6
const NETWORKING_SOCKET_DEBUG_OUTPUT_TYPE_WARNING := 4
const NET_SOCKET_CONNECTION_TYPE_NOT_CONNECTED := 0
const NET_SOCKET_CONNECTION_TYPE_UDP := 1
const NET_SOCKET_CONNECTION_TYPE_UDP_RELAY := 2
const NET_SOCKET_STATE_BROKEN := 25
const NET_SOCKET_STATE_CHALLENGE_HANDSHAKE := 15
const NET_SOCKET_STATE_CONNECTED := 1
const NET_SOCKET_STATE_DISCONNECTING := 21
const NET_SOCKET_STATE_INITIATED := 10
const NET_SOCKET_STATE_INVALID := 0
const NET_SOCKET_STATE_LOCAL_CANDIDATE_FOUND := 11
const NET_SOCKET_STATE_LOCAL_DISCONNECT := 22
const NET_SOCKET_STATE_RECEIVED_REMOTE_CANDIDATES := 12
const NET_SOCKET_STATE_REMOTE_END_DISCONNECTED := 24
const NET_SOCKET_STATE_TIMEOUT_DURING_CONNECT := 23
const NO_SERVERS_LISTED_ON_MASTER_SERVER := 2
const NUM_UGC_RESULTS_PER_PAGE := 50
const OVERLAY_TO_STORE_FLAG_ADD_TO_CART := 1
const OVERLAY_TO_STORE_FLAG_AND_TO_CART_AND_SHOW := 2
const OVERLAY_TO_STORE_FLAG_NONE := 0
const OVERLAY_TO_WEB_PAGE_MODE_DEFAULT := 0
const OVERLAY_TO_WEB_PAGE_MODE_MODAL := 1
const P2P_SEND_RELIABLE_WITH_BUFFERING := 3
const P2P_SEND_UNRELIABLE := 0
const P2P_SEND_UNRELIABLE_NO_DELAY := 1
const P2P_SESSION_ERROR_DESTINATION_NOT_LOGGED_ON := 3
const P2P_SESSION_ERROR_MAX := 5
const P2P_SESSION_ERROR_NONE := 0
const P2P_SESSION_ERROR_NOT_RUNNING_APP := 1
const P2P_SESSION_ERROR_NO_RIGHTS_TO_APP := 2
const P2P_SESSION_ERROR_TIMEOUT := 4
const PAD_TRIGGER_EFFECT_MODE_FEEDBACK := 1
const PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_FEEDBACK := 4
const PAD_TRIGGER_EFFECT_MODE_MULTIPLE_POSITION_VIBRATION := 6
const PAD_TRIGGER_EFFECT_MODE_OFF := 0
const PAD_TRIGGER_EFFECT_MODE_SLOPE_FEEDBACK := 5
const PAD_TRIGGER_EFFECT_MODE_VIBRATION := 3
const PAD_TRIGGER_EFFECT_MODE_WEAPON := 2
const PERSONA_CHANGE_AVATAR := 64
const PERSONA_CHANGE_COME_ONLINE := 4
const PERSONA_CHANGE_FACEBOOK_INFO := 2048
const PERSONA_CHANGE_GAME_PLAYED := 16
const PERSONA_CHANGE_GAME_SERVER := 32
const PERSONA_CHANGE_GONE_OFFLINE := 8
const PERSONA_CHANGE_JOINED_SOURCE := 128
const PERSONA_CHANGE_LEFT_SOURCE := 256
const PERSONA_CHANGE_NAME := 1
const PERSONA_CHANGE_NAME_FIRST_SET := 1024
const PERSONA_CHANGE_NICKNAME := 4096
const PERSONA_CHANGE_RELATIONSHIP_CHANGED := 512
const PERSONA_CHANGE_RICH_PRESENCE := 16384
const PERSONA_CHANGE_STATUS := 2
const PERSONA_CHANGE_STEAM_LEVEL := 8192
const PERSONA_NAME_MAX_UTF16 := 32
const PERSONA_NAME_MAX_UTF8 := 128
const PERSONA_STATE_AWAY := 3
const PERSONA_STATE_BUSY := 2
const PERSONA_STATE_INVISIBLE := 7
const PERSONA_STATE_LOOKING_TO_PLAY := 6
const PERSONA_STATE_LOOKING_TO_TRADE := 5
const PERSONA_STATE_MAX := 8
const PERSONA_STATE_OFFLINE := 0
const PERSONA_STATE_ONLINE := 1
const PERSONA_STATE_SNOOZE := 4
const PLAYER_RESULT_ABANDONED := 2
const PLAYER_RESULT_COMPLETED := 5
const PLAYER_RESULT_FAILED_TO_CONNECT := 1
const PLAYER_RESULT_INCOMPLETE := 4
const PLAYER_RESULT_KICKED := 3
const POSITION_BOTTOM_LEFT := 2
const POSITION_BOTTOM_RIGHT := 3
const POSITION_INVALID := -1
const POSITION_TOP_LEFT := 0
const POSITION_TOP_RIGHT := 1
const PROFILE_ITEM_PROPERTY_APP_ID := 5
const PROFILE_ITEM_PROPERTY_CLASS := 7
const PROFILE_ITEM_PROPERTY_DESCRIPTION := 4
const PROFILE_ITEM_PROPERTY_IMAGE_LARGE := 1
const PROFILE_ITEM_PROPERTY_IMAGE_SMALL := 0
const PROFILE_ITEM_PROPERTY_INTERNAL_NAME := 2
const PROFILE_ITEM_PROPERTY_MOVIE_MP4 := 9
const PROFILE_ITEM_PROPERTY_MOVIE_MP4_SMALL := 11
const PROFILE_ITEM_PROPERTY_MOVIE_WEBM := 8
const PROFILE_ITEM_PROPERTY_MOVIE_WEBM_SMALL := 10
const PROFILE_ITEM_PROPERTY_TITLE := 3
const PROFILE_ITEM_PROPERTY_TYPE_ID := 6
const PROFILE_ITEM_TYPE_ANIMATED_AVATAR := 0
const PROFILE_ITEM_TYPE_AVATAR_FRAME := 1
const PROFILE_ITEM_TYPE_MINI_PROFILE_BACKGROUND := 4
const PROFILE_ITEM_TYPE_PROFILE_BACKGROUND := 3
const PROFILE_ITEM_TYPE_PROFILE_MODIFIER := 2
const PUBLISHED_DOCUMENT_CHANGE_DESCRIPTION_MAX := 8000
const PUBLISHED_DOCUMENT_DESCRIPTION_MAX := 8000
const PUBLISHED_DOCUMENT_TITLE_MAX := 129
const PUBLISHED_FILE_ID_INVALID := 0
const PUBLISHED_FILE_UPDATE_HANDLE_INVALID := 0
const PUBLISHED_FILE_URL_MAX := 256
const QUERY_PORT_ERROR := 65534
const QUERY_PORT_NOT_INITIALIZED := 65535
const REMOTE_PLAYER_SCANCODE_0 := 39
const REMOTE_PLAYER_SCANCODE_1 := 30
const REMOTE_PLAYER_SCANCODE_2 := 31
const REMOTE_PLAYER_SCANCODE_3 := 32
const REMOTE_PLAYER_SCANCODE_4 := 33
const REMOTE_PLAYER_SCANCODE_5 := 34
const REMOTE_PLAYER_SCANCODE_6 := 35
const REMOTE_PLAYER_SCANCODE_7 := 36
const REMOTE_PLAYER_SCANCODE_8 := 37
const REMOTE_PLAYER_SCANCODE_9 := 38
const REMOTE_PLAYER_SCANCODE_A := 4
const REMOTE_PLAYER_SCANCODE_APOSTROPHE := 52
const REMOTE_PLAYER_SCANCODE_B := 5
const REMOTE_PLAYER_SCANCODE_BACKSLASH := 49
const REMOTE_PLAYER_SCANCODE_BACKSPACE := 42
const REMOTE_PLAYER_SCANCODE_C := 6
const REMOTE_PLAYER_SCANCODE_CAPSLOCK := 57
const REMOTE_PLAYER_SCANCODE_COMMA := 54
const REMOTE_PLAYER_SCANCODE_D := 7
const REMOTE_PLAYER_SCANCODE_DELETE := 76
const REMOTE_PLAYER_SCANCODE_DOWN := 81
const REMOTE_PLAYER_SCANCODE_E := 8
const REMOTE_PLAYER_SCANCODE_END := 77
const REMOTE_PLAYER_SCANCODE_EQUALS := 46
const REMOTE_PLAYER_SCANCODE_ESCAPE := 41
const REMOTE_PLAYER_SCANCODE_F := 9
const REMOTE_PLAYER_SCANCODE_F1 := 58
const REMOTE_PLAYER_SCANCODE_F10 := 67
const REMOTE_PLAYER_SCANCODE_F11 := 68
const REMOTE_PLAYER_SCANCODE_F12 := 69
const REMOTE_PLAYER_SCANCODE_F2 := 59
const REMOTE_PLAYER_SCANCODE_F3 := 60
const REMOTE_PLAYER_SCANCODE_F4 := 61
const REMOTE_PLAYER_SCANCODE_F5 := 62
const REMOTE_PLAYER_SCANCODE_F6 := 63
const REMOTE_PLAYER_SCANCODE_F7 := 64
const REMOTE_PLAYER_SCANCODE_F8 := 65
const REMOTE_PLAYER_SCANCODE_F9 := 66
const REMOTE_PLAYER_SCANCODE_G := 10
const REMOTE_PLAYER_SCANCODE_GRAVE := 53
const REMOTE_PLAYER_SCANCODE_H := 11
const REMOTE_PLAYER_SCANCODE_HOME := 74
const REMOTE_PLAYER_SCANCODE_I := 12
const REMOTE_PLAYER_SCANCODE_INSERT := 73
const REMOTE_PLAYER_SCANCODE_J := 13
const REMOTE_PLAYER_SCANCODE_K := 14
const REMOTE_PLAYER_SCANCODE_KEYPAD_0 := 98
const REMOTE_PLAYER_SCANCODE_KEYPAD_1 := 89
const REMOTE_PLAYER_SCANCODE_KEYPAD_2 := 90
const REMOTE_PLAYER_SCANCODE_KEYPAD_3 := 91
const REMOTE_PLAYER_SCANCODE_KEYPAD_4 := 92
const REMOTE_PLAYER_SCANCODE_KEYPAD_5 := 93
const REMOTE_PLAYER_SCANCODE_KEYPAD_6 := 94
const REMOTE_PLAYER_SCANCODE_KEYPAD_7 := 95
const REMOTE_PLAYER_SCANCODE_KEYPAD_8 := 96
const REMOTE_PLAYER_SCANCODE_KEYPAD_9 := 97
const REMOTE_PLAYER_SCANCODE_KEYPAD_DIVIDE := 84
const REMOTE_PLAYER_SCANCODE_KEYPAD_ENTER := 88
const REMOTE_PLAYER_SCANCODE_KEYPAD_MINUS := 86
const REMOTE_PLAYER_SCANCODE_KEYPAD_MULTIPLY := 85
const REMOTE_PLAYER_SCANCODE_KEYPAD_PERIOD := 99
const REMOTE_PLAYER_SCANCODE_KEYPAD_PLUS := 87
const REMOTE_PLAYER_SCANCODE_L := 15
const REMOTE_PLAYER_SCANCODE_LEFT := 80
const REMOTE_PLAYER_SCANCODE_LEFT_ALT := 226
const REMOTE_PLAYER_SCANCODE_LEFT_BRACKET := 47
const REMOTE_PLAYER_SCANCODE_LEFT_CONTROL := 224
const REMOTE_PLAYER_SCANCODE_LEFT_GUI := 227
const REMOTE_PLAYER_SCANCODE_LEFT_SHIFT := 225
const REMOTE_PLAYER_SCANCODE_M := 16
const REMOTE_PLAYER_SCANCODE_MINUS := 45
const REMOTE_PLAYER_SCANCODE_N := 17
const REMOTE_PLAYER_SCANCODE_O := 18
const REMOTE_PLAYER_SCANCODE_P := 19
const REMOTE_PLAYER_SCANCODE_PAGE_DOWN := 78
const REMOTE_PLAYER_SCANCODE_PAGE_UP := 75
const REMOTE_PLAYER_SCANCODE_PERIOD := 55
const REMOTE_PLAYER_SCANCODE_Q := 20
const REMOTE_PLAYER_SCANCODE_R := 21
const REMOTE_PLAYER_SCANCODE_RETURN := 40
const REMOTE_PLAYER_SCANCODE_RIGHT := 79
const REMOTE_PLAYER_SCANCODE_RIGHT_ALT := 230
const REMOTE_PLAYER_SCANCODE_RIGHT_BRACKET := 48
const REMOTE_PLAYER_SCANCODE_RIGHT_CONTROL := 228
const REMOTE_PLAYER_SCANCODE_RIGHT_GUI := 231
const REMOTE_PLAYER_SCANCODE_RIGHT_SHIFT := 229
const REMOTE_PLAYER_SCANCODE_S := 22
const REMOTE_PLAYER_SCANCODE_SEMICOLON := 51
const REMOTE_PLAYER_SCANCODE_SLASH := 56
const REMOTE_PLAYER_SCANCODE_SPACE := 44
const REMOTE_PLAYER_SCANCODE_T := 23
const REMOTE_PLAYER_SCANCODE_TAB := 43
const REMOTE_PLAYER_SCANCODE_U := 24
const REMOTE_PLAYER_SCANCODE_UNKNOWN := 0
const REMOTE_PLAYER_SCANCODE_UP := 82
const REMOTE_PLAYER_SCANCODE_V := 25
const REMOTE_PLAYER_SCANCODE_W := 26
const REMOTE_PLAYER_SCANCODE_X := 27
const REMOTE_PLAYER_SCANCODE_Y := 28
const REMOTE_PLAYER_SCANCODE_Z := 29
const REMOTE_PLAY_INPUT_KEY_DOWN := 5
const REMOTE_PLAY_INPUT_KEY_UP := 6
const REMOTE_PLAY_INPUT_MOUSE_BUTTON_DOWN := 2
const REMOTE_PLAY_INPUT_MOUSE_BUTTON_UP := 3
const REMOTE_PLAY_INPUT_MOUSE_MOTION := 1
const REMOTE_PLAY_INPUT_MOUSE_WHEEL := 4
const REMOTE_PLAY_INPUT_UNKNOWN := 0
const REMOTE_PLAY_KEY_MODIFIER_CAPS_LOCK := 8192
const REMOTE_PLAY_KEY_MODIFIER_LEFT_ALT := 256
const REMOTE_PLAY_KEY_MODIFIER_LEFT_CONTROL := 64
const REMOTE_PLAY_KEY_MODIFIER_LEFT_GUI := 1024
const REMOTE_PLAY_KEY_MODIFIER_LEFT_SHIFT := 1
const REMOTE_PLAY_KEY_MODIFIER_MASK := 65535
const REMOTE_PLAY_KEY_MODIFIER_NONE := 0
const REMOTE_PLAY_KEY_MODIFIER_NUM_LOCK := 4096
const REMOTE_PLAY_KEY_MODIFIER_RIGHT_ALT := 512
const REMOTE_PLAY_KEY_MODIFIER_RIGHT_CONTROL := 128
const REMOTE_PLAY_KEY_MODIFIER_RIGHT_GUI := 2048
const REMOTE_PLAY_KEY_MODIFIER_RIGHT_SHIFT := 2
const REMOTE_PLAY_MOUSE_BUTTON_LEFT := 1
const REMOTE_PLAY_MOUSE_BUTTON_MIDDLE := 16
const REMOTE_PLAY_MOUSE_BUTTON_RIGHT := 2
const REMOTE_PLAY_MOUSE_BUTTON_X1 := 32
const REMOTE_PLAY_MOUSE_BUTTON_X2 := 64
const REMOTE_PLAY_MOUSE_WHEEL_DOWN := 2
const REMOTE_PLAY_MOUSE_WHEEL_LEFT := 3
const REMOTE_PLAY_MOUSE_WHEEL_RIGHT := 4
const REMOTE_PLAY_MOUSE_WHEEL_UP := 1
const REMOTE_STORAGE_PLATFORM_ALL := -1
const REMOTE_STORAGE_PLATFORM_ANDROID := 32
const REMOTE_STORAGE_PLATFORM_IOS := 64
const REMOTE_STORAGE_PLATFORM_LINUX := 8
const REMOTE_STORAGE_PLATFORM_NONE := 0
const REMOTE_STORAGE_PLATFORM_OSX := 2
const REMOTE_STORAGE_PLATFORM_PS3 := 4
const REMOTE_STORAGE_PLATFORM_SWITCH := 16
const REMOTE_STORAGE_PLATFORM_WINDOWS := 1
const REMOTE_STORAGE_PUBLISHED_VISIBILITY_FRIENDS_ONLY := 1
const REMOTE_STORAGE_PUBLISHED_VISIBILITY_PRIVATE := 2
const REMOTE_STORAGE_PUBLISHED_VISIBILITY_PUBLIC := 0
const REMOTE_STORAGE_PUBLISHED_VISIBILITY_UNLISTED := 3
const RESULT_ACCESS_DENIED := 15
const RESULT_ACCOUNT_ACTIVITY_LIMIT_EXCEEDED := 96
const RESULT_ACCOUNT_ASSOCIATED_TO_MULTIPLE_PARTNERS := 90
const RESULT_ACCOUNT_DELETED := 114
const RESULT_ACCOUNT_DISABLED := 43
const RESULT_ACCOUNT_LIMIT_EXCEEDED := 95
const RESULT_ACCOUNT_LOCKED_DOWN := 73
const RESULT_ACCOUNT_LOGIN_DENIED_NEED_TWO_FACTOR := 85
const RESULT_ACCOUNT_LOGIN_DENIED_THROTTLE := 87
const RESULT_ACCOUNT_LOG_ON_DENIED := 63
const RESULT_ACCOUNT_LOG_ON_DENIED_NO_MAIL := 66
const RESULT_ACCOUNT_LOG_ON_DENIED_VERIFIED_EMAIL_REQUIRED := 74
const RESULT_ACCOUNT_NOT_FEATURED := 45
const RESULT_ACCOUNT_NOT_FOUND := 18
const RESULT_ACCOUNT_NOT_FRIENDS := 111
const RESULT_ADMINISTRATOR_OK := 46
const RESULT_ADMINISTRATO_ROK := 46
const RESULT_ALREADY_LOGGED_IN_ELSEWHERE := 50
const RESULT_ALREADY_OWNED := 30
const RESULT_ALREADY_REDEEMED := 28
const RESULT_BAD_RESPONSE := 76
const RESULT_BANNED := 17
const RESULT_BLOCKED := 40
const RESULT_BUSY := 10
const RESULT_CACHED_CREDENTIAL_INVALID := 126
const RESULT_CANCELLED := 52
const RESULT_CANNOT_USE_OLD_PASSWORD := 64
const RESULT_CANT_REMOVE_ITEM := 113
const RESULT_CHARGER_REQUIRED := 125
const RESULT_COMMUNITY_COOLDOWN := 116
const RESULT_CONNECT_FAILED := 35
const RESULT_CONTENT_VERSION := 47
const RESULT_DATA_CORRUPTION := 53
const RESULT_DISABLED := 80
const RESULT_DISK_FULL := 54
const RESULT_DUPLICATE_NAME := 14
const RESULT_DUPLICATE_REQUEST := 29
const RESULT_EMAIL_SEND_FAILURE := 99
const RESULT_ENCRYPTION_FAILURE := 23
const RESULT_EXISTING_USER_CANCELLED_LICENSE := 115
const RESULT_EXPIRED := 27
const RESULT_EXPIRED_LOGIN_AUTH_CODE := 71
const RESULT_EXTERNAL_ACCOUNT_ALREADY_LINKED := 59
const RESULT_EXTERNAL_ACCOUNT_UNLINKED := 57
const RESULT_FACEBOOK_QUERY_ERROR := 70
const RESULT_FAIL := 2
const RESULT_FAMILY_SIZE_LIMIT_EXCEEDED := 129
const RESULT_FILE_NOT_FOUND := 9
const RESULT_GSLT_DENIED := 102
const RESULT_GSLT_EXPIRED := 106
const RESULT_GS_OWNER_DENIED := 103
const RESULT_HANDSHAKE_FAILED := 36
const RESULT_HARDWARE_NOT_CAPABLE_OF_IPT := 67
const RESULT_IGNORED := 41
const RESULT_ILLEGAL_PASSWORD := 61
const RESULT_INSUFFICIENT_BATTERY := 124
const RESULT_INSUFFICIENT_FUNDS := 107
const RESULT_INSUFFICIENT_PRIVILEGE := 24
const RESULT_INVALID_CEG_SUBMISSION := 81
const RESULT_INVALID_EMAIL := 13
const RESULT_INVALID_ITEM_TYPE := 104
const RESULT_INVALID_LOG_IN_AUTH_CODE := 65
const RESULT_INVALID_NAME := 12
const RESULT_INVALID_PARAM := 8
const RESULT_INVALID_PASSWORD := 5
const RESULT_INVALID_PROTOCOL_VER := 7
const RESULT_INVALID_SIGNATURE := 121
const RESULT_INVALID_STATE := 11
const RESULT_INVALID_STEAMID := 19
const RESULT_IO_FAILURE := 37
const RESULT_IPT_INIT_ERROR := 68
const RESULT_IP_BANNED := 105
const RESULT_IP_LOGIN_RESTRICTION_FAILED := 72
const RESULT_IP_NOT_FOUND := 31
const RESULT_ITEM_DELETED := 86
const RESULT_LAUNCHER_MIGRATED := 119
const RESULT_LIMITED_USER_ACCOUNT := 112
const RESULT_LIMIT_EXCEEDED := 25
const RESULT_LOCKING_FAILED := 33
const RESULT_LOGGED_IN_ELSEWHERE := 6
const RESULT_LOG_ON_SESSION_REPLACED := 34
const RESULT_MUST_AGREE_TO_SSA := 118
const RESULT_NEED_CAPTCHA := 101
const RESULT_NONE := 0
const RESULT_NOT_LOGGED_ON := 21
const RESULT_NOT_MODIFIED := 91
const RESULT_NOT_SETTLED := 100
const RESULT_NOT_SUPPORTED := 128
const RESULT_NO_CONNECTION := 3
const RESULT_NO_LAUNCHER_SPECIFIED := 117
const RESULT_NO_MATCH := 42
const RESULT_NO_MATCHING_URL := 75
const RESULT_NO_MOBILE_DEVICE := 92
const RESULT_NO_SITE_LICENSES_FOUND := 109
const RESULT_NO_VERIFIED_PHONE := 123
const RESULT_OFFLINE_APP_CACHE_INVALID := 130
const RESULT_PARENTAL_CONTROL_RESTRICTED := 69
const RESULT_PARSE_FAILURE := 122
const RESULT_PASSWORD_REQUIRED_TO_KICK_SESSION := 49
const RESULT_PASSWORD_UNSET := 56
const RESULT_PENDING := 22
const RESULT_PERSIST_FAILED := 32
const RESULT_PHONE_ACTIVITY_LIMIT_EXCEEDED := 97
const RESULT_PHONE_NUMBER_IS_VOIP := 127
const RESULT_PSN_TICKET_INVALID := 58
const RESULT_RATE_LIMIT_EXCEEDED := 84
const RESULT_REFUND_TO_WALLET := 98
const RESULT_REGION_LOCKED := 83
const RESULT_REMOTE_CALL_FAILED := 55
const RESULT_REMOTE_DISCONNECT := 38
const RESULT_REMOTE_FILE_CONFLICT := 60
const RESULT_REQUIRE_PASSWORD_REENTRY := 77
const RESULT_RESTRICTED_DEVICE := 82
const RESULT_REVOKED := 26
const RESULT_SAME_AS_PREVIOUS_VALUE := 62
const RESULT_SERVICE_READ_ONLY := 44
const RESULT_SERVICE_UNAVAILABLE := 20
const RESULT_SHOPPING_CART_NOT_FOUND := 39
const RESULT_SMS_CODE_FAILED := 94
const RESULT_STEAM_REALM_MISMATCH := 120
const RESULT_SUSPENDED := 51
const RESULT_TIMEOUT := 16
const RESULT_TIME_NOT_SYNCED := 93
const RESULT_TOO_MANY_PENDING := 108
const RESULT_TRY_ANOTHER_CM := 48
const RESULT_TRY_LATER := 131
const RESULT_TWO_FACTOR_ACTIVATION_CODE_MISMATCH := 89
const RESULT_TWO_FACTOR_CODE_MISMATCH := 88
const RESULT_UNEXPECTED_ERROR := 79
const RESULT_VALUE_OUT_OF_RANGE := 78
const RESULT_WG_NETWORK_SEND_EXCEEDED := 110
const SCREENSHOT_INVALID_HANDLE := 0
const SCREENSHOT_THUMB_WIDTH := 200
const SERVER_FAILED_TO_RESPOND := 1
const SERVER_QUERY_INVALID := -1
const SERVER_RESPONDED := 0
const SONY_PAD_TRIGGER_EFFECT_CONTROL_POINT_NUM := 10
const SONY_PAD_TRIGGER_EFFECT_PARAM_INDEX_FOR_L2 := 0
const SONY_PAD_TRIGGER_EFFECT_PARAM_INDEX_FOR_R2 := 1
const SONY_PAD_TRIGGER_EFFECT_TRIGGER_MASK_L2 := 1
const SONY_PAD_TRIGGER_EFFECT_TRIGGER_MASK_R2 := 2
const SONY_PAD_TRIGGER_EFFECT_TRIGGER_NUM := 2
const STAT_NAME_MAX := 128
const STEAM_ACCOUNT_ID_MASK := -1
const STEAM_ACCOUNT_INSTANCE_MASK := 1048575
const STEAM_API_CALL_FAILURE_INVALID_HANDLE := 2
const STEAM_API_CALL_FAILURE_MISMATCHED_CALLBACK := 3
const STEAM_API_CALL_FAILURE_NETWORK_FAILURE := 1
const STEAM_API_CALL_FAILURE_NONE := -1
const STEAM_API_CALL_FAILURE_STEAM_GONE := 0
const STEAM_API_INIT_RESULT_FAILED_GENERIC := 1
const STEAM_API_INIT_RESULT_NO_STEAM_CLIENT := 2
const STEAM_API_INIT_RESULT_OK := 0
const STEAM_API_INIT_RESULT_VERSION_MISMATCH := 3
const STEAM_BUFFER_SIZE := 255
const STEAM_CONTROLLER_PAD_LEFT := 0
const STEAM_CONTROLLER_PAD_RIGHT := 1
const STEAM_ITEM_CONSUMED := 512
const STEAM_ITEM_NO_TRADE := 1
const STEAM_ITEM_REMOVED := 256
const STEAM_LARGE_BUFFER_SIZE := 8160
const STEAM_MAX_ERROR_MESSAGE := 1024
const STEAM_PARTY_BEACON_LOCATIONTYPE_CHAT_GROUP := 1
const STEAM_PARTY_BEACON_LOCATIONTYPE_INVALID := 0
const STEAM_PARTY_BEACON_LOCATION_DATA := 0
const STEAM_PARTY_BEACON_LOCATION_DATA_INVALID := 0
const STEAM_PARTY_BEACON_LOCATION_DATA_NAME := 1
const STEAM_PARTY_BEACON_LOCATION_DATA_URL_LARGE := 4
const STEAM_PARTY_BEACON_LOCATION_DATA_URL_MEDIUM := 3
const STEAM_PARTY_BEACON_LOCATION_DATA_URL_SMALL := 2
const STEAM_PARTY_BEACON_LOCATION_TYPE_CHAT_GROUP := 1
const STEAM_PARTY_BEACON_LOCATION_TYPE_INVALID := 0
const STEAM_PARTY_BEACON_LOCATION_TYPE_MAX := 2
const STEAM_USER_CONSOLE_INSTANCE := 2
const STEAM_USER_DEFAULT_INSTANCE := 1
const STEAM_USER_DESKTOP_INSTANCE := 1
const STEAM_USER_WEB_INSTANCE := 4
const TAG_LIST_MAX := 1025
const TEXT_FILTERING_CONTEXT_CHAT := 2
const TEXT_FILTERING_CONTEXT_GAME_CONTENT := 1
const TEXT_FILTERING_CONTEXT_NAME := 3
const TEXT_FILTERING_CONTEXT_UNKNOWN := 0
const TIMELINE_EVENT_CLIP_PRIORITY_FEATURED := 3
const TIMELINE_EVENT_CLIP_PRIORITY_INVALID := 0
const TIMELINE_EVENT_CLIP_PRIORITY_NONE := 1
const TIMELINE_EVENT_CLIP_PRIORITY_STANDARD := 2
const TIMELINE_GAME_MODE_INVALID := 0
const TIMELINE_GAME_MODE_LOADING_SCREEN := 4
const TIMELINE_GAME_MODE_MAX := 5
const TIMELINE_GAME_MODE_MENUS := 3
const TIMELINE_GAME_MODE_PLAYING := 1
const TIMELINE_GAME_MODE_STAGING := 2
const UFS_TAG_TYPE_MAX := 255
const UFS_TAG_VALUE_MAX := 255
const UGCCONTENTDESCRIPTOR_ADULT_ONLY_SEXUAL_CONTENT := 3
const UGCCONTENTDESCRIPTOR_ANY_MATURE_CONTENT := 5
const UGCCONTENTDESCRIPTOR_FREQUENT_VIOLENCE_OR_GORE := 2
const UGCCONTENTDESCRIPTOR_GRATUITOUS_SEXUAL_CONTENT := 4
const UGCCONTENTDESCRIPTOR_NUDITY_OR_SEXUAL_CONTENT := 1
const UGC_CONTENT_DESCRIPTOR_ADULT_ONLY_SEXUAL_CONTENT := 3
const UGC_CONTENT_DESCRIPTOR_ANY_MATURE_CONTENT := 5
const UGC_CONTENT_DESCRIPTOR_FREQUENT_VIOLENCE_OR_GORE := 2
const UGC_CONTENT_DESCRIPTOR_GRATUITOUS_SEXUAL_CONTENT := 4
const UGC_CONTENT_DESCRIPTOR_NUDITY_OR_SEXUAL_CONTENT := 1
const UGC_FILE_STREAM_HANDLE_INVALID := 0
const UGC_HANDLE_INVALID := 0
const UGC_MATCHINGUGCTYPE_ITEMS := 0
const UGC_MATCHING_UGC_TYPE_ALL := -1
const UGC_MATCHING_UGC_TYPE_ALL_GUIDES := 7
const UGC_MATCHING_UGC_TYPE_ARTWORK := 4
const UGC_MATCHING_UGC_TYPE_COLLECTIONS := 3
const UGC_MATCHING_UGC_TYPE_CONTROLLER_BINDINGS := 11
const UGC_MATCHING_UGC_TYPE_GAME_MANAGED_ITEMS := 12
const UGC_MATCHING_UGC_TYPE_INTEGRATED_GUIDES := 9
const UGC_MATCHING_UGC_TYPE_ITEMS := 0
const UGC_MATCHING_UGC_TYPE_ITEMS_MTX := 1
const UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE := 2
const UGC_MATCHING_UGC_TYPE_SCREENSHOTS := 6
const UGC_MATCHING_UGC_TYPE_USABLE_IN_GAME := 10
const UGC_MATCHING_UGC_TYPE_VIDEOS := 5
const UGC_MATCHING_UGC_TYPE_WEB_GUIDES := 8
const UGC_QUERY_ACCEPTED_FOR_GAME_RANKED_BY_ACCEPTANCE_DATE := 2
const UGC_QUERY_CREATED_BY_FOLLOWED_USERS_RANKED_BY_PUBLICATION_DATE := 7
const UGC_QUERY_CREATED_BY_FRIENDS_RANKED_BY_PUBLICATION_DATE := 5
const UGC_QUERY_FAVORITED_BY_FRIENDS_RANKED_BY_PUBLICATION_DATE := 4
const UGC_QUERY_HANDLE_INVALID := 0
const UGC_QUERY_NOT_YET_RATED := 8
const UGC_QUERY_RANKED_BY_AVERAGE_PLAYTIME_TREND := 15
const UGC_QUERY_RANKED_BY_LAST_UPDATED_DATE := 19
const UGC_QUERY_RANKED_BY_LIFETIME_AVERAGE_PLAYTIME := 16
const UGC_QUERY_RANKED_BY_LIFETIME_PLAYTIME_SESSIONS := 18
const UGC_QUERY_RANKED_BY_NUM_TIMES_REPORTED := 6
const UGC_QUERY_RANKED_BY_PLAYTIME_SESSIONS_TREND := 17
const UGC_QUERY_RANKED_BY_PLAYTIME_TREND := 13
const UGC_QUERY_RANKED_BY_PUBLICATION_DATE := 1
const UGC_QUERY_RANKED_BY_TEXT_SEARCH := 11
const UGC_QUERY_RANKED_BY_TOTAL_PLAYTIME := 14
const UGC_QUERY_RANKED_BY_TOTAL_UNIQUE_SUBSCRIPTIONS := 12
const UGC_QUERY_RANKED_BY_TOTAL_VOTES_ASC := 9
const UGC_QUERY_RANKED_BY_TREND := 3
const UGC_QUERY_RANKED_BY_VOTE := 0
const UGC_QUERY_RANKED_BY_VOTES_UP := 10
const UGC_READ_CLOSE := 2
const UGC_READ_CONTINUE_READING := 1
const UGC_READ_CONTINUE_READING_UNTIL_FINISHED := 0
const UGC_UPDATE_HANDLE_INVALID := 0
const UNIVERSE_BETA := 2
const UNIVERSE_DEV := 4
const UNIVERSE_INTERNAL := 3
const UNIVERSE_INVALID := 0
const UNIVERSE_MAX := 5
const UNIVERSE_PUBLIC := 1
const USERUGCLISTSORTORDER_CREATIONORDERASC := 1
const USERUGCLISTSORTORDER_FORMODERATION := 6
const USERUGCLISTSORTORDER_LASTUPDATEDDESC := 3
const USERUGCLISTSORTORDER_SUBSCRIPTIONDATEDESC := 4
const USERUGCLISTSORTORDER_TITLEASC := 2
const USERUGCLISTSORTORDER_VOTESCOREDESC := 5
const USER_HAS_LICENSE_RESULT_DOES_NOT_HAVE_LICENSE := 1
const USER_HAS_LICENSE_RESULT_HAS_LICENSE := 0
const USER_HAS_LICENSE_RESULT_NO_AUTH := 2
const USER_RESTRICTION_ANY_CHAT := 2
const USER_RESTRICTION_GAME_INVITES := 32
const USER_RESTRICTION_GROUP_CHAT := 8
const USER_RESTRICTION_NONE := 0
const USER_RESTRICTION_RATING := 16
const USER_RESTRICTION_TRADING := 64
const USER_RESTRICTION_UNKNOWN := 1
const USER_RESTRICTION_VOICE_CHAT := 4
const USER_UGC_LIST_FAVORITED := 5
const USER_UGC_LIST_FOLLOWED := 8
const USER_UGC_LIST_SORT_ORDER_CREATION_ORDER_ASC := 1
const USER_UGC_LIST_SORT_ORDER_CREATION_ORDER_DESC := 0
const USER_UGC_LIST_SORT_ORDER_FOR_MODERATION := 6
const USER_UGC_LIST_SORT_ORDER_LAST_UPDATED_DESC := 3
const USER_UGC_LIST_SORT_ORDER_SUBSCRIPTION_DATE_DESC := 4
const USER_UGC_LIST_SORT_ORDER_TITLE_ASC := 2
const USER_UGC_LIST_SORT_ORDER_VOTE_SCORE_DESC := 5
const USER_UGC_LIST_SUBSCRIBED := 6
const USER_UGC_LIST_USED_OR_PLAYED := 7
const USER_UGC_LIST_VOTED_DOWN := 3
const USER_UGC_LIST_VOTED_ON := 1
const USER_UGC_LIST_VOTED_UP := 2
const USER_UGC_LIST_WILL_VOTE_LATER := 4
const VOICE_RESULT_BUFFER_TOO_SMALL := 4
const VOICE_RESULT_DATA_CORRUPTED := 5
const VOICE_RESULT_NOT_INITIALIZED := 1
const VOICE_RESULT_NOT_RECORDING := 2
const VOICE_RESULT_NO_DATA := 3
const VOICE_RESULT_NO_DATE := 3
const VOICE_RESULT_OK := 0
const VOICE_RESULT_RECEIVER_DID_NOT_ANSWER := 9
const VOICE_RESULT_RECEIVER_OUT_OF_DATE := 8
const VOICE_RESULT_RESTRICTED := 6
const VOICE_RESULT_UNSUPPORTED_CODEC := 7
const VR_SCREENSHOT_TYPE_MONO := 1
const VR_SCREENSHOT_TYPE_MONO_CUBE_MAP := 3
const VR_SCREENSHOT_TYPE_MONO_PANORAMA := 4
const VR_SCREENSHOT_TYPE_NONE := 0
const VR_SCREENSHOT_TYPE_STEREO := 2
const VR_SCREENSHOT_TYPE_STEREO_PANORAMA := 5
const WORKSHOP_ENUMERATION_TYPE_CONTENT_BY_FRIENDS := 5
const WORKSHOP_ENUMERATION_TYPE_FAVORITES_OF_FRIENDS := 3
const WORKSHOP_ENUMERATION_TYPE_RANKED_BY_VOTE := 0
const WORKSHOP_ENUMERATION_TYPE_RECENT := 1
const WORKSHOP_ENUMERATION_TYPE_RECENT_FROM_FOLLOWED_USERS := 6
const WORKSHOP_ENUMERATION_TYPE_TRENDING := 2
const WORKSHOP_ENUMERATION_TYPE_VOTED_BY_FRIENDS := 4
const WORKSHOP_FILE_ACTION_COMPLETED := 1
const WORKSHOP_FILE_ACTION_PLAYED := 0
const WORKSHOP_FILE_TYPE_ART := 3
const WORKSHOP_FILE_TYPE_CLIP := 16
const WORKSHOP_FILE_TYPE_COLLECTION := 2
const WORKSHOP_FILE_TYPE_CONCEPT := 8
const WORKSHOP_FILE_TYPE_CONTROLLER_BINDING := 12
const WORKSHOP_FILE_TYPE_FIRST := 0
const WORKSHOP_FILE_TYPE_GAME := 6
const WORKSHOP_FILE_TYPE_GAME_MANAGED_ITEM := 15
const WORKSHOP_FILE_TYPE_INTEGRATED_GUIDE := 10
const WORKSHOP_FILE_TYPE_MAX := 16
const WORKSHOP_FILE_TYPE_MERCH := 11
const WORKSHOP_FILE_TYPE_MICROTRANSACTION := 1
const WORKSHOP_FILE_TYPE_SCREENSHOT := 5
const WORKSHOP_FILE_TYPE_SOFTWARE := 7
const WORKSHOP_FILE_TYPE_STEAMWORKS_ACCESS_INVITE := 13
const WORKSHOP_FILE_TYPE_STEAM_VIDEO := 14
const WORKSHOP_FILE_TYPE_VIDEO := 4
const WORKSHOP_FILE_TYPE_WEB_GUIDE := 9
const WORKSHOP_VIDEO_PROVIDER_NONE := 0
const WORKSHOP_VIDEO_PROVIDER_YOUTUBE := 1
const WORKSHOP_VOTE_AGAINST := 2
const WORKSHOP_VOTE_FOR := 1
const WORKSHOP_VOTE_LATER := 3
const WORKSHOP_VOTE_UNVOTED := 0
const XBOX_ORIGIN_A := 0
const XBOX_ORIGIN_B := 1
const XBOX_ORIGIN_COUNT := 28
const XBOX_ORIGIN_DPAD_EAST := 27
const XBOX_ORIGIN_DPAD_NORTH := 24
const XBOX_ORIGIN_DPAD_SOUTH := 25
const XBOX_ORIGIN_DPAD_WEST := 26
const XBOX_ORIGIN_LEFT_BUMPER := 4
const XBOX_ORIGIN_LEFT_STICK_CLICK := 13
const XBOX_ORIGIN_LEFT_STICK_DPAD_EAT := 17
const XBOX_ORIGIN_LEFT_STICK_DPAD_NORTH := 14
const XBOX_ORIGIN_LEFT_STICK_DPAD_SOUTH := 15
const XBOX_ORIGIN_LEFT_STICK_DPAD_WEST := 16
const XBOX_ORIGIN_LEFT_STICK_MOVE := 12
const XBOX_ORIGIN_LEFT_TRIGGER_CLICK := 9
const XBOX_ORIGIN_LEFT_TRIGGER_PULL := 8
const XBOX_ORIGIN_MENU := 6
const XBOX_ORIGIN_RIGHT_BUMPER := 5
const XBOX_ORIGIN_RIGHT_STICK_CLICK := 19
const XBOX_ORIGIN_RIGHT_STICK_DPAD_EAST := 23
const XBOX_ORIGIN_RIGHT_STICK_DPAD_NORTH := 20
const XBOX_ORIGIN_RIGHT_STICK_DPAD_SOUTH := 21
const XBOX_ORIGIN_RIGHT_STICK_DPAD_WEST := 22
const XBOX_ORIGIN_RIGHT_STICK_MOVE := 18
const XBOX_ORIGIN_RIGHT_TRIGGER_CLICK := 11
const XBOX_ORIGIN_RIGHT_TRIGGER_PULL := 10
const XBOX_ORIGIN_VIEW := 7
const XBOX_ORIGIN_X := 2
const XBOX_ORIGIN_Y := 3

const RELAY_SIGNALS := {
	"lobby_created": 2,
	"lobby_match_list": 1,
	"lobby_joined": 4,
	"lobby_chat_update": 4,
	"lobby_message": 4,
	"lobby_data_update": 0,
	"lobby_invite": 3,
	"join_requested": 2,
	"persona_state_change": 2,
	"p2p_session_request": 1,
	"p2p_session_connect_fail": 2,
	"get_auth_session_ticket_response": 2,
	"validate_auth_ticket_response": 3,
	"ugc_query_completed": 5,
	"current_stats_received": 3,
	"item_created": 3,
	"item_updated": 2,
	"avatar_loaded": 3,
	"encrypted_app_ticket_response": 1,
	"get_item_vote_result": 5,
	"set_user_item_vote": 3,
	"active_beacons_updated": 0,
	"add_app_dependency_result": 3,
	"add_ugc_dependency_result": 3,
	"app_installed": 2,
	"app_resuming_from_suspend": 0,
	"app_uninstalled": 2,
	"available_beacon_locations_updated": 0,
	"avatar_image_loaded": 4,
	"change_num_open_slots": 1,
	"change_server_requested": 2,
	"check_file_signature": 1,
	"clan_activity_downloaded": 1,
	"client_game_server_deny": 5,
	"connected_chat_join": 2,
	"connected_chat_leave": 4,
	"connected_clan_chat_message": 1,
	"connected_friend_chat_message": 1,
	"create_beacon": 2,
	"dlc_installed": 1,
	"download_ugc_result": 2,
	"duration_control": 2,
	"end_game_result": 2,
	"enumerate_following_list": 2,
	"equipped_profile_items": 3,
	"equipped_profile_items_changed": 1,
	"fake_ip_result": 4,
	"favorites_list_accounts_updated": 1,
	"favorites_list_changed": 1,
	"file_details_result": 4,
	"file_read_async_complete": 1,
	"file_share_result": 3,
	"file_write_async_complete": 1,
	"filter_text_dictionary_changed": 1,
	"floating_gamepad_text_input_dismissed": 0,
	"friend_rich_presence_update": 2,
	"game_web_callback": 1,
	"gamepad_text_input_dismissed": 3,
	"get_app_dependencies_result": 4,
	"get_follower_count": 3,
	"get_opf_settings_result": 2,
	"get_ticket_for_web_api": 4,
	"get_video_result": 3,
	"global_achievement_percentages_ready": 2,
	"global_stats_received": 2,
	"html_browser_ready": 1,
	"html_can_go_backandforward": 3,
	"html_changed_title": 2,
	"html_close_browser": 1,
	"html_file_open_dialog": 3,
	"html_finished_request": 3,
	"html_hide_tooltip": 2,
	"html_horizontal_scroll": 2,
	"html_js_alert": 2,
	"html_js_confirm": 2,
	"html_link_at_position": 2,
	"html_needs_paint": 2,
	"html_new_window": 2,
	"html_open_link_in_new_tab": 2,
	"html_search_results": 3,
	"html_set_cursor": 2,
	"html_show_tooltip": 2,
	"html_start_request": 5,
	"html_status_text": 2,
	"html_update_tooltip": 2,
	"html_url_changed": 2,
	"html_vertical_scroll": 2,
	"http_request_completed": 5,
	"http_request_data_received": 4,
	"http_request_headers_received": 2,
	"input_action_event": 0,
	"input_configuration_loaded": 3,
	"input_device_connected": 1,
	"input_device_disconnected": 1,
	"input_gamepad_slot_change": 5,
	"inventory_definition_update": 1,
	"inventory_eligible_promo_item": 3,
	"inventory_full_update": 1,
	"inventory_request_prices_result": 2,
	"inventory_result_ready": 2,
	"inventory_start_purchase_result": 3,
	"ip_country": 0,
	"ipc_failure": 1,
	"is_following": 3,
	"item_deleted": 2,
	"item_downloaded": 3,
	"item_installed": 2,
	"join_clan_chat_complete": 2,
	"join_game_requested": 2,
	"join_party": 4,
	"leaderboard_find_result": 2,
	"leaderboard_score_uploaded": 3,
	"leaderboard_scores_downloaded": 2,
	"leaderboard_ugc_set": 2,
	"licenses_updated": 0,
	"lobby_game_created": 4,
	"lobby_kicked": 3,
	"local_file_changed": 0,
	"low_power": 1,
	"microtransaction_auth_response": 3,
	"music_player_remote_to_front": 0,
	"music_player_remote_will_activate": 0,
	"music_player_remote_will_deactivate": 0,
	"music_player_selects_playlist_entry": 1,
	"music_player_selects_queue_entry": 1,
	"music_player_wants_looped": 1,
	"music_player_wants_pause": 0,
	"music_player_wants_play": 0,
	"music_player_wants_play_next": 0,
	"music_player_wants_play_previous": 0,
	"music_player_wants_playing_repeat_status": 1,
	"music_player_wants_shuffled": 1,
	"music_player_wants_volume": 1,
	"music_player_will_quit": 0,
	"name_changed": 3,
	"network_authentication_status": 2,
	"network_connection_status_changed": 3,
	"network_messages_session_failed": 1,
	"network_messages_session_request": 1,
	"new_launch_url_parameters": 0,
	"number_of_current_players": 2,
	"overlay_browser_protocol": 1,
	"overlay_toggled": 3,
	"parental_setting_changed": 0,
	"relay_network_status": 5,
	"remote_play_session_connected": 1,
	"remote_play_session_disconnected": 1,
	"remove_app_dependency_result": 3,
	"remove_ugc_dependency_result": 3,
	"request_clan_officer_list": 2,
	"request_players_for_game_final_result": 3,
	"request_players_for_game_progress": 2,
	"request_players_for_game_result": 3,
	"reservation_notification": 2,
	"screenshot_ready": 2,
	"screenshot_requested": 0,
	"search_for_game_progress": 3,
	"search_for_game_result": 3,
	"server_connect_failure": 2,
	"server_connected": 0,
	"server_disconnected": 1,
	"server_failed_to_respond": 0,
	"server_responded": 0,
	"start_playtime_tracking": 1,
	"steam_api_call_completed": 3,
	"steam_server_connect_failed": 2,
	"steam_server_connected": 0,
	"steam_server_disconnected": 0,
	"steam_shutdown": 0,
	"steamworks_error": 2,
	"stop_playtime_tracking": 1,
	"store_auth_url_response": 1,
	"submit_player_result": 3,
	"subscribe_item": 2,
	"timed_trial_status": 4,
	"unread_chat_messages_changed": 0,
	"unsubscribe_item": 2,
	"user_achievement_stored": 5,
	"user_favorite_items_list_changed": 3,
	"user_stats_received": 3,
	"user_stats_stored": 2,
	"user_stats_unloaded": 1,
	"user_subscribed_items_list_changed": 1,
	"workshop_eula_status": 3,
	"music_playback_status_has_changed": 0,
	"music_volume_has_changed": 0,
	"ping_server_failed_to_respond": 0,
	"ping_server_responded": 1,
	"player_details_failed_to_respond": 0,
	"player_details_player_added": 3,
	"player_details_refresh_complete": 0,
	"request_server_list_refresh_complete": 2,
	"request_server_list_server_failed_to_respond": 2,
	"request_server_list_server_responded": 2,
	"server_rules_failed_to_respond": 0,
	"server_rules_refresh_complete": 0,
	"server_rules_responded": 2,
	"broadcast_upload_start": 1,
	"broadcast_upload_stop": 1,
	"market_eligibility_response": 5,
	"published_file_subscribed": 2,
	"published_file_unsubscribed": 2,
	"remote_play_guest_invite": 1,
	"timeline_event_recording_exists": 2,
	"timeline_game_phase_recording_exists": 5,
	"user_achievement_icon_fetched": 4,
}

var _native = null
var _native_methods = {}


func _enter_tree() -> void:
	if not Engine.has_singleton("Steam"):
		return
	_native = Engine.get_singleton("Steam")
	for method_info in _native.get_method_list():
		_native_methods[method_info["name"]] = method_info
	for signal_name in RELAY_SIGNALS:
		if _native.has_signal(signal_name):
			_native.connect(signal_name, self, "_relay" + str(RELAY_SIGNALS[signal_name]), [signal_name])


func is_native() -> bool:
	return _native != null


func _forward(method_name: String, args: Array, fallback = null):
	if _native == null or not _native.has_method(method_name):
		return fallback
	var call_args = args.duplicate()
	var method_info = _native_methods.get(method_name)
	if method_info != null:
		var expected = method_info["args"].size()
		var supplied_defaults = 0
		if method_info.has("default_args"):
			supplied_defaults = method_info["default_args"].size()
		var required = expected - supplied_defaults
		if call_args.size() > expected:
			call_args.resize(expected)
		while call_args.size() < required:
			call_args.append(_zero_value(method_info["args"][call_args.size()]["type"]))
	return _native.callv(method_name, call_args)


func _zero_value(argument_type):
	match argument_type:
		TYPE_BOOL:
			return false
		TYPE_INT:
			return 0
		TYPE_REAL:
			return 0.0
		TYPE_STRING:
			return ""
		TYPE_DICTIONARY:
			return {}
		TYPE_ARRAY:
			return []
		TYPE_RAW_ARRAY:
			return PoolByteArray()
		TYPE_INT_ARRAY:
			return PoolIntArray()
		TYPE_REAL_ARRAY:
			return PoolRealArray()
		TYPE_STRING_ARRAY:
			return PoolStringArray()
		TYPE_VECTOR2_ARRAY:
			return PoolVector2Array()
		TYPE_VECTOR3_ARRAY:
			return PoolVector3Array()
		TYPE_COLOR_ARRAY:
			return PoolColorArray()
		TYPE_VECTOR2:
			return Vector2()
		TYPE_VECTOR3:
			return Vector3()
		TYPE_COLOR:
			return Color()
	return null


func _relay0(signal_name) -> void:
	emit_signal(signal_name)


func _relay1(a, signal_name) -> void:
	emit_signal(signal_name, a)


func _relay2(a, b, signal_name) -> void:
	emit_signal(signal_name, a, b)


func _relay3(a, b, c, signal_name) -> void:
	emit_signal(signal_name, a, b, c)


func _relay4(a, b, c, d, signal_name) -> void:
	emit_signal(signal_name, a, b, c, d)


func _relay5(a, b, c, d, e, signal_name) -> void:
	emit_signal(signal_name, a, b, c, d, e)


func steamInit(retrieve_stats: bool = true, app_id: int = 0, embed_callbacks: bool = false) -> Dictionary:
	var result = _forward("steamInit", [retrieve_stats, app_id, embed_callbacks], null)
	if typeof(result) == TYPE_DICTIONARY:
		return result
	if typeof(result) == TYPE_BOOL:
		if result:
			return {"status": 1, "verbal": "Steamworks active."}
		return {"status": 0, "verbal": "Steamworks failed to initialize."}
	return {"status": 2, "verbal": "Dummy Steam"}


func activateGameOverlayToWebPage(url: String, _mode: int = 0):
	if _native == null:
		if url != "":
			OS.shell_open(url)
		return
	_forward("activateGameOverlayToWebPage", [url, _mode])


func activateGameOverlayToUser(type: String, steam_id: int):
	_forward("activateGameOverlayToUser", [type, steam_id])


func activateGameOverlayToStore(app_id: int):
	_forward("activateGameOverlayToStore", [app_id])


func getFriendPersonaName(steam_id: int):
	return _forward("getFriendPersonaName", [steam_id], "Player")


func getPlayerAvatar(size: int = 2, steam_id: int = 0):
	_forward("getPlayerAvatar", [size, steam_id])


func getLobbyData(lobby_id, key: String):
	return _forward("getLobbyData", [lobby_id, key], "")


func getLobbyOwner(lobby_id):
	return _forward("getLobbyOwner", [lobby_id], 0)


func getLobbyMemberLimit(lobby_id):
	return _forward("getLobbyMemberLimit", [lobby_id], 0)


func getNumLobbyMembers(lobby_id):
	return _forward("getNumLobbyMembers", [lobby_id], 0)


func getLobbyMemberByIndex(lobby_id, index: int):
	return _forward("getLobbyMemberByIndex", [lobby_id, index], 0)


func getLobbyMemberData(lobby_id, steam_id, key: String):
	return _forward("getLobbyMemberData", [lobby_id, steam_id, key], "")


func setLobbyMemberData(lobby_id, key: String, value: String):
	return _forward("setLobbyMemberData", [lobby_id, key, value], true)


func getAvailableP2PPacketSize(channel: int = 0):
	return _forward("getAvailableP2PPacketSize", [channel], 0)


func readP2PPacket(packet_size: int, channel: int = 0):
	return _forward("readP2PPacket", [packet_size, channel], {})


func getSubscribedItems():
	return _forward("getSubscribedItems", [], [])


func isSubscribed(_item_id: int = 0):
	return _forward("isSubscribed", [_item_id], false)


func getItemInstallInfo(item_id):
	return _forward("getItemInstallInfo", [item_id], {"ret": false, "size_on_disk": 0, "folder": "", "timestamp": 0})


func getItemState(item_id):
	return _forward("getItemState", [item_id], 0)


func getItemDownloadInfo(item_id):
	return _forward("getItemDownloadInfo", [item_id], {})


func downloadItem(item_id, high_priority: bool = true):
	return _forward("downloadItem", [item_id, high_priority], false)


func subscribeItem(item_id):
	_forward("subscribeItem", [item_id])


func unsubscribeItem(item_id):
	_forward("unsubscribeItem", [item_id])


func createItem(app_id: int, file_type: int):
	return _forward("createItem", [app_id, file_type], 0)


func startItemUpdate(app_id: int, item_id: int):
	return _forward("startItemUpdate", [app_id, item_id], 0)


func submitItemUpdate(update_handle: int, change_note: String = ""):
	_forward("submitItemUpdate", [update_handle, change_note])


func setItemTitle(update_handle: int, title: String):
	return _forward("setItemTitle", [update_handle, title], true)


func setItemDescription(update_handle: int, description: String):
	return _forward("setItemDescription", [update_handle, description], true)


func setItemUpdateLanguage(update_handle: int, language: String):
	return _forward("setItemUpdateLanguage", [update_handle, language], true)


func setItemVisibility(update_handle: int, visibility: int):
	return _forward("setItemVisibility", [update_handle, visibility], true)


func setItemTags(update_handle: int, tags: Array):
	return _forward("setItemTags", [update_handle, tags], true)


func setItemContent(update_handle: int, content_folder: String):
	return _forward("setItemContent", [update_handle, content_folder], true)


func setItemPreview(update_handle: int, preview_file: String):
	return _forward("setItemPreview", [update_handle, preview_file], true)


func setItemMetadata(update_handle: int, metadata: String):
	return _forward("setItemMetadata", [update_handle, metadata], true)


func createQueryUserUGCRequest(steam_id: int, list_type: int = 0, match_type: int = 0, sort_order: int = 0, creator_id: int = 0, consumer_id: int = 0, page: int = 1):
	return _forward("createQueryUserUGCRequest", [steam_id, list_type, match_type, sort_order, creator_id, consumer_id, page], 0)


func createQueryAllUGCRequest(query_type: int, matching_type: int, creator_id: int, consumer_id: int, page: int):
	return _forward("createQueryAllUGCRequest", [query_type, matching_type, creator_id, consumer_id, page], 0)


func setSearchText(query_handle: int, search_text: String):
	_forward("setSearchText", [query_handle, search_text])


func addRequiredTag(query_handle: int, tag_name: String):
	return _forward("addRequiredTag", [query_handle, tag_name], false)


func setMatchAnyTag(query_handle: int, match_any: bool):
	return _forward("setMatchAnyTag", [query_handle, match_any], false)


func setUserItemVote(item_id, vote_up: bool):
	return _forward("setUserItemVote", [item_id, vote_up], false)


func getUserItemVote(item_id):
	return _forward("getUserItemVote", [item_id], null)


func setReturnOnlyIDs(query_handle: int, return_only_ids: bool):
	_forward("setReturnOnlyIDs", [query_handle, return_only_ids])


func sendQueryUGCRequest(query_handle: int):
	return _forward("sendQueryUGCRequest", [query_handle], 0)


func getQueryUGCResult(query_handle: int, index: int):
	return _forward("getQueryUGCResult", [query_handle, index], {})


func getQueryUGCPreviewURL(query_handle: int, index: int):
	return _forward("getQueryUGCPreviewURL", [query_handle, index], "")


func releaseQueryUGCRequest(query_handle: int):
	return _forward("releaseQueryUGCRequest", [query_handle], true)


func getAppID():
	return _forward("getAppID", [], 0)


func getSteamID():
	return _forward("getSteamID", [], 0)


func getPersonaName():
	return _forward("getPersonaName", [], "Player")


func loggedOn():
	return _forward("loggedOn", [], false)


func userHasLicenseForApp(steam_id: int, app_id: int):
	return _forward("userHasLicenseForApp", [steam_id, app_id], RESULT_OK)


func requestCurrentStats() -> bool:
	return _forward("requestCurrentStats", [], true)


func run_callbacks():
	if _native != null:
		_native.run_callbacks()


func getStatInt(stat_name: String):
	return _forward("getStatInt", [stat_name], 0)


func setStatInt(stat_name: String, value: int):
	return _forward("setStatInt", [stat_name, value], true)


func storeStats():
	return _forward("storeStats", [], true)


func getNumAchievements():
	return _forward("getNumAchievements", [], 0)


func getAchievementName(index: int):
	return _forward("getAchievementName", [index], "")


func getAchievement(achievement_name: String):
	return _forward("getAchievement", [achievement_name], {"ret": false, "achieved": false})


func setAchievement(achievement_name: String):
	return _forward("setAchievement", [achievement_name], true)


func clearAchievement(achievement_name: String):
	return _forward("clearAchievement", [achievement_name], true)


func createLobby(lobby_type: int, max_members: int):
	_forward("createLobby", [lobby_type, max_members])


func joinLobby(lobby_id):
	_forward("joinLobby", [lobby_id])


func leaveLobby(lobby_id):
	_forward("leaveLobby", [lobby_id])


func setLobbyData(lobby_id, key: String, value: String):
	return _forward("setLobbyData", [lobby_id, key, value], true)


func setLobbyJoinable(lobby_id, joinable: bool):
	return _forward("setLobbyJoinable", [lobby_id, joinable], true)


func setLobbyOwner(lobby_id, new_owner_id):
	return _forward("setLobbyOwner", [lobby_id, new_owner_id], true)


func sendLobbyChatMsg(lobby_id, message: String):
	return _forward("sendLobbyChatMsg", [lobby_id, message], true)


func requestLobbyList():
	_forward("requestLobbyList", [])


func addRequestLobbyListDistanceFilter(distance_filter: int):
	_forward("addRequestLobbyListDistanceFilter", [distance_filter])


func addRequestLobbyListResultCountFilter(max_results: int):
	_forward("addRequestLobbyListResultCountFilter", [max_results])


func addRequestLobbyListStringFilter(key: String, value: String, comparison: int):
	_forward("addRequestLobbyListStringFilter", [key, value, comparison])


func sendP2PPacket(steam_id, data: PoolByteArray, send_type: int = 0, channel: int = 0):
	return _forward("sendP2PPacket", [steam_id, data, send_type, channel], true)


func acceptP2PSessionWithUser(steam_id):
	return _forward("acceptP2PSessionWithUser", [steam_id], true)


func closeP2PSessionWithUser(steam_id):
	return _forward("closeP2PSessionWithUser", [steam_id], true)


func allowP2PPacketRelay(allow: bool):
	return _forward("allowP2PPacketRelay", [allow], true)


func getAuthSessionTicket():
	return _forward("getAuthSessionTicket", [], {"id": 0, "buffer": PoolByteArray(), "size": 0})


func beginAuthSession(ticket_buffer, ticket_size: int, steam_id):
	return _forward("beginAuthSession", [ticket_buffer, ticket_size, steam_id], RESULT_OK)


func endAuthSession(steam_id):
	_forward("endAuthSession", [steam_id])


func cancelAuthTicket(ticket_id: int):
	_forward("cancelAuthTicket", [ticket_id])


func requestEncryptedAppTicket(secret: String):
	_forward("requestEncryptedAppTicket", [secret])


func getEncryptedAppTicket():
	return _forward("getEncryptedAppTicket", [], {})


func getAchievementDisplayAttribute(achievement_name: String, key: String):
	var result = _forward("getAchievementDisplayAttribute", [achievement_name, key], null)
	if result != null:
		return result
	if key == "name":
		return achievement_name
	elif key == "desc":
		return "Achievement description for " + achievement_name
	return ""


func setRichPresence(key: String, value: String):
	_forward("setRichPresence", [key, value])


func setRichPresenceStatus(status: String):
	_forward("setRichPresenceStatus", [status])


func clearRichPresence():
	_forward("clearRichPresence", [])


func acceptConnection(connection_handle) -> int:
	return _forward("acceptConnection", [connection_handle], 0)


func acceptGame() -> int:
	return _forward("acceptGame", [], 0)


func acceptSessionWithUser(identity_reference) -> bool:
	return _forward("acceptSessionWithUser", [identity_reference], false)


func activateActionSet(input_handle, action_set_handle):
	_forward("activateActionSet", [input_handle, action_set_handle])


func activateActionSetLayer(input_handle, action_set_layer_handle):
	_forward("activateActionSetLayer", [input_handle, action_set_layer_handle])


func activateGameOverlay(type = ""):
	_forward("activateGameOverlay", [type])


func activateGameOverlayInviteDialog(steam_id):
	_forward("activateGameOverlayInviteDialog", [steam_id])


func activateGameOverlayInviteDialogConnectString(connect_string):
	_forward("activateGameOverlayInviteDialogConnectString", [connect_string])


func activateGameOverlayRemotePlayTogetherInviteDialog(lobby_id):
	_forward("activateGameOverlayRemotePlayTogetherInviteDialog", [lobby_id])


func activationSuccess(activate) -> bool:
	return _forward("activationSuccess", [activate], false)


func addAppDependency(published_file_id, app_id):
	_forward("addAppDependency", [published_file_id, app_id])


func addContentDescriptor(update_handle, descriptor_id) -> bool:
	return _forward("addContentDescriptor", [update_handle, descriptor_id], false)


func addDependency(published_file_id, child_published_file_id):
	_forward("addDependency", [published_file_id, child_published_file_id])


func addExcludedTag(query_handle, tag_name) -> bool:
	return _forward("addExcludedTag", [query_handle, tag_name], false)


func addFavoriteGame(ip, port, query_port, flags, last_played) -> int:
	return _forward("addFavoriteGame", [ip, port, query_port, flags, last_played], 0)


func addGamePhaseTag(tag_name, tag_icon, tag_group, priority):
	_forward("addGamePhaseTag", [tag_name, tag_icon, tag_group, priority])


func addGameSearchParams(key, values) -> int:
	return _forward("addGameSearchParams", [key, values], 0)


func addHeader(key, value, this_handle = 0):
	_forward("addHeader", [key, value, this_handle])


func addIPAddress(reference_name) -> bool:
	return _forward("addIPAddress", [reference_name], false)


func addIdentity(reference_name) -> bool:
	return _forward("addIdentity", [reference_name], false)


func addInstantaneousTimelineEvent(title, description, icon, icon_priority, start_offset_seconds, possible_clip = 1) -> int:
	return _forward("addInstantaneousTimelineEvent", [title, description, icon, icon_priority, start_offset_seconds, possible_clip], 0)


func addItemKeyValueTag(query_handle, key, value) -> bool:
	return _forward("addItemKeyValueTag", [query_handle, key, value], false)


func addItemPreviewFile(query_handle, preview_file, type) -> bool:
	return _forward("addItemPreviewFile", [query_handle, preview_file, type], false)


func addItemPreviewVideo(query_handle, video_id) -> bool:
	return _forward("addItemPreviewVideo", [query_handle, video_id], false)


func addItemToFavorites(app_id, published_file_id):
	_forward("addItemToFavorites", [app_id, published_file_id])


func addPromoItem(item) -> bool:
	return _forward("addPromoItem", [item], false)


func addPromoItems(items) -> bool:
	return _forward("addPromoItems", [items], false)


func addRangeTimelineEvent(title, description, icon, icon_priority, start_offset_seconds, duration, possible_clip = 1) -> int:
	return _forward("addRangeTimelineEvent", [title, description, icon, icon_priority, start_offset_seconds, duration, possible_clip], 0)


func addRequestLobbyListFilterSlotsAvailable(slots_available):
	_forward("addRequestLobbyListFilterSlotsAvailable", [slots_available])


func addRequestLobbyListNearValueFilter(key_to_match, value_to_be_close_to):
	_forward("addRequestLobbyListNearValueFilter", [key_to_match, value_to_be_close_to])


func addRequestLobbyListNumericalFilter(key_to_match, value_to_match, comparison_type):
	_forward("addRequestLobbyListNumericalFilter", [key_to_match, value_to_match, comparison_type])


func addRequiredKeyValueTag(query_handle, key, value) -> bool:
	return _forward("addRequiredKeyValueTag", [query_handle, key, value], false)


func addRequiredTagGroup(query_handle, tag_array) -> bool:
	return _forward("addRequiredTagGroup", [query_handle, tag_array], false)


func addScreenshotToLibrary(filename, thumbnail_filename, width, height) -> int:
	return _forward("addScreenshotToLibrary", [filename, thumbnail_filename, width, height], 0)


func addVRScreenshotToLibrary(type, filename, vr_filename) -> int:
	return _forward("addVRScreenshotToLibrary", [type, filename, vr_filename], 0)


func advertiseGame(server_ip, port):
	_forward("advertiseGame", [server_ip, port])


func allowStartRequest(allowed, this_handle = 0):
	_forward("allowStartRequest", [allowed, this_handle])


func attachLeaderboardUGC(ugc_handle, this_leaderboard = 0):
	_forward("attachLeaderboardUGC", [ugc_handle, this_leaderboard])


func beginAsyncRequestFakeIP(num_ports) -> bool:
	return _forward("beginAsyncRequestFakeIP", [num_ports], false)


func beginFileWriteBatch() -> bool:
	return _forward("beginFileWriteBatch", [], false)


func cancelQuery(server_list_request):
	_forward("cancelQuery", [server_list_request])


func cancelRequestPlayersForGame() -> int:
	return _forward("cancelRequestPlayersForGame", [], 0)


func cancelReservation(beacon_id, steam_id):
	_forward("cancelReservation", [beacon_id, steam_id])


func cancelServerQuery(server_query):
	_forward("cancelServerQuery", [server_query])


func changeNumOpenSlots(beacon_id, open_slots):
	_forward("changeNumOpenSlots", [beacon_id, open_slots])


func checkFileSignature(arg0):
	_forward("checkFileSignature", [arg0])


func checkPingDataUpToDate(max_age_in_seconds) -> bool:
	return _forward("checkPingDataUpToDate", [max_age_in_seconds], false)


func checkResultSteamID(steam_id_expected, this_inventory_handle = 0) -> bool:
	return _forward("checkResultSteamID", [steam_id_expected, this_inventory_handle], false)


func clearIPAddress(reference_name):
	_forward("clearIPAddress", [reference_name])


func clearIdentity(reference_name):
	_forward("clearIdentity", [reference_name])


func clearTimelineTooltip(time_delta):
	_forward("clearTimelineTooltip", [time_delta])


func closeChannelWithUser(identity_reference, channel) -> bool:
	return _forward("closeChannelWithUser", [identity_reference, channel], false)


func closeClanChatWindowInSteam(chat_id) -> bool:
	return _forward("closeClanChatWindowInSteam", [chat_id], false)


func closeConnection(peer, reason, debug_message, linger) -> bool:
	return _forward("closeConnection", [peer, reason, debug_message, linger], false)


func closeListenSocket(socket) -> bool:
	return _forward("closeListenSocket", [socket], false)


func closeP2PChannelWithUser(steam_id_remote, channel) -> bool:
	return _forward("closeP2PChannelWithUser", [steam_id_remote, channel], false)


func closeSessionWithUser(identity_reference) -> bool:
	return _forward("closeSessionWithUser", [identity_reference], false)


func configureConnectionLanes(connection, lanes, priorities, weights) -> int:
	return _forward("configureConnectionLanes", [connection, lanes, priorities, weights], 0)


func connectByIPAddress(ip_address_with_port, options) -> int:
	return _forward("connectByIPAddress", [ip_address_with_port, options], 0)


func connectP2P(identity_reference, virtual_port, options) -> int:
	return _forward("connectP2P", [identity_reference, virtual_port, options], 0)


func connectToHostedDedicatedServer(identity_reference, virtual_port, options) -> int:
	return _forward("connectToHostedDedicatedServer", [identity_reference, virtual_port, options], 0)


func consumeItem(item_consume, quantity) -> bool:
	return _forward("consumeItem", [item_consume, quantity], false)


func convertPingLocationToString(location) -> String:
	return _forward("convertPingLocationToString", [location], "")


func copyToClipboard(this_handle):
	_forward("copyToClipboard", [this_handle])


func createBeacon(open_slots, location_id, type, connect_string, metadata):
	_forward("createBeacon", [open_slots, location_id, type, connect_string, metadata])


func createBrowser(user_agent, user_css):
	_forward("createBrowser", [user_agent, user_css])


func createCookieContainer(allow_response_to_modify) -> int:
	return _forward("createCookieContainer", [allow_response_to_modify], 0)


func createFakeUDPPort(fake_server_port):
	_forward("createFakeUDPPort", [fake_server_port])


func createHTTPRequest(request_method, absolute_url) -> int:
	return _forward("createHTTPRequest", [request_method, absolute_url], 0)


func createHostedDedicatedServerListenSocket(virtual_port, options) -> int:
	return _forward("createHostedDedicatedServerListenSocket", [virtual_port, options], 0)


func createListenSocketIP(ip_reference, options) -> int:
	return _forward("createListenSocketIP", [ip_reference, options], 0)


func createListenSocketP2P(virtual_port, options) -> int:
	return _forward("createListenSocketP2P", [virtual_port, options], 0)


func createListenSocketP2PFakeIP(fake_port, options) -> int:
	return _forward("createListenSocketP2PFakeIP", [fake_port, options], 0)


func createPollGroup() -> int:
	return _forward("createPollGroup", [], 0)


func createQueryAllUGCRequestCursor(query_type, matching_type, creator_id, consumer_id, cursor) -> int:
	return _forward("createQueryAllUGCRequestCursor", [query_type, matching_type, creator_id, consumer_id, cursor], 0)


func createQueryAllUGCRequestPage(query_type, matching_type, creator_id, consumer_id, page) -> int:
	return _forward("createQueryAllUGCRequestPage", [query_type, matching_type, creator_id, consumer_id, page], 0)


func createQueryUGCDetailsRequest(published_file_id) -> int:
	return _forward("createQueryUGCDetailsRequest", [published_file_id], 0)


func createSocketPair(loopback, identity_reference1, identity_reference2) -> Dictionary:
	return _forward("createSocketPair", [loopback, identity_reference1, identity_reference2], {})


func currentEntryDidChange() -> bool:
	return _forward("currentEntryDidChange", [], false)


func currentEntryIsAvailable(available) -> bool:
	return _forward("currentEntryIsAvailable", [available], false)


func currentEntryWillChange() -> bool:
	return _forward("currentEntryWillChange", [], false)


func deactivateActionSetLayer(input_handle, action_set_handle):
	_forward("deactivateActionSetLayer", [input_handle, action_set_handle])


func deactivateAllActionSetLayers(input_handle):
	_forward("deactivateAllActionSetLayers", [input_handle])


func declineGame() -> int:
	return _forward("declineGame", [], 0)


func decompressVoice(voice, voice_size, sample_rate) -> Dictionary:
	return _forward("decompressVoice", [voice, voice_size, sample_rate], {})


func deferHTTPRequest(request_handle) -> bool:
	return _forward("deferHTTPRequest", [request_handle], false)


func deleteItem(published_file_id):
	_forward("deleteItem", [published_file_id])


func deleteLobbyData(steam_lobby_id, key) -> bool:
	return _forward("deleteLobbyData", [steam_lobby_id, key], false)


func deregisterSteamMusicRemote() -> bool:
	return _forward("deregisterSteamMusicRemote", [], false)


func deserializeResult(buffer) -> int:
	return _forward("deserializeResult", [buffer], 0)


func destroyBeacon(beacon_id) -> bool:
	return _forward("destroyBeacon", [beacon_id], false)


func destroyPollGroup(poll_group) -> bool:
	return _forward("destroyPollGroup", [poll_group], false)


func destroyResult(this_inventory_handle = 0):
	_forward("destroyResult", [this_inventory_handle])


func disableRemotePlayTogetherDirectInput():
	_forward("disableRemotePlayTogetherDirectInput", [])


func dismissFloatingGamepadTextInput() -> bool:
	return _forward("dismissFloatingGamepadTextInput", [], false)


func dismissGamepadTextInput() -> bool:
	return _forward("dismissGamepadTextInput", [], false)


func doesEventRecordingExist(timeline_event_handle):
	_forward("doesEventRecordingExist", [timeline_event_handle])


func doesGamePhaseRecordingExist(phase_id):
	_forward("doesGamePhaseRecordingExist", [phase_id])


func downloadClanActivityCounts(chat_id, clans_to_request):
	_forward("downloadClanActivityCounts", [chat_id, clans_to_request])


func downloadLeaderboardEntries(start, end, type = 0, this_leaderboard = 0):
	_forward("downloadLeaderboardEntries", [start, end, type, this_leaderboard])


func downloadLeaderboardEntriesForUsers(users_id, this_leaderboard = 0):
	_forward("downloadLeaderboardEntriesForUsers", [users_id, this_leaderboard])


func enableActionEventCallbacks():
	_forward("enableActionEventCallbacks", [])


func enableDeviceCallbacks():
	_forward("enableDeviceCallbacks", [])


func enableLooped(loop) -> bool:
	return _forward("enableLooped", [loop], false)


func enablePlayNext(next) -> bool:
	return _forward("enablePlayNext", [next], false)


func enablePlayPrevious(previous) -> bool:
	return _forward("enablePlayPrevious", [previous], false)


func enablePlaylists(playlists) -> bool:
	return _forward("enablePlaylists", [playlists], false)


func enableQueue(queue) -> bool:
	return _forward("enableQueue", [queue], false)


func enableRemotePlayTogetherDirectInput() -> bool:
	return _forward("enableRemotePlayTogetherDirectInput", [], false)


func enableShuffled(shuffle) -> bool:
	return _forward("enableShuffled", [shuffle], false)


func endFileWriteBatch() -> bool:
	return _forward("endFileWriteBatch", [], false)


func endGame(game_id) -> int:
	return _forward("endGame", [game_id], 0)


func endGamePhase():
	_forward("endGamePhase", [])


func endGameSearch() -> int:
	return _forward("endGameSearch", [], 0)


func endRangeTimelineEvent(timeline_event_handle, end_offset_seconds):
	_forward("endRangeTimelineEvent", [timeline_event_handle, end_offset_seconds])


func enumerateFollowingList(start_index):
	_forward("enumerateFollowingList", [start_index])


func estimatePingTimeBetweenTwoLocations(location1, location2) -> int:
	return _forward("estimatePingTimeBetweenTwoLocations", [location1, location2], 0)


func estimatePingTimeFromLocalHost(location) -> int:
	return _forward("estimatePingTimeFromLocalHost", [location], 0)


func exchangeItems(output_items, output_quantity, input_items, input_quantity) -> bool:
	return _forward("exchangeItems", [output_items, output_quantity, input_items, input_quantity], false)


func executeJavascript(script, this_handle = 0):
	_forward("executeJavascript", [script, this_handle])


func fileDelete(file) -> bool:
	return _forward("fileDelete", [file], false)


func fileExists(file) -> bool:
	return _forward("fileExists", [file], false)


func fileForget(file) -> bool:
	return _forward("fileForget", [file], false)


func filePersisted(file) -> bool:
	return _forward("filePersisted", [file], false)


func fileRead(file, data_to_read) -> Dictionary:
	return _forward("fileRead", [file, data_to_read], {})


func fileReadAsync(file, offset, data_to_read):
	_forward("fileReadAsync", [file, offset, data_to_read])


func fileShare(file):
	_forward("fileShare", [file])


func fileWrite(file, data, size = 0) -> bool:
	return _forward("fileWrite", [file, data, size], false)


func fileWriteAsync(file, data, size = 0):
	_forward("fileWriteAsync", [file, data, size])


func fileWriteStreamCancel(write_handle) -> bool:
	return _forward("fileWriteStreamCancel", [write_handle], false)


func fileWriteStreamClose(write_handle) -> bool:
	return _forward("fileWriteStreamClose", [write_handle], false)


func fileWriteStreamOpen(file) -> int:
	return _forward("fileWriteStreamOpen", [file], 0)


func fileWriteStreamWriteChunk(write_handle, data) -> bool:
	return _forward("fileWriteStreamWriteChunk", [write_handle, data], false)


func filterText(context, steam_id, message) -> String:
	return _forward("filterText", [context, steam_id, message], "")


func find(search, currently_in_find, reverse, this_handle = 0):
	_forward("find", [search, currently_in_find, reverse, this_handle])


func findLeaderboard(leaderboard_name):
	_forward("findLeaderboard", [leaderboard_name])


func findOrCreateLeaderboard(leaderboard_name, sort_method, display_type):
	_forward("findOrCreateLeaderboard", [leaderboard_name, sort_method, display_type])


func flushMessagesOnConnection(connection_handle) -> int:
	return _forward("flushMessagesOnConnection", [connection_handle], 0)


func generateItems(items, quantity) -> bool:
	return _forward("generateItems", [items, quantity], false)


func getAPICallFailureReason() -> String:
	return _forward("getAPICallFailureReason", [], "")


func getAchievementAchievedPercent(achievement_name) -> Dictionary:
	return _forward("getAchievementAchievedPercent", [achievement_name], {})


func getAchievementAndUnlockTime(achievement_name) -> Dictionary:
	return _forward("getAchievementAndUnlockTime", [achievement_name], {})


func getAchievementIcon(achievement_name) -> int:
	return _forward("getAchievementIcon", [achievement_name], 0)


func getAchievementProgressLimitsFloat(achievement_name) -> Dictionary:
	return _forward("getAchievementProgressLimitsFloat", [achievement_name], {})


func getAchievementProgressLimitsInt(achievement_name) -> Dictionary:
	return _forward("getAchievementProgressLimitsInt", [achievement_name], {})


func getActionOriginFromXboxOrigin(input_handle, origin) -> int:
	return _forward("getActionOriginFromXboxOrigin", [input_handle, origin], 0)


func getActionSetHandle(action_set_name) -> int:
	return _forward("getActionSetHandle", [action_set_name], 0)


func getActiveActionSetLayers(input_handle) -> Array:
	return _forward("getActiveActionSetLayers", [input_handle], [])


func getAllItems() -> bool:
	return _forward("getAllItems", [], false)


func getAllLobbyData(steam_lobby_id) -> Dictionary:
	return _forward("getAllLobbyData", [steam_lobby_id], {})


func getAnalogActionData(input_handle, analog_action_handle) -> Dictionary:
	return _forward("getAnalogActionData", [input_handle, analog_action_handle], {})


func getAnalogActionHandle(action_name) -> int:
	return _forward("getAnalogActionHandle", [action_name], 0)


func getAnalogActionOrigins(input_handle, action_set_handle, analog_action_handle) -> Array:
	return _forward("getAnalogActionOrigins", [input_handle, action_set_handle, analog_action_handle], [])


func getAppBuildId() -> int:
	return _forward("getAppBuildId", [], 0)


func getAppDependencies(published_file_id):
	_forward("getAppDependencies", [published_file_id])


func getAppInstallDir(app_id) -> String:
	return _forward("getAppInstallDir", [app_id], "")


func getAppListBuildId(app_id, arg1) -> String:
	return _forward("getAppListBuildId", [app_id, arg1], "")


func getAppListInstallDir(app_id, name_max) -> String:
	return _forward("getAppListInstallDir", [app_id, name_max], "")


func getAppName(app_id, name_max) -> String:
	return _forward("getAppName", [app_id, name_max], "")


func getAppOwner() -> int:
	return _forward("getAppOwner", [], 0)


func getAuthTicketForWebApi(identity_reference = "") -> int:
	return _forward("getAuthTicketForWebApi", [identity_reference], 0)


func getAuthenticationStatus() -> int:
	return _forward("getAuthenticationStatus", [], 0)


func getAvailableBeaconLocations(max_) -> Array:
	return _forward("getAvailableBeaconLocations", [max_], [])


func getAvailableGameLanguages() -> String:
	return _forward("getAvailableGameLanguages", [], "")


func getAvailableVoice() -> Dictionary:
	return _forward("getAvailableVoice", [], {})


func getBeaconByIndex(index) -> int:
	return _forward("getBeaconByIndex", [index], 0)


func getBeaconDetails(beacon_id) -> Dictionary:
	return _forward("getBeaconDetails", [beacon_id], {})


func getBeaconLocationData(location_id, location_type, location_data) -> String:
	return _forward("getBeaconLocationData", [location_id, location_type, location_data], "")


func getBetaInfo() -> Dictionary:
	return _forward("getBetaInfo", [], {})


func getCachedUGCCount() -> int:
	return _forward("getCachedUGCCount", [], 0)


func getCachedUGCHandle(content) -> int:
	return _forward("getCachedUGCHandle", [content], 0)


func getCertificateRequest() -> Dictionary:
	return _forward("getCertificateRequest", [], {})


func getChatMemberByIndex(clan_id, user) -> int:
	return _forward("getChatMemberByIndex", [clan_id, user], 0)


func getClanActivityCounts(clan_id) -> Dictionary:
	return _forward("getClanActivityCounts", [clan_id], {})


func getClanByIndex(clan) -> int:
	return _forward("getClanByIndex", [clan], 0)


func getClanChatMemberCount(clan_id) -> int:
	return _forward("getClanChatMemberCount", [clan_id], 0)


func getClanChatMessage(chat_id, message) -> Dictionary:
	return _forward("getClanChatMessage", [chat_id, message], {})


func getClanCount() -> int:
	return _forward("getClanCount", [], 0)


func getClanName(clan_id) -> String:
	return _forward("getClanName", [clan_id], "")


func getClanOfficerByIndex(clan_id, officer) -> int:
	return _forward("getClanOfficerByIndex", [clan_id, officer], 0)


func getClanOfficerCount(clan_id) -> int:
	return _forward("getClanOfficerCount", [clan_id], 0)


func getClanOwner(clan_id) -> int:
	return _forward("getClanOwner", [clan_id], 0)


func getClanTag(clan_id) -> String:
	return _forward("getClanTag", [clan_id], "")


func getConfigValue(config_value, scope_type, connection_handle) -> Dictionary:
	return _forward("getConfigValue", [config_value, scope_type, connection_handle], {})


func getConfigValueInfo(config_value) -> Dictionary:
	return _forward("getConfigValueInfo", [config_value], {})


func getConnectedControllers() -> Array:
	return _forward("getConnectedControllers", [], [])


func getConnectedUniverse() -> int:
	return _forward("getConnectedUniverse", [], 0)


func getConnectionInfo(connection_handle) -> Dictionary:
	return _forward("getConnectionInfo", [connection_handle], {})


func getConnectionName(peer) -> String:
	return _forward("getConnectionName", [peer], "")


func getConnectionRealTimeStatus(connection_handle, lanes, get_status = true) -> Dictionary:
	return _forward("getConnectionRealTimeStatus", [connection_handle, lanes, get_status], {})


func getConnectionUserData(peer) -> int:
	return _forward("getConnectionUserData", [peer], 0)


func getControllerForGamepadIndex(index) -> int:
	return _forward("getControllerForGamepadIndex", [index], 0)


func getCoplayFriend(friend_number) -> int:
	return _forward("getCoplayFriend", [friend_number], 0)


func getCoplayFriendCount() -> int:
	return _forward("getCoplayFriendCount", [], 0)


func getCurrentActionSet(input_handle) -> int:
	return _forward("getCurrentActionSet", [input_handle], 0)


func getCurrentBatteryPower() -> int:
	return _forward("getCurrentBatteryPower", [], 0)


func getCurrentBetaName() -> String:
	return _forward("getCurrentBetaName", [], "")


func getCurrentGameLanguage() -> String:
	return _forward("getCurrentGameLanguage", [], "")


func getDLCCount() -> int:
	return _forward("getDLCCount", [], 0)


func getDLCData() -> Array:
	return _forward("getDLCData", [], [])


func getDLCDataByIndex() -> Array:
	return _forward("getDLCDataByIndex", [], [])


func getDLCDownloadProgress(dlc_id) -> Dictionary:
	return _forward("getDLCDownloadProgress", [dlc_id], {})


func getDecompressedVoice(buffer_in_size_override = 0, buffer_out_size_override = 20480, sample_rate_override = 0) -> Dictionary:
	return _forward("getDecompressedVoice", [buffer_in_size_override, buffer_out_size_override, sample_rate_override], {})


func getDetailedConnectionStatus(connection_handle) -> Dictionary:
	return _forward("getDetailedConnectionStatus", [connection_handle], {})


func getDeviceBindingRevision(input_handle) -> Array:
	return _forward("getDeviceBindingRevision", [input_handle], [])


func getDigitalActionData(input_handle, digital_action_handle) -> Dictionary:
	return _forward("getDigitalActionData", [input_handle, digital_action_handle], {})


func getDigitalActionHandle(action_name) -> int:
	return _forward("getDigitalActionHandle", [action_name], 0)


func getDigitalActionOrigins(input_handle, action_set_handle, digital_action_handle) -> Array:
	return _forward("getDigitalActionOrigins", [input_handle, action_set_handle, digital_action_handle], [])


func getDirectPingToPOP(pop_id) -> int:
	return _forward("getDirectPingToPOP", [pop_id], 0)


func getDurationControl():
	_forward("getDurationControl", [])


func getEarliestPurchaseUnixTime(app_id) -> int:
	return _forward("getEarliestPurchaseUnixTime", [app_id], 0)


func getFakeIP(first_port = 0) -> Dictionary:
	return _forward("getFakeIP", [first_port], {})


func getFavoriteGames() -> Array:
	return _forward("getFavoriteGames", [], [])


func getFileCount() -> int:
	return _forward("getFileCount", [], 0)


func getFileDetails(filename):
	_forward("getFileDetails", [filename])


func getFileNameAndSize(file) -> Dictionary:
	return _forward("getFileNameAndSize", [file], {})


func getFileSize(file) -> int:
	return _forward("getFileSize", [file], 0)


func getFileTimestamp(file) -> int:
	return _forward("getFileTimestamp", [file], 0)


func getFollowerCount(steam_id):
	_forward("getFollowerCount", [steam_id])


func getFriendByIndex(friend_number, friend_flags) -> int:
	return _forward("getFriendByIndex", [friend_number, friend_flags], 0)


func getFriendCoplayGame(friend_id) -> int:
	return _forward("getFriendCoplayGame", [friend_id], 0)


func getFriendCoplayTime(friend_id) -> int:
	return _forward("getFriendCoplayTime", [friend_id], 0)


func getFriendCount(arg0 = 4) -> int:
	return _forward("getFriendCount", [arg0], 0)


func getFriendCountFromSource(source_id) -> int:
	return _forward("getFriendCountFromSource", [source_id], 0)


func getFriendFromSourceByIndex(source_id, friend_number) -> int:
	return _forward("getFriendFromSourceByIndex", [source_id, friend_number], 0)


func getFriendGamePlayed(steam_id) -> Dictionary:
	return _forward("getFriendGamePlayed", [steam_id], {})


func getFriendMessage(friend_id, message) -> Dictionary:
	return _forward("getFriendMessage", [friend_id, message], {})


func getFriendPersonaNameHistory(steam_id, name_history) -> String:
	return _forward("getFriendPersonaNameHistory", [steam_id, name_history], "")


func getFriendPersonaState(steam_id) -> int:
	return _forward("getFriendPersonaState", [steam_id], 0)


func getFriendRelationship(steam_id) -> int:
	return _forward("getFriendRelationship", [steam_id], 0)


func getFriendRichPresence(friend_id, key) -> String:
	return _forward("getFriendRichPresence", [friend_id, key], "")


func getFriendRichPresenceKeyByIndex(friend_id, key) -> String:
	return _forward("getFriendRichPresenceKeyByIndex", [friend_id, key], "")


func getFriendRichPresenceKeyCount(friend_id) -> int:
	return _forward("getFriendRichPresenceKeyCount", [friend_id], 0)


func getFriendSteamLevel(steam_id) -> int:
	return _forward("getFriendSteamLevel", [steam_id], 0)


func getFriendsGroupCount() -> int:
	return _forward("getFriendsGroupCount", [], 0)


func getFriendsGroupIDByIndex(friend_group) -> int:
	return _forward("getFriendsGroupIDByIndex", [friend_group], 0)


func getFriendsGroupMembersCount(friend_group) -> int:
	return _forward("getFriendsGroupMembersCount", [friend_group], 0)


func getFriendsGroupMembersList(friend_group, member_count) -> Array:
	return _forward("getFriendsGroupMembersList", [friend_group, member_count], [])


func getFriendsGroupName(friend_group) -> String:
	return _forward("getFriendsGroupName", [friend_group], "")


func getGameBadgeLevel(series, foil) -> int:
	return _forward("getGameBadgeLevel", [series, foil], 0)


func getGamepadIndexForController(input_handle) -> int:
	return _forward("getGamepadIndexForController", [input_handle], 0)


func getGenericBytes(reference_name) -> int:
	return _forward("getGenericBytes", [reference_name], 0)


func getGenericString(reference_name) -> String:
	return _forward("getGenericString", [reference_name], "")


func getGlobalStatFloat(stat_name) -> float:
	return _forward("getGlobalStatFloat", [stat_name], 0.0)


func getGlobalStatFloatHistory(stat_name) -> float:
	return _forward("getGlobalStatFloatHistory", [stat_name], 0.0)


func getGlobalStatInt(stat_name) -> int:
	return _forward("getGlobalStatInt", [stat_name], 0)


func getGlobalStatIntHistory(stat_name) -> int:
	return _forward("getGlobalStatIntHistory", [stat_name], 0)


func getGlyphForActionOrigin(origin) -> String:
	return _forward("getGlyphForActionOrigin", [origin], "")


func getGlyphForXboxOrigin(origin) -> String:
	return _forward("getGlyphForXboxOrigin", [origin], "")


func getGlyphPNGForActionOrigin(origin, size, flags) -> String:
	return _forward("getGlyphPNGForActionOrigin", [origin, size, flags], "")


func getGlyphSVGForActionOrigin(origin, flags) -> String:
	return _forward("getGlyphSVGForActionOrigin", [origin, flags], "")


func getHTTPDownloadProgressPct(request_handle) -> float:
	return _forward("getHTTPDownloadProgressPct", [request_handle], 0.0)


func getHTTPRequestWasTimedOut(request_handle) -> bool:
	return _forward("getHTTPRequestWasTimedOut", [request_handle], false)


func getHTTPResponseBodyData(request_handle, buffer_size) -> PoolByteArray:
	return _forward("getHTTPResponseBodyData", [request_handle, buffer_size], PoolByteArray())


func getHTTPResponseBodySize(request_handle) -> int:
	return _forward("getHTTPResponseBodySize", [request_handle], 0)


func getHTTPResponseHeaderSize(request_handle, header_name) -> int:
	return _forward("getHTTPResponseHeaderSize", [request_handle, header_name], 0)


func getHTTPResponseHeaderValue(request_handle, header_name, buffer_size) -> int:
	return _forward("getHTTPResponseHeaderValue", [request_handle, header_name, buffer_size], 0)


func getHTTPStreamingResponseBodyData(request_handle, offset, buffer_size) -> int:
	return _forward("getHTTPStreamingResponseBodyData", [request_handle, offset, buffer_size], 0)


func getHostedDedicatedServerPOPId() -> int:
	return _forward("getHostedDedicatedServerPOPId", [], 0)


func getHostedDedicatedServerPort() -> int:
	return _forward("getHostedDedicatedServerPort", [], 0)


func getIPAddresses() -> Array:
	return _forward("getIPAddresses", [], [])


func getIPCCallCount() -> int:
	return _forward("getIPCCallCount", [], 0)


func getIPCountry() -> String:
	return _forward("getIPCountry", [], "")


func getIPv4(reference_name) -> int:
	return _forward("getIPv4", [reference_name], 0)


func getIPv4FakeIPType(ipv4) -> int:
	return _forward("getIPv4FakeIPType", [ipv4], 0)


func getIPv6ConnectivityState(protocol) -> int:
	return _forward("getIPv6ConnectivityState", [protocol], 0)


func getIdentities() -> Array:
	return _forward("getIdentities", [], [])


func getIdentity() -> String:
	return _forward("getIdentity", [], "")


func getIdentityIPAddr(reference_name) -> int:
	return _forward("getIdentityIPAddr", [reference_name], 0)


func getIdentitySteamID(reference_name) -> int:
	return _forward("getIdentitySteamID", [reference_name], 0)


func getIdentitySteamID64(reference_name) -> int:
	return _forward("getIdentitySteamID64", [reference_name], 0)


func getImageRGBA(image) -> Dictionary:
	return _forward("getImageRGBA", [image], {})


func getImageSize(image) -> Dictionary:
	return _forward("getImageSize", [image], {})


func getInput(max_events) -> Array:
	return _forward("getInput", [max_events], [])


func getInputTypeForHandle(input_handle) -> String:
	return _forward("getInputTypeForHandle", [input_handle], "")


func getInstalledApps(max_app_ids) -> Array:
	return _forward("getInstalledApps", [max_app_ids], [])


func getInstalledDepots(app_id) -> Array:
	return _forward("getInstalledDepots", [app_id], [])


func getItemDefinitionProperty(definition, name) -> String:
	return _forward("getItemDefinitionProperty", [definition, name], "")


func getItemPrice(definition) -> int:
	return _forward("getItemPrice", [definition], 0)


func getItemUpdateProgress(update_handle) -> Dictionary:
	return _forward("getItemUpdateProgress", [update_handle], {})


func getItemsByID(id_array, count) -> bool:
	return _forward("getItemsByID", [id_array, count], false)


func getItemsWithPrices(length) -> Array:
	return _forward("getItemsWithPrices", [length], [])


func getLargeFriendAvatar(steam_id) -> int:
	return _forward("getLargeFriendAvatar", [steam_id], 0)


func getLaunchCommandLine() -> String:
	return _forward("getLaunchCommandLine", [], "")


func getLaunchQueryParam(key) -> String:
	return _forward("getLaunchQueryParam", [key], "")


func getLeaderboardDisplayType(this_leaderboard = 0) -> Dictionary:
	return _forward("getLeaderboardDisplayType", [this_leaderboard], {})


func getLeaderboardEntries() -> Array:
	return _forward("getLeaderboardEntries", [], [])


func getLeaderboardEntryCount(this_leaderboard = 0) -> int:
	return _forward("getLeaderboardEntryCount", [this_leaderboard], 0)


func getLeaderboardName(this_leaderboard = 0) -> String:
	return _forward("getLeaderboardName", [this_leaderboard], "")


func getLeaderboardSortMethod(this_leaderboard = 0) -> Dictionary:
	return _forward("getLeaderboardSortMethod", [this_leaderboard], {})


func getLinkAtPosition(x, y, this_handle = 0):
	_forward("getLinkAtPosition", [x, y, this_handle])


func getListenSocketAddress(socket) -> bool:
	return _forward("getListenSocketAddress", [socket], false)


func getLobbyGameServer(steam_lobby_id) -> Dictionary:
	return _forward("getLobbyGameServer", [steam_lobby_id], {})


func getLocalFileChange(file) -> Dictionary:
	return _forward("getLocalFileChange", [file], {})


func getLocalFileChangeCount() -> int:
	return _forward("getLocalFileChangeCount", [], 0)


func getLocalPingLocation() -> Dictionary:
	return _forward("getLocalPingLocation", [], {})


func getLocalTimestamp() -> int:
	return _forward("getLocalTimestamp", [], 0)


func getMediumFriendAvatar(steam_id) -> int:
	return _forward("getMediumFriendAvatar", [steam_id], 0)


func getMostAchievedAchievementInfo() -> Dictionary:
	return _forward("getMostAchievedAchievementInfo", [], {})


func getMotionData(input_handle) -> Dictionary:
	return _forward("getMotionData", [input_handle], {})


func getNextMostAchievedAchievementInfo(iterator) -> Dictionary:
	return _forward("getNextMostAchievedAchievementInfo", [iterator], {})


func getNumActiveBeacons() -> int:
	return _forward("getNumActiveBeacons", [], 0)


func getNumAvailableBeaconLocations() -> int:
	return _forward("getNumAvailableBeaconLocations", [], 0)


func getNumBetas() -> Dictionary:
	return _forward("getNumBetas", [], {})


func getNumInstalledApps() -> int:
	return _forward("getNumInstalledApps", [], 0)


func getNumItemsWithPrices() -> int:
	return _forward("getNumItemsWithPrices", [], 0)


func getNumSubscribedItems() -> int:
	return _forward("getNumSubscribedItems", [], 0)


func getNumSupportedGameVersions(query_handle, index) -> int:
	return _forward("getNumSupportedGameVersions", [query_handle, index], 0)


func getNumberOfCurrentPlayers():
	_forward("getNumberOfCurrentPlayers", [])


func getOPFSettings(app_id):
	_forward("getOPFSettings", [app_id])


func getOPFStringForApp(app_id) -> String:
	return _forward("getOPFStringForApp", [app_id], "")


func getP2PSessionState(steam_id_remote) -> Dictionary:
	return _forward("getP2PSessionState", [steam_id_remote], {})


func getPOPCount() -> int:
	return _forward("getPOPCount", [], 0)


func getPOPList() -> Array:
	return _forward("getPOPList", [], [])


func getPSNID(reference_name) -> int:
	return _forward("getPSNID", [reference_name], 0)


func getPersonaState() -> int:
	return _forward("getPersonaState", [], 0)


func getPingToDataCenter(pop_id) -> Dictionary:
	return _forward("getPingToDataCenter", [pop_id], {})


func getPlaybackStatus() -> int:
	return _forward("getPlaybackStatus", [], 0)


func getPlayerNickname(steam_id) -> String:
	return _forward("getPlayerNickname", [steam_id], "")


func getPlayerSteamLevel() -> int:
	return _forward("getPlayerSteamLevel", [], 0)


func getProfileItemPropertyInt(steam_id, item_type, item_propery) -> int:
	return _forward("getProfileItemPropertyInt", [steam_id, item_type, item_propery], 0)


func getProfileItemPropertyString(steam_id, item_type, item_property) -> String:
	return _forward("getProfileItemPropertyString", [steam_id, item_type, item_property], "")


func getQueryUGCAdditionalPreview(query_handle, index, preview_index) -> Dictionary:
	return _forward("getQueryUGCAdditionalPreview", [query_handle, index, preview_index], {})


func getQueryUGCChildren(query_handle, index, child_count) -> Dictionary:
	return _forward("getQueryUGCChildren", [query_handle, index, child_count], {})


func getQueryUGCContentDescriptors(query_handle, index, max_entries) -> Dictionary:
	return _forward("getQueryUGCContentDescriptors", [query_handle, index, max_entries], {})


func getQueryUGCKeyValueTag(query_handle, index, key_value_tag_index) -> Dictionary:
	return _forward("getQueryUGCKeyValueTag", [query_handle, index, key_value_tag_index], {})


func getQueryUGCMetadata(query_handle, index) -> String:
	return _forward("getQueryUGCMetadata", [query_handle, index], "")


func getQueryUGCNumAdditionalPreviews(query_handle, index) -> int:
	return _forward("getQueryUGCNumAdditionalPreviews", [query_handle, index], 0)


func getQueryUGCNumKeyValueTags(query_handle, index) -> int:
	return _forward("getQueryUGCNumKeyValueTags", [query_handle, index], 0)


func getQueryUGCNumTags(query_handle, index) -> int:
	return _forward("getQueryUGCNumTags", [query_handle, index], 0)


func getQueryUGCStatistic(query_handle, index, stat_type) -> Dictionary:
	return _forward("getQueryUGCStatistic", [query_handle, index, stat_type], {})


func getQueryUGCTag(query_handle, index, tag_index) -> String:
	return _forward("getQueryUGCTag", [query_handle, index, tag_index], "")


func getQueryUGCTagDisplayName(query_handle, index, tag_index) -> String:
	return _forward("getQueryUGCTagDisplayName", [query_handle, index, tag_index], "")


func getQuota() -> Dictionary:
	return _forward("getQuota", [], {})


func getRealIdentityForFakeIP(fake_ip) -> Dictionary:
	return _forward("getRealIdentityForFakeIP", [fake_ip], {})


func getRecentPlayers() -> Array:
	return _forward("getRecentPlayers", [], [])


func getRelayNetworkStatus() -> int:
	return _forward("getRelayNetworkStatus", [], 0)


func getRemoteFakeIPForConnection(connection) -> Dictionary:
	return _forward("getRemoteFakeIPForConnection", [connection], {})


func getRemotePlaySessionID(input_handle) -> int:
	return _forward("getRemotePlaySessionID", [input_handle], 0)


func getResultItemProperty(index, name, this_inventory_handle = 0) -> String:
	return _forward("getResultItemProperty", [index, name, this_inventory_handle], "")


func getResultItems(this_inventory_handle = 0) -> Array:
	return _forward("getResultItems", [this_inventory_handle], [])


func getResultStatus(this_inventory_handle = 0) -> String:
	return _forward("getResultStatus", [this_inventory_handle], "")


func getResultTimestamp(this_inventory_handle = 0) -> int:
	return _forward("getResultTimestamp", [this_inventory_handle], 0)


func getSecondsSinceAppActive() -> int:
	return _forward("getSecondsSinceAppActive", [], 0)


func getSecondsSinceComputerActive() -> int:
	return _forward("getSecondsSinceComputerActive", [], 0)


func getServerCount(server_list_request) -> int:
	return _forward("getServerCount", [server_list_request], 0)


func getServerDetails(server, server_list_request) -> Dictionary:
	return _forward("getServerDetails", [server, server_list_request], {})


func getServerRealTime() -> int:
	return _forward("getServerRealTime", [], 0)


func getSessionClientFormFactor(session_id) -> int:
	return _forward("getSessionClientFormFactor", [session_id], 0)


func getSessionClientName(session_id) -> String:
	return _forward("getSessionClientName", [session_id], "")


func getSessionClientResolution(session_id) -> Dictionary:
	return _forward("getSessionClientResolution", [session_id], {})


func getSessionConnectionInfo(identity_reference, get_connection, get_status) -> Dictionary:
	return _forward("getSessionConnectionInfo", [identity_reference, get_connection, get_status], {})


func getSessionCount() -> int:
	return _forward("getSessionCount", [], 0)


func getSessionID(index) -> int:
	return _forward("getSessionID", [index], 0)


func getSessionInputConfigurationSettings() -> int:
	return _forward("getSessionInputConfigurationSettings", [], 0)


func getSessionSteamID(session_id) -> int:
	return _forward("getSessionSteamID", [session_id], 0)


func getSmallFriendAvatar(steam_id) -> int:
	return _forward("getSmallFriendAvatar", [steam_id], 0)


func getStadiaID(reference_name) -> int:
	return _forward("getStadiaID", [reference_name], 0)


func getStatFloat(stat_name) -> float:
	return _forward("getStatFloat", [stat_name], 0.0)


func getSteamID32(steam_id) -> int:
	return _forward("getSteamID32", [steam_id], 0)


func getSteamUILanguage() -> String:
	return _forward("getSteamUILanguage", [], "")


func getStringForActionOrigin(origin) -> String:
	return _forward("getStringForActionOrigin", [origin], "")


func getStringForAnalogActionName(action_handle) -> String:
	return _forward("getStringForAnalogActionName", [action_handle], "")


func getStringForDigitalActionName(action_handle) -> String:
	return _forward("getStringForDigitalActionName", [action_handle], "")


func getStringForXboxOrigin(origin) -> String:
	return _forward("getStringForXboxOrigin", [origin], "")


func getSupportedGameVersionData(query_handle, index, version_index) -> Dictionary:
	return _forward("getSupportedGameVersionData", [query_handle, index, version_index], {})


func getSyncPlatforms(file) -> Dictionary:
	return _forward("getSyncPlatforms", [file], {})


func getUGCDetails(content) -> Dictionary:
	return _forward("getUGCDetails", [content], {})


func getUGCDownloadProgress(content) -> Dictionary:
	return _forward("getUGCDownloadProgress", [content], {})


func getUserAchievement(steam_id, name) -> Dictionary:
	return _forward("getUserAchievement", [steam_id, name], {})


func getUserAchievementAndUnlockTime(steam_id, name) -> Dictionary:
	return _forward("getUserAchievementAndUnlockTime", [steam_id, name], {})


func getUserContentDescriptorPreferences(max_entries) -> Array:
	return _forward("getUserContentDescriptorPreferences", [max_entries], [])


func getUserFriendsGroups() -> Array:
	return _forward("getUserFriendsGroups", [], [])


func getUserRestrictions() -> int:
	return _forward("getUserRestrictions", [], 0)


func getUserStatFloat(steam_id, name) -> float:
	return _forward("getUserStatFloat", [steam_id, name], 0.0)


func getUserStatInt(steam_id, name) -> int:
	return _forward("getUserStatInt", [steam_id, name], 0)


func getUserSteamFriends() -> Array:
	return _forward("getUserSteamFriends", [], [])


func getUserSteamGroups() -> Array:
	return _forward("getUserSteamGroups", [], [])


func getVideoURL(app_id):
	_forward("getVideoURL", [app_id])


func getVoice() -> Dictionary:
	return _forward("getVoice", [], {})


func getVoiceOptimalSampleRate() -> int:
	return _forward("getVoiceOptimalSampleRate", [], 0)


func getWorkshopEULAStatus():
	_forward("getWorkshopEULAStatus", [])


func getXboxPairwiseID(reference_name) -> String:
	return _forward("getXboxPairwiseID", [reference_name], "")


func get_godotsteam_version() -> String:
	return _forward("get_godotsteam_version", [], "")


func get_server_list_request() -> int:
	return _forward("get_server_list_request", [], 0)


func get_steam_init_result() -> Dictionary:
	return _forward("get_steam_init_result", [], {})


func goBack(this_handle = 0):
	_forward("goBack", [this_handle])


func goForward(this_handle = 0):
	_forward("goForward", [this_handle])


func grantPromoItems() -> int:
	return _forward("grantPromoItems", [], 0)


func hasEquippedProfileItem(steam_id, friend_flags) -> bool:
	return _forward("hasEquippedProfileItem", [steam_id, friend_flags], false)


func hasFriend(steam_id, friend_flags) -> bool:
	return _forward("hasFriend", [steam_id, friend_flags], false)


func hookScreenshots(hook):
	_forward("hookScreenshots", [hook])


func hostConfirmGameStart(game_id) -> int:
	return _forward("hostConfirmGameStart", [game_id], 0)


func htmlInit():
	_forward("htmlInit", [])


func htmlShutdown() -> bool:
	return _forward("htmlShutdown", [], false)


func indicateAchievementProgress(name, current_progress, max_progress) -> bool:
	return _forward("indicateAchievementProgress", [name, current_progress, max_progress], false)


func initAuthentication() -> int:
	return _forward("initAuthentication", [], 0)


func initFilterText() -> bool:
	return _forward("initFilterText", [], false)


func initRelayNetworkAccess():
	_forward("initRelayNetworkAccess", [])


func initWorkshopForGameServer(workshop_depot_id) -> bool:
	return _forward("initWorkshopForGameServer", [workshop_depot_id], false)


func initiateGameConnection(server_id, server_ip, server_port, secure) -> Dictionary:
	return _forward("initiateGameConnection", [server_id, server_ip, server_port, secure], {})


func inputInit(explicitly_call_runframe = false) -> bool:
	return _forward("inputInit", [explicitly_call_runframe], false)


func inputShutdown() -> bool:
	return _forward("inputShutdown", [], false)


func installDLC(dlc_id):
	_forward("installDLC", [dlc_id])


func inviteUserToGame(friend_id, connect_string) -> bool:
	return _forward("inviteUserToGame", [friend_id, connect_string], false)


func inviteUserToLobby(steam_lobby_id, steam_id_invitee) -> bool:
	return _forward("inviteUserToLobby", [steam_lobby_id, steam_id_invitee], false)


func isAPICallCompleted() -> Dictionary:
	return _forward("isAPICallCompleted", [], {})


func isAddressLocalHost(reference_name) -> bool:
	return _forward("isAddressLocalHost", [reference_name], false)


func isAnonAccount(steam_id) -> bool:
	return _forward("isAnonAccount", [steam_id], false)


func isAnonUserAccount(steam_id) -> bool:
	return _forward("isAnonUserAccount", [steam_id], false)


func isAppBlocked(app_id) -> bool:
	return _forward("isAppBlocked", [app_id], false)


func isAppInBlockList(app_id) -> bool:
	return _forward("isAppInBlockList", [app_id], false)


func isAppInstalled(app_id) -> bool:
	return _forward("isAppInstalled", [app_id], false)


func isBehindNAT() -> bool:
	return _forward("isBehindNAT", [], false)


func isBroadcasting() -> Dictionary:
	return _forward("isBroadcasting", [], {})


func isChatAccount(steam_id) -> bool:
	return _forward("isChatAccount", [steam_id], false)


func isClanAccount(steam_id) -> bool:
	return _forward("isClanAccount", [steam_id], false)


func isClanChatAdmin(chat_id, steam_id) -> bool:
	return _forward("isClanChatAdmin", [chat_id, steam_id], false)


func isClanChatWindowOpenInSteam(chat_id) -> bool:
	return _forward("isClanChatWindowOpenInSteam", [chat_id], false)


func isClanOfficialGameGroup(clan_id) -> bool:
	return _forward("isClanOfficialGameGroup", [clan_id], false)


func isClanPublic(clan_id) -> bool:
	return _forward("isClanPublic", [clan_id], false)


func isCloudEnabledForAccount() -> bool:
	return _forward("isCloudEnabledForAccount", [], false)


func isCloudEnabledForApp() -> bool:
	return _forward("isCloudEnabledForApp", [], false)


func isConsoleUserAccount(steam_id) -> bool:
	return _forward("isConsoleUserAccount", [steam_id], false)


func isCurrentMusicRemote() -> bool:
	return _forward("isCurrentMusicRemote", [], false)


func isCybercafe() -> bool:
	return _forward("isCybercafe", [], false)


func isDLCInstalled(dlc_id) -> bool:
	return _forward("isDLCInstalled", [dlc_id], false)


func isFakeIPv4(ip_address) -> bool:
	return _forward("isFakeIPv4", [ip_address], false)


func isFeatureBlocked(feature) -> bool:
	return _forward("isFeatureBlocked", [feature], false)


func isFeatureInBlockList(feature) -> bool:
	return _forward("isFeatureInBlockList", [feature], false)


func isFollowing(steam_id):
	_forward("isFollowing", [steam_id])


func isIPv4(reference_name) -> bool:
	return _forward("isIPv4", [reference_name], false)


func isIPv6AllZeros(reference_name) -> bool:
	return _forward("isIPv6AllZeros", [reference_name], false)


func isIdentityInvalid(reference_name) -> bool:
	return _forward("isIdentityInvalid", [reference_name], false)


func isIdentityLocalHost(reference_name) -> bool:
	return _forward("isIdentityLocalHost", [reference_name], false)


func isIndividualAccount(steam_id) -> bool:
	return _forward("isIndividualAccount", [steam_id], false)


func isLobby(steam_id) -> bool:
	return _forward("isLobby", [steam_id], false)


func isLowViolence() -> bool:
	return _forward("isLowViolence", [], false)


func isOverlayEnabled() -> bool:
	return _forward("isOverlayEnabled", [], false)


func isParentalLockEnabled() -> bool:
	return _forward("isParentalLockEnabled", [], false)


func isParentalLockLocked() -> bool:
	return _forward("isParentalLockLocked", [], false)


func isPhoneIdentifying() -> bool:
	return _forward("isPhoneIdentifying", [], false)


func isPhoneRequiringVerification() -> bool:
	return _forward("isPhoneRequiringVerification", [], false)


func isPhoneVerified() -> bool:
	return _forward("isPhoneVerified", [], false)


func isRefreshing(server_list_request) -> bool:
	return _forward("isRefreshing", [server_list_request], false)


func isScreenshotsHooked() -> bool:
	return _forward("isScreenshotsHooked", [], false)


func isSteamChinaLauncher() -> bool:
	return _forward("isSteamChinaLauncher", [], false)


func isSteamInBigPictureMode() -> bool:
	return _forward("isSteamInBigPictureMode", [], false)


func isSteamRunning() -> bool:
	return _forward("isSteamRunning", [], false)


func isSteamRunningInVR() -> bool:
	return _forward("isSteamRunningInVR", [], false)


func isSteamRunningOnSteamDeck() -> bool:
	return _forward("isSteamRunningOnSteamDeck", [], false)


func isSubscribedApp(app_id) -> bool:
	return _forward("isSubscribedApp", [app_id], false)


func isSubscribedFromFamilySharing() -> bool:
	return _forward("isSubscribedFromFamilySharing", [], false)


func isSubscribedFromFreeWeekend() -> bool:
	return _forward("isSubscribedFromFreeWeekend", [], false)


func isTimedTrial() -> Dictionary:
	return _forward("isTimedTrial", [], {})


func isTwoFactorEnabled() -> bool:
	return _forward("isTwoFactorEnabled", [], false)


func isUserInSource(steam_id, source_id) -> bool:
	return _forward("isUserInSource", [steam_id, source_id], false)


func isVACBanned() -> bool:
	return _forward("isVACBanned", [], false)


func isVRHeadsetStreamingEnabled() -> bool:
	return _forward("isVRHeadsetStreamingEnabled", [], false)


func iterateGenericEditableConfigValues(current_value, enumerate_dev_vars) -> int:
	return _forward("iterateGenericEditableConfigValues", [current_value, enumerate_dev_vars], 0)


func joinClanChatRoom(clan_id):
	_forward("joinClanChatRoom", [clan_id])


func joinParty(beacon_id):
	_forward("joinParty", [beacon_id])


func jsDialogResponse(result, this_handle = 0):
	_forward("jsDialogResponse", [result, this_handle])


func keyChar(unicode_char, key_modifiers, this_handle = 0):
	_forward("keyChar", [unicode_char, key_modifiers, this_handle])


func keyDown(native_key_code, key_modifiers, this_handle = 0):
	_forward("keyDown", [native_key_code, key_modifiers, this_handle])


func keyUp(native_key_code, key_modifiers, this_handle = 0):
	_forward("keyUp", [native_key_code, key_modifiers, this_handle])


func leaveClanChatRoom(clan_id) -> bool:
	return _forward("leaveClanChatRoom", [clan_id], false)


func loadItemDefinitions() -> bool:
	return _forward("loadItemDefinitions", [], false)


func loadURL(url, post_data, this_handle = 0):
	_forward("loadURL", [url, post_data, this_handle])


func markContentCorrupt(missing_files_only) -> bool:
	return _forward("markContentCorrupt", [missing_files_only], false)


func mouseDoubleClick(mouse_button, this_handle = 0):
	_forward("mouseDoubleClick", [mouse_button, this_handle])


func mouseDown(mouse_button, this_handle = 0):
	_forward("mouseDown", [mouse_button, this_handle])


func mouseMove(x, y, this_handle = 0):
	_forward("mouseMove", [x, y, this_handle])


func mouseUp(mouse_button, this_handle = 0):
	_forward("mouseUp", [mouse_button, this_handle])


func mouseWheel(delta, this_handle = 0):
	_forward("mouseWheel", [delta, this_handle])


func musicGetVolume() -> float:
	return _forward("musicGetVolume", [], 0.0)


func musicIsEnabled() -> bool:
	return _forward("musicIsEnabled", [], false)


func musicIsPlaying() -> bool:
	return _forward("musicIsPlaying", [], false)


func musicPause():
	_forward("musicPause", [])


func musicPlay():
	_forward("musicPlay", [])


func musicPlayNext():
	_forward("musicPlayNext", [])


func musicPlayPrev():
	_forward("musicPlayPrev", [])


func musicSetVolume(volume):
	_forward("musicSetVolume", [volume])


func newDataAvailable() -> bool:
	return _forward("newDataAvailable", [], false)


func onReservationCompleted(beacon_id, steam_id):
	_forward("onReservationCompleted", [beacon_id, steam_id])


func openClanChatWindowInSteam(chat_id) -> bool:
	return _forward("openClanChatWindowInSteam", [chat_id], false)


func openDeveloperTools(browser_handle = 0):
	_forward("openDeveloperTools", [browser_handle])


func openOverlayToGamePhase(phase_id):
	_forward("openOverlayToGamePhase", [phase_id])


func openOverlayToTimelineEvent(timeline_event_handle):
	_forward("openOverlayToTimelineEvent", [timeline_event_handle])


func overlayNeedsPresent() -> bool:
	return _forward("overlayNeedsPresent", [], false)


func parseIPAddressString(reference_name, string_to_parse) -> bool:
	return _forward("parseIPAddressString", [reference_name, string_to_parse], false)


func parseIdentityString(reference_name, string_to_parse) -> bool:
	return _forward("parseIdentityString", [reference_name, string_to_parse], false)


func parsePingLocationString(string) -> Dictionary:
	return _forward("parsePingLocationString", [string], {})


func pasteFromClipboard(this_handle = 0):
	_forward("pasteFromClipboard", [this_handle])


func pingServer(ip, port) -> int:
	return _forward("pingServer", [ip, port], 0)


func playerDetails(ip, port) -> int:
	return _forward("playerDetails", [ip, port], 0)


func playlistDidChange() -> bool:
	return _forward("playlistDidChange", [], false)


func playlistWillChange() -> bool:
	return _forward("playlistWillChange", [], false)


func prioritizeHTTPRequest(request_handle) -> bool:
	return _forward("prioritizeHTTPRequest", [request_handle], false)


func queueDidChange() -> bool:
	return _forward("queueDidChange", [], false)


func queueWillChange() -> bool:
	return _forward("queueWillChange", [], false)


func receiveMessagesOnChannel(channel, max_messages) -> Array:
	return _forward("receiveMessagesOnChannel", [channel, max_messages], [])


func receiveMessagesOnConnection(connection, max_messages) -> Array:
	return _forward("receiveMessagesOnConnection", [connection, max_messages], [])


func receiveMessagesOnPollGroup(poll_group, max_messages) -> Array:
	return _forward("receiveMessagesOnPollGroup", [poll_group, max_messages], [])


func refreshQuery(server_list_request):
	_forward("refreshQuery", [server_list_request])


func refreshServer(server, server_list_request):
	_forward("refreshServer", [server, server_list_request])


func registerProtocolInOverlayBrowser(protocol) -> bool:
	return _forward("registerProtocolInOverlayBrowser", [protocol], false)


func registerSteamMusicRemote(name) -> bool:
	return _forward("registerSteamMusicRemote", [name], false)


func releaseCookieContainer(cookie_handle) -> bool:
	return _forward("releaseCookieContainer", [cookie_handle], false)


func releaseCurrentThreadMemory():
	_forward("releaseCurrentThreadMemory", [])


func releaseHTTPRequest(request_handle) -> bool:
	return _forward("releaseHTTPRequest", [request_handle], false)


func releaseRequest(server_list_request):
	_forward("releaseRequest", [server_list_request])


func reload(this_handle = 0):
	_forward("reload", [this_handle])


func removeAllItemKeyValueTags(update_handle) -> bool:
	return _forward("removeAllItemKeyValueTags", [update_handle], false)


func removeAppDependency(published_file_id, app_id):
	_forward("removeAppDependency", [published_file_id, app_id])


func removeBrowser(this_handle = 0):
	_forward("removeBrowser", [this_handle])


func removeContentDescriptor(update_handle, descriptor_id) -> bool:
	return _forward("removeContentDescriptor", [update_handle, descriptor_id], false)


func removeDependency(published_file_id, child_published_file_id):
	_forward("removeDependency", [published_file_id, child_published_file_id])


func removeFavoriteGame(app_id, ip, port, query_port, flags) -> bool:
	return _forward("removeFavoriteGame", [app_id, ip, port, query_port, flags], false)


func removeItemFromFavorites(app_id, published_file_id):
	_forward("removeItemFromFavorites", [app_id, published_file_id])


func removeItemKeyValueTags(update_handle, key) -> bool:
	return _forward("removeItemKeyValueTags", [update_handle, key], false)


func removeItemPreview(update_handle, index) -> bool:
	return _forward("removeItemPreview", [update_handle, index], false)


func removeProperty(item_id, name, this_inventory_update_handle = 0) -> bool:
	return _forward("removeProperty", [item_id, name, this_inventory_update_handle], false)


func removeTimelineEvent(timeline_event_handle):
	_forward("removeTimelineEvent", [timeline_event_handle])


func replyToFriendMessage(steam_id, message) -> bool:
	return _forward("replyToFriendMessage", [steam_id, message], false)


func requestClanOfficerList(clan_id):
	_forward("requestClanOfficerList", [clan_id])


func requestEligiblePromoItemDefinitionsIDs(steam_id):
	_forward("requestEligiblePromoItemDefinitionsIDs", [steam_id])


func requestEquippedProfileItems(steam_id):
	_forward("requestEquippedProfileItems", [steam_id])


func requestFavoritesServerList(app_id, filters):
	_forward("requestFavoritesServerList", [app_id, filters])


func requestFriendRichPresence(friend_id):
	_forward("requestFriendRichPresence", [friend_id])


func requestFriendsServerList(app_id, filters):
	_forward("requestFriendsServerList", [app_id, filters])


func requestGlobalAchievementPercentages():
	_forward("requestGlobalAchievementPercentages", [])


func requestGlobalStats(history_days):
	_forward("requestGlobalStats", [history_days])


func requestHistoryServerList(app_id, filters):
	_forward("requestHistoryServerList", [app_id, filters])


func requestInternetServerList(app_id, filters):
	_forward("requestInternetServerList", [app_id, filters])


func requestLANServerList(app_id):
	_forward("requestLANServerList", [app_id])


func requestLobbyData(steam_lobby_id) -> bool:
	return _forward("requestLobbyData", [steam_lobby_id], false)


func requestPlayersForGame(player_min, player_max, max_team_size) -> int:
	return _forward("requestPlayersForGame", [player_min, player_max, max_team_size], 0)


func requestPrices():
	_forward("requestPrices", [])


func requestSpectatorServerList(app_id, filters):
	_forward("requestSpectatorServerList", [app_id, filters])


func requestStoreAuthURL(redirect):
	_forward("requestStoreAuthURL", [redirect])


func requestUserInformation(steam_id, require_name_only) -> bool:
	return _forward("requestUserInformation", [steam_id, require_name_only], false)


func requestUserStats(steam_id):
	_forward("requestUserStats", [steam_id])


func resetAllStats(achievements_too) -> bool:
	return _forward("resetAllStats", [achievements_too], false)


func resetIdentity(this_identity):
	_forward("resetIdentity", [this_identity])


func resetPlaylistEntries() -> bool:
	return _forward("resetPlaylistEntries", [], false)


func resetQueueEntries() -> bool:
	return _forward("resetQueueEntries", [], false)


func restartAppIfNecessary(app_id) -> bool:
	return _forward("restartAppIfNecessary", [app_id], false)


func retrieveConnectionDetails(host_id) -> String:
	return _forward("retrieveConnectionDetails", [host_id], "")


func runFrame(reserved_value = true):
	_forward("runFrame", [reserved_value])


func runNetworkingCallbacks():
	_forward("runNetworkingCallbacks", [])


func searchForGameSolo(player_min, player_max) -> int:
	return _forward("searchForGameSolo", [player_min, player_max], 0)


func searchForGameWithLobby(lobby_id, player_min, player_max) -> int:
	return _forward("searchForGameWithLobby", [lobby_id, player_min, player_max], 0)


func sendClanChatMessage(chat_id, text) -> bool:
	return _forward("sendClanChatMessage", [chat_id, text], false)


func sendHTTPRequest(request_handle) -> bool:
	return _forward("sendHTTPRequest", [request_handle], false)


func sendHTTPRequestAndStreamResponse(request_handle) -> bool:
	return _forward("sendHTTPRequestAndStreamResponse", [request_handle], false)


func sendMessageToConnection(connection_handle, data, flags) -> Dictionary:
	return _forward("sendMessageToConnection", [connection_handle, data, flags], {})


func sendMessageToUser(identity_reference, data, flags, channel) -> int:
	return _forward("sendMessageToUser", [identity_reference, data, flags, channel], 0)


func sendMessages(messages, data, connection_handle, flags):
	_forward("sendMessages", [messages, data, connection_handle, flags])


func sendRemotePlayTogetherInvite(friend_id) -> bool:
	return _forward("sendRemotePlayTogetherInvite", [friend_id], false)


func serializeResult(this_inventory_handle = 0) -> String:
	return _forward("serializeResult", [this_inventory_handle], "")


func serverRules(ip, port) -> int:
	return _forward("serverRules", [ip, port], 0)


func setActiveBeta(beta_name) -> bool:
	return _forward("setActiveBeta", [beta_name], false)


func setAdminQuery(query_handle, admin_query) -> bool:
	return _forward("setAdminQuery", [query_handle, admin_query], false)


func setAllowCachedResponse(update_handle, max_age_seconds):
	_forward("setAllowCachedResponse", [update_handle, max_age_seconds])


func setAllowLegacyUpload(update_handle, allow_legacy_upload) -> bool:
	return _forward("setAllowLegacyUpload", [update_handle, allow_legacy_upload], false)


func setBackgroundMode(background_mode, this_handle = 0):
	_forward("setBackgroundMode", [background_mode, this_handle])


func setCertificate(certificate) -> Dictionary:
	return _forward("setCertificate", [certificate], {})


func setCloudEnabledForApp(enabled):
	_forward("setCloudEnabledForApp", [enabled])


func setCloudFileNameFilter(update_handle, match_cloud_filename) -> bool:
	return _forward("setCloudFileNameFilter", [update_handle, match_cloud_filename], false)


func setConnectionConfigValueFloat(connection, config, value) -> bool:
	return _forward("setConnectionConfigValueFloat", [connection, config, value], false)


func setConnectionConfigValueInt32(connection, config, value) -> bool:
	return _forward("setConnectionConfigValueInt32", [connection, config, value], false)


func setConnectionConfigValueString(connection, config, value) -> bool:
	return _forward("setConnectionConfigValueString", [connection, config, value], false)


func setConnectionDetails(details, connection_details) -> int:
	return _forward("setConnectionDetails", [details, connection_details], 0)


func setConnectionName(peer, name):
	_forward("setConnectionName", [peer, name])


func setConnectionPollGroup(connection_handle, poll_group) -> bool:
	return _forward("setConnectionPollGroup", [connection_handle, poll_group], false)


func setConnectionUserData(connection_handle, user_data) -> bool:
	return _forward("setConnectionUserData", [connection_handle, user_data], false)


func setCookie(hostname, key, value, path, expires, secure, http_only):
	_forward("setCookie", [hostname, key, value, path, expires, secure, http_only])


func setCurrentPlaylistEntry(id) -> bool:
	return _forward("setCurrentPlaylistEntry", [id], false)


func setCurrentQueueEntry(id) -> bool:
	return _forward("setCurrentQueueEntry", [id], false)


func setDLCContext(app_id, name) -> bool:
	return _forward("setDLCContext", [app_id, name], false)


func setDPIScalingFactor(dpi_scaling, browser_handle):
	_forward("setDPIScalingFactor", [dpi_scaling, browser_handle])


func setDisplayName(name) -> bool:
	return _forward("setDisplayName", [name], false)


func setDualSenseTriggerEffect(input_handle, parameters, trigger_mask, effect_mode, position, amplitude, frequency):
	_forward("setDualSenseTriggerEffect", [input_handle, parameters, trigger_mask, effect_mode, position, amplitude, frequency])


func setDurationControlOnlineState(new_state) -> bool:
	return _forward("setDurationControlOnlineState", [new_state], false)


func setGameHostParams(key, value) -> int:
	return _forward("setGameHostParams", [key, value], 0)


func setGameLauncherMode(mode):
	_forward("setGameLauncherMode", [mode])


func setGamePhaseAttribute(attribute_group, attribute_value, priority):
	_forward("setGamePhaseAttribute", [attribute_group, attribute_value, priority])


func setGamePhaseID(phase_id):
	_forward("setGamePhaseID", [phase_id])


func setGenericBytes(reference_name, data) -> bool:
	return _forward("setGenericBytes", [reference_name, data], false)


func setGenericString(reference_name, this_string) -> bool:
	return _forward("setGenericString", [reference_name, this_string], false)


func setGlobalConfigValueFloat(config, value) -> bool:
	return _forward("setGlobalConfigValueFloat", [config, value], false)


func setGlobalConfigValueInt32(config, value) -> bool:
	return _forward("setGlobalConfigValueInt32", [config, value], false)


func setGlobalConfigValueString(config, value) -> bool:
	return _forward("setGlobalConfigValueString", [config, value], false)


func setHTTPCookie(cookie_handle, host, url, cookie) -> bool:
	return _forward("setHTTPCookie", [cookie_handle, host, url, cookie], false)


func setHTTPRequestAbsoluteTimeoutMS(request_handle, milliseconds) -> bool:
	return _forward("setHTTPRequestAbsoluteTimeoutMS", [request_handle, milliseconds], false)


func setHTTPRequestContextValue(request_handle, context_value) -> bool:
	return _forward("setHTTPRequestContextValue", [request_handle, context_value], false)


func setHTTPRequestCookieContainer(request_handle, cookie_handle) -> bool:
	return _forward("setHTTPRequestCookieContainer", [request_handle, cookie_handle], false)


func setHTTPRequestGetOrPostParameter(request_handle, name, value) -> bool:
	return _forward("setHTTPRequestGetOrPostParameter", [request_handle, name, value], false)


func setHTTPRequestHeaderValue(request_handle, header_name, header_value) -> bool:
	return _forward("setHTTPRequestHeaderValue", [request_handle, header_name, header_value], false)


func setHTTPRequestNetworkActivityTimeout(request_handle, timeout_seconds) -> bool:
	return _forward("setHTTPRequestNetworkActivityTimeout", [request_handle, timeout_seconds], false)


func setHTTPRequestRawPostBody(request_handle, content_type, body_length) -> int:
	return _forward("setHTTPRequestRawPostBody", [request_handle, content_type, body_length], 0)


func setHTTPRequestRequiresVerifiedCertificate(request_handle, require_verified_certificate) -> bool:
	return _forward("setHTTPRequestRequiresVerifiedCertificate", [request_handle, require_verified_certificate], false)


func setHTTPRequestUserAgentInfo(request_handle, user_agent_info) -> bool:
	return _forward("setHTTPRequestUserAgentInfo", [request_handle, user_agent_info], false)


func setHorizontalScroll(absolute_pixel_scroll, this_handle = 0):
	_forward("setHorizontalScroll", [absolute_pixel_scroll, this_handle])


func setIPv4(reference_name, ip, port):
	_forward("setIPv4", [reference_name, ip, port])


func setIPv6(reference_name, ipv6, port):
	_forward("setIPv6", [reference_name, ipv6, port])


func setIPv6LocalHost(reference_name, port = 0):
	_forward("setIPv6LocalHost", [reference_name, port])


func setIdentityIPAddr(reference_name, ip_address_name) -> bool:
	return _forward("setIdentityIPAddr", [reference_name, ip_address_name], false)


func setIdentityLocalHost(reference_name):
	_forward("setIdentityLocalHost", [reference_name])


func setIdentitySteamID(reference_name, steam_id):
	_forward("setIdentitySteamID", [reference_name, steam_id])


func setIdentitySteamID64(reference_name, steam_id):
	_forward("setIdentitySteamID64", [reference_name, steam_id])


func setInGameVoiceSpeaking(steam_id, speaking):
	_forward("setInGameVoiceSpeaking", [steam_id, speaking])


func setInputActionManifestFilePath(manifest_path) -> bool:
	return _forward("setInputActionManifestFilePath", [manifest_path], false)


func setItemsDisabledLocally(file_ids, disabled_locally) -> bool:
	return _forward("setItemsDisabledLocally", [file_ids, disabled_locally], false)


func setKeyFocus(has_key_focus, this_handle = 0):
	_forward("setKeyFocus", [has_key_focus, this_handle])


func setLEDColor(input_handle, color_r, color_g, color_b, flags):
	_forward("setLEDColor", [input_handle, color_r, color_g, color_b, flags])


func setLanguage(query_handle, language) -> bool:
	return _forward("setLanguage", [query_handle, language], false)


func setLeaderboardDetailsMax(max_) -> int:
	return _forward("setLeaderboardDetailsMax", [max_], 0)


func setListenForFriendsMessages(intercept) -> bool:
	return _forward("setListenForFriendsMessages", [intercept], false)


func setLobbyGameServer(steam_lobby_id, server_ip, server_port, steam_id_game_server):
	_forward("setLobbyGameServer", [steam_lobby_id, server_ip, server_port, steam_id_game_server])


func setLobbyMemberLimit(steam_lobby_id, max_members) -> bool:
	return _forward("setLobbyMemberLimit", [steam_lobby_id, max_members], false)


func setLobbyType(steam_lobby_id, lobby_type) -> bool:
	return _forward("setLobbyType", [steam_lobby_id, lobby_type], false)


func setLocation(screenshot, location) -> bool:
	return _forward("setLocation", [screenshot, location], false)


func setMouseCursor(session_id, cursor_id):
	_forward("setMouseCursor", [session_id, cursor_id])


func setMousePosition(session_id, normalized_x, normalized_y):
	_forward("setMousePosition", [session_id, normalized_x, normalized_y])


func setMouseVisibility(session_id, visible):
	_forward("setMouseVisibility", [session_id, visible])


func setOverlayNotificationInset(horizontal, vertical):
	_forward("setOverlayNotificationInset", [horizontal, vertical])


func setOverlayNotificationPosition(pos):
	_forward("setOverlayNotificationPosition", [pos])


func setPNGIcon64x64(icon) -> bool:
	return _forward("setPNGIcon64x64", [icon], false)


func setPSNID(reference_name, psn_id):
	_forward("setPSNID", [reference_name, psn_id])


func setPageScaleFactor(zoom, point_x, point_y, this_handle = 0):
	_forward("setPageScaleFactor", [zoom, point_x, point_y, this_handle])


func setPersonaName(name):
	_forward("setPersonaName", [name])


func setPlayedWith(steam_id):
	_forward("setPlayedWith", [steam_id])


func setPlaylistEntry(id, position, entry_text) -> bool:
	return _forward("setPlaylistEntry", [id, position, entry_text], false)


func setPropertyBool(item_id, name, value, this_inventory_update_handle = 0) -> bool:
	return _forward("setPropertyBool", [item_id, name, value, this_inventory_update_handle], false)


func setPropertyFloat(item_id, name, value, this_inventory_update_handle = 0) -> bool:
	return _forward("setPropertyFloat", [item_id, name, value, this_inventory_update_handle], false)


func setPropertyInt(item_id, name, value, this_inventory_update_handle = 0) -> bool:
	return _forward("setPropertyInt", [item_id, name, value, this_inventory_update_handle], false)


func setPropertyString(item_id, name, value, this_inventory_update_handle = 0) -> bool:
	return _forward("setPropertyString", [item_id, name, value, this_inventory_update_handle], false)


func setQueueEntry(id, position, entry_text) -> bool:
	return _forward("setQueueEntry", [id, position, entry_text], false)


func setRankedByTrendDays(query_handle, days) -> bool:
	return _forward("setRankedByTrendDays", [query_handle, days], false)


func setRequiredGameVersions(query_handle, game_branch_min, game_branch_max) -> bool:
	return _forward("setRequiredGameVersions", [query_handle, game_branch_min, game_branch_max], false)


func setReturnAdditionalPreviews(query_handle, return_additional_previews) -> bool:
	return _forward("setReturnAdditionalPreviews", [query_handle, return_additional_previews], false)


func setReturnChildren(query_handle, return_children) -> bool:
	return _forward("setReturnChildren", [query_handle, return_children], false)


func setReturnKeyValueTags(query_handle, return_key_value_tags) -> bool:
	return _forward("setReturnKeyValueTags", [query_handle, return_key_value_tags], false)


func setReturnLongDescription(query_handle, return_long_description) -> bool:
	return _forward("setReturnLongDescription", [query_handle, return_long_description], false)


func setReturnMetadata(query_handle, return_metadata) -> bool:
	return _forward("setReturnMetadata", [query_handle, return_metadata], false)


func setReturnPlaytimeStats(query_handle, days) -> bool:
	return _forward("setReturnPlaytimeStats", [query_handle, days], false)


func setReturnTotalOnly(query_handle, return_total_only) -> bool:
	return _forward("setReturnTotalOnly", [query_handle, return_total_only], false)


func setSize(width, height, this_handle):
	_forward("setSize", [width, height, this_handle])


func setStadiaID(reference_name, stadia_id):
	_forward("setStadiaID", [reference_name, stadia_id])


func setStatFloat(name, value) -> bool:
	return _forward("setStatFloat", [name, value], false)


func setSubscriptionsLoadOrder(published_file_ids) -> bool:
	return _forward("setSubscriptionsLoadOrder", [published_file_ids], false)


func setSyncPlatforms(file, platform) -> bool:
	return _forward("setSyncPlatforms", [file, platform], false)


func setTimeCreatedDateRange(update_handle, start, end) -> bool:
	return _forward("setTimeCreatedDateRange", [update_handle, start, end], false)


func setTimeUpdatedDateRange(update_handle, start, end) -> bool:
	return _forward("setTimeUpdatedDateRange", [update_handle, start, end], false)


func setTimelineGameMode(mode):
	_forward("setTimelineGameMode", [mode])


func setTimelineTooltip(description, time_delta):
	_forward("setTimelineTooltip", [description, time_delta])


func setVRHeadsetStreamingEnabled(enabled):
	_forward("setVRHeadsetStreamingEnabled", [enabled])


func setVerticalScroll(absolute_pixel_scroll, this_handle = 0):
	_forward("setVerticalScroll", [absolute_pixel_scroll, this_handle])


func setXboxPairwiseID(reference_name, xbox_id) -> bool:
	return _forward("setXboxPairwiseID", [reference_name, xbox_id], false)


func set_server_list_request(new_server_list_request):
	_forward("set_server_list_request", [new_server_list_request])


func showBindingPanel(input_handle) -> bool:
	return _forward("showBindingPanel", [input_handle], false)


func showFloatingGamepadTextInput(input_mode, text_field_x_position, text_field_y_position, text_field_width, text_field_height) -> bool:
	return _forward("showFloatingGamepadTextInput", [input_mode, text_field_x_position, text_field_y_position, text_field_width, text_field_height], false)


func showGamepadTextInput(input_mode, line_input_mode, description, max_text, preset_text) -> bool:
	return _forward("showGamepadTextInput", [input_mode, line_input_mode, description, max_text, preset_text], false)


func showRemotePlayTogetherUI() -> bool:
	return _forward("showRemotePlayTogetherUI", [], false)


func showWorkshopEULA() -> bool:
	return _forward("showWorkshopEULA", [], false)


func startGamePhase():
	_forward("startGamePhase", [])


func startPlaytimeTracking(published_file_ids):
	_forward("startPlaytimeTracking", [published_file_ids])


func startPurchase(items, quantity):
	_forward("startPurchase", [items, quantity])


func startRangeTimelineEvent(title, description, icon, priority, start_offset_seconds, possible_clip = 1) -> int:
	return _forward("startRangeTimelineEvent", [title, description, icon, priority, start_offset_seconds, possible_clip], 0)


func startRemotePlayTogether(show_overlay = true) -> bool:
	return _forward("startRemotePlayTogether", [show_overlay], false)


func startUpdateProperties():
	_forward("startUpdateProperties", [])


func startVRDashboard():
	_forward("startVRDashboard", [])


func startVoiceRecording():
	_forward("startVoiceRecording", [])


func steamInitEx(retrieve_stats = true, app_id = 0, embed_callbacks = false) -> Dictionary:
	return _forward("steamInitEx", [retrieve_stats, app_id, embed_callbacks], {})


func steamShutdown():
	_forward("steamShutdown", [])


func stopAnalogActionMomentum(input_handle, action):
	_forward("stopAnalogActionMomentum", [input_handle, action])


func stopFind(this_handle = 0):
	_forward("stopFind", [this_handle])


func stopLoad(this_handle = 0):
	_forward("stopLoad", [this_handle])


func stopPlaytimeTracking(published_file_ids):
	_forward("stopPlaytimeTracking", [published_file_ids])


func stopPlaytimeTrackingForAllItems():
	_forward("stopPlaytimeTrackingForAllItems", [])


func stopVoiceRecording():
	_forward("stopVoiceRecording", [])


func submitPlayerResult(game_id, player_id, player_result) -> int:
	return _forward("submitPlayerResult", [game_id, player_id, player_result], 0)


func submitUpdateProperties(this_inventory_update_handle = 0) -> int:
	return _forward("submitUpdateProperties", [this_inventory_update_handle], 0)


func suspendDownloads(suspend):
	_forward("suspendDownloads", [suspend])


func tagPublishedFile(screenshot, file_id) -> bool:
	return _forward("tagPublishedFile", [screenshot, file_id], false)


func tagUser(screenshot, steam_id) -> bool:
	return _forward("tagUser", [screenshot, steam_id], false)


func terminateGameConnection(server_ip, server_port):
	_forward("terminateGameConnection", [server_ip, server_port])


func toIPAddressString(reference_name, with_port) -> String:
	return _forward("toIPAddressString", [reference_name, with_port], "")


func toIdentityString(reference_name) -> String:
	return _forward("toIdentityString", [reference_name], "")


func transferItemQuantity(item_id, quantity, item_destination, split) -> bool:
	return _forward("transferItemQuantity", [item_id, quantity, item_destination, split], false)


func translateActionOrigin(destination_input, source_origin) -> int:
	return _forward("translateActionOrigin", [destination_input, source_origin], 0)


func triggerHapticPulse(input_handle, target_pad, duration):
	_forward("triggerHapticPulse", [input_handle, target_pad, duration])


func triggerItemDrop(definition) -> bool:
	return _forward("triggerItemDrop", [definition], false)


func triggerRepeatedHapticPulse(input_handle, target_pad, duration, offset, repeat, flags):
	_forward("triggerRepeatedHapticPulse", [input_handle, target_pad, duration, offset, repeat, flags])


func triggerScreenshot():
	_forward("triggerScreenshot", [])


func triggerSimpleHapticEvent(input_handle, haptic_location, intensity, gain_db, other_intensity, other_gain_db):
	_forward("triggerSimpleHapticEvent", [input_handle, haptic_location, intensity, gain_db, other_intensity, other_gain_db])


func triggerVibration(input_handle, left_speed, right_speed):
	_forward("triggerVibration", [input_handle, left_speed, right_speed])


func triggerVibrationExtended(input_handle, left_speed, right_speed, left_trigger_speed, right_trigger_speed):
	_forward("triggerVibrationExtended", [input_handle, left_speed, right_speed, left_trigger_speed, right_trigger_speed])


func ugcDownload(content, priority):
	_forward("ugcDownload", [content, priority])


func ugcDownloadToLocation(content, location, priority):
	_forward("ugcDownloadToLocation", [content, location, priority])


func ugcRead(content, data_size, offset, action) -> PoolByteArray:
	return _forward("ugcRead", [content, data_size, offset, action], PoolByteArray())


func uninstallDLC(dlc_id):
	_forward("uninstallDLC", [dlc_id])


func updateAvgRateStat(name, this_session, session_length) -> bool:
	return _forward("updateAvgRateStat", [name, this_session, session_length], false)


func updateCurrentEntryCoverArt(art) -> bool:
	return _forward("updateCurrentEntryCoverArt", [art], false)


func updateCurrentEntryElapsedSeconds(seconds) -> bool:
	return _forward("updateCurrentEntryElapsedSeconds", [seconds], false)


func updateCurrentEntryText(text) -> bool:
	return _forward("updateCurrentEntryText", [text], false)


func updateItemPreviewFile(update_handle, index, preview_file) -> bool:
	return _forward("updateItemPreviewFile", [update_handle, index, preview_file], false)


func updateItemPreviewVideo(update_handle, index, video_id) -> bool:
	return _forward("updateItemPreviewVideo", [update_handle, index, video_id], false)


func updateLooped(looped) -> bool:
	return _forward("updateLooped", [looped], false)


func updatePlaybackStatus(status) -> bool:
	return _forward("updatePlaybackStatus", [status], false)


func updateRangeTimelineEvent(timeline_event_handle, title, description, icon, priority, possible_clip = 1):
	_forward("updateRangeTimelineEvent", [timeline_event_handle, title, description, icon, priority, possible_clip])


func updateShuffled(shuffle) -> bool:
	return _forward("updateShuffled", [shuffle], false)


func updateVolume(volume) -> bool:
	return _forward("updateVolume", [volume], false)


func uploadLeaderboardScore(score, keep_best = true, details = PoolIntArray(), this_leaderboard = 0):
	_forward("uploadLeaderboardScore", [score, keep_best, details, this_leaderboard])


func viewSource(this_handle = 0):
	_forward("viewSource", [this_handle])


func waitForData(wait_forever, timeout) -> bool:
	return _forward("waitForData", [wait_forever, timeout], false)


func writeScreenshot(rgb, width, height) -> int:
	return _forward("writeScreenshot", [rgb, width, height], 0)
