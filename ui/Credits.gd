extends PanelContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if UIManager.is_connected("swiped_back", self, "_on_Button_pressed"):
		UIManager.disconnect("swiped_back", self, "_on_Button_pressed")
	UIManager.connect("swiped_back", self, "_on_Button_pressed")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Button_pressed():
	if not visible: return
	Global.reload()


func _on_TextureButton_pressed():
	OS.shell_open("https://godotengine.org/")
	pass # Replace with function body.


func _on_Label3_pressed():
	$"%Labels3".play()


func _on_Label_pressed():
	$"%Labels".play()
