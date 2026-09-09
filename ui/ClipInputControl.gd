extends Container


export var expand := false setget set_expand



func set_expand(value):
	expand = value
	queue_sort()



# I'm losing my mind
func _clips_input():
	return true



func _init():
	connect("sort_children", self, "_on_sort_children")
	connect("resized", self, "refresh")



func refresh():
	queue_sort()



func _on_sort_children():
	rect_min_size = Vector2()
	if expand:
		for child in get_children():
			fit_child_in_rect(child, Rect2(Vector2(), Vector2()))
			rect_min_size.x = max(rect_min_size.x, child.rect_size.x)
			rect_min_size.y = max(rect_min_size.y, child.rect_size.y)
	for child in get_children():
		fit_child_in_rect(child, Rect2(Vector2(), rect_size))
		# Hard coded to expect Grow Direction H-End V-Begin
		# If this needs to be changed later, it can be, but, like
		# I already went down this massive rabbit hole to make this work
		child.rect_position.y = rect_size.y - child.rect_size.y

