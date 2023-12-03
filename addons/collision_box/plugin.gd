tool
extends EditorPlugin

var eds = get_editor_interface().get_selection()

func _enter_tree():
#	eds.connect("selection_changed", self, "on_selection_changed")
	add_custom_type("CollisionBox", "Node2D", preload("CollisionBox.gd"), preload("hurtbox.png"))

	pass

func _process(delta):
	var selected = eds.get_selected_nodes()
	for object in selected:
		if object is CollisionBox:
			object.editor_selected = true
	pass

func _exit_tree():
	remove_custom_type("CollisionBox")
	pass


#func on_selection_changed():
#	var selected = eds.get_selected_nodes()
#	for object in selected:
#		if object is CollisionBox:
#			object.editor_selected = true
