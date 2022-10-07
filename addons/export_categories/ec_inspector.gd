extends EditorInspectorPlugin


func can_handle(object: Object) -> bool:
	return true


func parse_property(object: Object, type: int, path: String, hint: int, hint_text: String, usage: int) -> bool:
	# Get any variabled prefixed with _c_
	if "_c_" in path:
		add_property_editor(path, EC_CreateCategory.new())
		return true
	return false
