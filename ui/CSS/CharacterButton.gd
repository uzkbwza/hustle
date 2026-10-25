extends Button

export(PackedScene) var character_scene

onready var char_select = Network.css_instance


func _ready():
	connect("visibility_changed", self, "on_visibility_changed")



func on_visibility_changed():
	if is_visible_in_tree():
		var display_data = char_select.get_display_data(self)
		$ClipContents/TextureRect.texture = display_data["portrait"]
