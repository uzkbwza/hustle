extends PanelContainer

signal selected()

onready var lobby_name = $"%LobbyName"
onready var player_count = $"%PlayerCount"
onready var select_rect = $SelectRect
onready var hover_rect = $HoverRect
onready var game_version = $"%GameVersion"

var lobby_id

var mouse_entered = false
var selected = false

func set_data(lobby_data):
	lobby_name.text = lobby_data.name
	game_version.text = lobby_data.version
	player_count.text = str(lobby_data.player_count) + "/" + str(lobby_data.max_players)
	lobby_id = lobby_data.id

func _input(event):
	if mouse_entered:
		if event is InputEventMouseButton:
			if event.pressed:
				select()

func select():
	selected = true
	select_rect.show()
	emit_signal("selected")

func deselect():
	select_rect.hide()
	selected = false

func _on_LobbyEntry_mouse_entered():
	mouse_entered = true
	hover_rect.show()
	pass # Replace with function body.


func _on_LobbyEntry_mouse_exited():
	mouse_entered = false
	hover_rect.hide()
	pass # Replace with function body.
