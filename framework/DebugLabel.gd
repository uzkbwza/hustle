extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	if !Debug.text_enabled:
		return
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Debug.enabled:
#		visible = !visible
		text = ""
		for line in Debug.lines():
			text = text + line + "\n"
