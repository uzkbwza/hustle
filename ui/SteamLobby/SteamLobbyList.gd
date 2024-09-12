extends Control

onready var lobby_list = $"%LobbyList"
onready var lobby_name = $"%LobbyName"
onready var charloader_button = $"%CharloaderButton"
onready var exclamation_button = $"%ExclamationButton"
onready var exclamation_button_y = exclamation_button.rect_position.y
onready var custom_char_on = $"%CustomCharOn"
onready var custom_char_off = $"%CustomCharOff"

var selected_lobby
var lobbies = []


var show_custom_character_lobbies = true
var show_vanilla_lobbies = true

var t = 0

func _ready():
	$"%CreateLobbyButton".connect("pressed", self, "_on_create_lobby_button_pressed")
#	$"%RefreshTimer".connect("timeout", self, "_on_refresh_timer_timeout")
	SteamLobby.connect("lobby_match_list_received", self, "_on_lobby_match_list_received", [], CONNECT_DEFERRED)
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	
	charloader_button.disabled = !ModLoader.active
#	exclamation_button.visible = ModLoader.active

	if Global.seen_custom_character_nag and !OS.is_debug_build():
		exclamation_button.hide()

#	charloader_button.pressed = ModLoader.active

func _on_create_lobby_button_pressed():
	var availability
	if $"%PublicButton".pressed:
		availability = SteamLobby.LOBBY_AVAILABILITY.PUBLIC
	else:
		availability = SteamLobby.LOBBY_AVAILABILITY.FRIENDS
	SteamLobby.LOBBY_NAME = get_lobby_name()
	SteamLobby.LOBBY_CHARLOADER_ENABLED = charloader_button.pressed and ModLoader.active
	SteamLobby.create_lobby(availability, $"%LobbySize".value)

func _on_back_button_pressed():
	Network.stop_multiplayer()
	Global.reload()

func show():
	.show()

	_on_LobbySize_value_changed($"%LobbySize".value)
	$"%ConnectingLabel".show()
	clear_lobby_list()
	request_lobby_list()
#	_on_refresh_timer_timeout()

func request_lobby_list(code=""):
	SteamLobby.request_lobby_list(code, Global.VERSION if $"%FilterIncompatibleButton".pressed else "", show_custom_character_lobbies, show_vanilla_lobbies)
 
func get_lobby_name():
	var lobby_text = lobby_name.text.strip_edges()
	if lobby_text == "":
		return SteamHustle.STEAM_NAME + "'s Lobby"
	return lobby_text

func clear_lobby_list():
	for child in lobby_list.get_children():
		child.free()
#
#func _process(delta):
#	if !is_visible_in_tree():
#		return
#	t += delta
##	var color = Color("ffd519").linear_interpolate(Color("65e6ff"), sin(t * 3))
##	$"%CharloaderButton".set("custom_colors/font_color", color)
##	$"%CharloaderButton".set("custom_colors/font_color_hover", color)
##	$"%CharloaderButton".set("custom_colors/font_color_pressed", color)
#	if exclamation_button.visible:
#		exclamation_button.rect_position.y = exclamation_button_y + sin(t * 30) * 3

	
	
		

func _on_lobby_match_list_received(lobbies):
	self.lobbies = lobbies
	$"%ConnectingLabel".hide()
	# TODO - keep and update existing lobbies so your selection isnt cleared
#		$"%LobbyList".clear()
	clear_lobby_list()
	var sorting_methods = [
		"sort_player_count",
		"sort_name",
	]
	
	lobbies.sort_custom(self, sorting_methods[$"%SortButton".selected])

	for lobby in lobbies:
		# Pull lobby data from Steam, these are specific to our example
		var lobby_name: String = Steam.getLobbyData(lobby, "name")
#			var lobby_status: String = Steam.getLobbyData(lobby, "status")
		var lobby_version: String = Steam.getLobbyData(lobby, "version")
		
		var charloader_enabled: String = Steam.getLobbyData(lobby, "charloader")
		if not (charloader_enabled in ["Yes", "No"]):
			charloader_enabled  = "N/A" 
		
		var lobby_max_members: int = Steam.getLobbyMemberLimit(lobby)
		
		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(lobby)
		
		var lobby_entry = preload("res://ui/SteamLobby/LobbyEntry.tscn").instance()
		lobby_list.add_child(lobby_entry)
		lobby_entry.connect("selected", self, "_on_lobby_clicked", [lobby_entry])
		var data = {
			"name": lobby_name,
#				"status": lobby_status,
			"version": lobby_version,
			"player_count": lobby_num_members,
			"max_players": lobby_max_members,
			"charloader_enabled": charloader_enabled == "Yes",
			"charloader_enabled_text": charloader_enabled,
			"id": lobby,
		}
		lobby_entry.set_data(data)
		if lobby == selected_lobby:
			lobby_entry.select()
		pass
#	yield(get_tree().create_timer(1.0), "timeout")

func sort_player_count(a, b):
	return Steam.getNumLobbyMembers(a) > Steam.getNumLobbyMembers(b)

func sort_name(a, b):
	return Steam.getLobbyData(a, "name") > Steam.getLobbyData(b, "name")
	pass

func _on_lobby_clicked(entry):
#	print("here")
	if SteamLobby.LOBBY_ID != 0:
		return
	for lobby in lobby_list.get_children():
		if lobby != entry:
			lobby.deselect()
	if entry.lobby_data.version != Global.VERSION:
		error("Mismatched versions. Make sure your game is fully updated, or you have the same mods enabled.")
		return
	selected_lobby = entry.lobby_id
	SteamLobby.join_lobby(entry.lobby_id)
	$"%LobbyList".hide()
	$"%LobbyConnectingLabel".show()

func error(text):
	$"%ErrorLabel".text = text

func _on_SteamLobbyList_visibility_changed():
	if !visible:
		$"%RefreshTimer".stop()
	pass # Replace with function body.

func _on_FilterIncompatibleButton_toggled(button_pressed):
	request_lobby_list($"%CodeSearch".text)
#	_on_lobby_match_list_received(lobbies)


func _on_RefreshButton_pressed():
	request_lobby_list()
	pass # Replace with function body.


func _on_SortButton_item_selected(index):
	request_lobby_list()
#	_on_lobby_match_list_received(lobbies)
	pass # Replace with function body.


func _on_SearchButton_pressed():
	request_lobby_list($"%CodeSearch".text)
	pass # Replace with function body.


func _on_CodeSearch_text_entered(new_text):
	request_lobby_list(new_text)
	pass # Replace with function body.

func _on_LobbySize_value_changed(value):
	$"%LobbySizeLabelCount".text = str(value)
	pass # Replace with function body.


func _on_LobbySettingsChangeWindowButton_pressed():
	$"%LobbySettingsChangedWindow".hide()
	pass # Replace with function body.


func _on_ExclamationButton_pressed():
	$"%LobbySettingsChangedWindow".show()
	exclamation_button.hide()
	Global.seen_custom_character_nag = true
	pass # Replace with function body.

func _on_CustomCharOff_toggled(button_pressed):
	show_vanilla_lobbies = button_pressed
	if !show_vanilla_lobbies and !show_custom_character_lobbies:
		custom_char_on.pressed = false
		custom_char_off.pressed = true
		return
	request_lobby_list()
	pass # Replace with function body.

func _on_CustomCharOn_toggled(button_pressed):
	show_custom_character_lobbies = button_pressed
	if !show_vanilla_lobbies and !show_custom_character_lobbies:
		custom_char_on.pressed = false
		custom_char_off.pressed = true
		return
	request_lobby_list()
	pass # Replace with function body.
