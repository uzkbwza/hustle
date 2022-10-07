extends ScrollContainer

onready var container = $"%VBoxContainer"

func add_item(node):
	container.add_child(node)

func get_items():
	return container.get_children()
