extends VBoxContainer

export var player_id = 1

func _ready():
	$"%PlayerLabel".text = "P1" if player_id == 1 else "P2"

func init():
	$"%CharacterLabel".text = ""
	set_enabled(true)

func load_character_data(data):
	$"%CharacterLabel".text = data["filename"].split("/")[-1].split(".")[0]

func set_enabled(on):
	for child in get_children():
		child.visible = on
