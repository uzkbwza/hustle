tool

extends Control

export var texture: Texture = null setget set_texture


func set_texture(texture):
	self.texture = texture
	$"%TextureRect".texture = texture


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
