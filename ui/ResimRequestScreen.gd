extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func _ready():
	Network.connect("resim_requested", self, "_on_resim_requested")

func _on_resim_requested():
	show()

func _on_ResimYes_pressed():
	Network.answer_resim_request(true)
	hide()

func _on_ResimNo_pressed():
	Network.answer_resim_request(false)
	hide()
