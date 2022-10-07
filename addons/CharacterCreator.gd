extends Control

func _ready():
	$Button.connect("pressed", self, "_on_button_pressed")

func _on_button_pressed():
	print("hi")
