extends Control

signal accepted()

func _ready():
	$"%ContinueButton".connect("pressed", self, "_on_continue_pressed")

func _on_continue_pressed():
	hide()
	emit_signal("accepted")
