extends VBoxContainer

export var player_id = 1

func _ready():
	$"%PlayerLabel".text = "P1" if player_id == 1 else "P2"
	$"%CharacterPortrait".flip_h = player_id != 1

func init():
	$"%CharacterLabel".text = ""
	$"%CharacterPortrait".texture = null
	set_enabled(true)

func load_character_data(data):
	$"%CharacterPortrait".texture = data["portrait"]
	$"%CharacterLabel".text = data["name"]

func set_enabled(on):
	for child in get_children():
		child.visible = on
