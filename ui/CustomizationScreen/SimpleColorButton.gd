extends Button

var color
var outline

func init(color, outline):
	$Fill.color = Color(color)
	$Outline.color = Color(outline)
	self.color = color
	self.outline = outline
