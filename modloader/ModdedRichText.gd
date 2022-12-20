extends RichTextLabel

# Gross fix, Godot 3.x problems
func _ready():
	self.rect_min_size.y = 80
