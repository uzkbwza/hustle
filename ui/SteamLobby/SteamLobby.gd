extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var user_list = $"%UserList"

var users = []
var selected_user = null

# Called when the node enters the scene tree for the first time.
func _ready():
	SteamLobby.connect("lobby_data_update", self, "_on_lobby_data_update")
	SteamLobby.connect("retrieved_lobby_members", self, "_on_retrieved_lobby_members")
	$"%BackButton".connect("pressed", self, "_on_back_button_pressed")
	$"%StartButton".connect("pressed", self, "_on_start_button_pressed")
	user_list.connect("item_selected", self, "_on_user_selected")

func _on_lobby_data_update(steam_id, member_id, success):
	pass

func _on_user_selected(index):
	if users[index].steam_id == SteamYomi.STEAM_ID:
		return
	selected_user = users[index]
	$"%StartButton".disabled = false

func _on_start_button_pressed():
	if selected_user:
		SteamLobby.challenge_user(selected_user)

func _on_retrieved_lobby_members(members):
	user_list.clear()
	users.clear()
	for member in members:
		user_list.add_item(member.steam_name, null)
		users.append(member)

func _on_back_button_pressed():
	Network.stop_multiplayer()
	get_tree().reload_current_scene()
