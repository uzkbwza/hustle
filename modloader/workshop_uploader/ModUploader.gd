extends Control

var image_valid = false
var zip_path = ""
var has_name = false
var has_tag = false

var tag_nodes = {}
var node_tags = {}

var initialized = false

func init():
	var dir = Directory.new()
	dir.make_dir_recursive(get_dir())
#
	for button in $"%TagsContainer".get_children():
		button.connect("pressed", self, "update_has_tags")
	
	node_tags = {
		$"%Character": "Character",
		$"%TextureReplacement": "Texture Replacement",
		$"%SoundReplacement": "Sound Replacement",
		$"%Gamemode": "Gamemode",
		$"%Stage": "Stage",
		$"%Tweaks": "Tweaks",
		$"%Tool": "Tool",
		$"%Overhaul": "Overhaul",
		$"%ClientSide": "Clientside",
	}
	
	for node in node_tags:
		tag_nodes[node_tags[node]] = node
	initialized = true
	refresh()

func show():
	if !initialized:
		init()
	.show()
	refresh()

func get_dir():
	return ProjectSettings.globalize_path("user://".plus_file("modupload"))

func get_image_path():
	return get_dir().plus_file("preview.png")

func update_workshop_button():
	$"%UploadButton".disabled = !is_valid_workshop_item()
	$"%WorkshopItemLink".hide()

func is_valid_workshop_item():
	return image_valid and zip_path != "" and has_name and has_tag

func refresh(load_save_data=true):
	if load_save_data:
		var file = File.new()
		var err = file.open(get_dir().plus_file("workshop_data.json"), File.READ)
		if err == OK:
			var text = file.get_as_text()
			var data = JSON.parse(text).result
			if data is Dictionary:
				$"%ModID".text = data.id
				$"%ModName".text = data.name
				$"%ModDesc".text = data.desc
				set_tags(data.tags)
			file.close()

	zip_path = ""
	image_valid = false
	var img = Image.new()
	var file = File.new()
	var err = file.open(get_image_path(), File.READ)
	if err == OK:
		var bytes = file.get_buffer(file.get_len())
		err = img.load_png_from_buffer(bytes)
		if err == OK:
			img.lock()
		
	$"%PreviewFoundLabel".modulate = Color("64d26b")
	$"%ZipFoundLabel".modulate = Color("64d26b")
	$"%LocalLabel".modulate = Color.white
	
	if err != OK:
		$"%PreviewFoundLabel".text = "preview.png missing or invalid..."
		$"%PreviewFoundLabel".modulate = Color("ff333d")
		$"%LocalLabel".modulate = Color("ff333d")
		$"%PreviewImage".texture = null
	else:
		image_valid = true
		var texture = ImageTexture.new()
		texture.create_from_image(img, 0)
		$"%PreviewImage".texture = texture
		$"%PreviewFoundLabel".text = "using preview.png."

	var files = Utils.get_files_in_folder(get_dir(), ".zip")
	if files == []:
		$"%ZipFoundLabel".text = ".zip file not found..."
		$"%LocalLabel".modulate = Color("ff333d")
		$"%ZipFoundLabel".modulate = Color("ff333d")
	else:
		if files.size() > 1:
			$"%ZipFoundLabel".text = "using multiple .zip files."
		else:
			$"%ZipFoundLabel".text = "using %s." % files[0].get_file()
		zip_path = files[0]
	_on_ModName_text_changed()
	update_workshop_button()
	update_has_tags()
	print(get_mod_data())

func save():
	var data = get_mod_data()
	var dir = get_dir()
	var file = File.new()
	print(dir.plus_file("workshop_data.json"))
	file.open(dir.plus_file("workshop_data.json"), File.WRITE)
	file.store_string(JSON.print(data))
	file.close()

func get_mod_data():
	return {
		"name": get_mod_name(),
		"desc": get_mod_desc(),
		"id": get_mod_id(),
		"tags": get_tags(),
	}

func get_mod_name():
	return $"%ModName".text.strip_edges()
	
func get_mod_desc():
	return $"%ModDesc".text.strip_edges()

func get_mod_id():
	return $"%ModID".text.strip_edges()

func set_tags(tags):
	for node in node_tags:
		node.set_pressed_no_signal(false)
	
	for tag in tags:
		if tag in tag_nodes:
			tag_nodes[tag].set_pressed_no_signal(true)

func get_tags():
	var tags = []
	
	for node in node_tags:
		if node.pressed:
			tags.append(node_tags[node])
	
	return tags

func _on_BackButton_pressed():
	Global.reload()
	pass # Replace with function body.

func _on_OpenFolderButton_pressed():
	OS.shell_open(get_dir())
	pass # Replace with function body.

func _on_RefreshButton_pressed():
	refresh()

func _on_SaveButton_pressed():
	save()
	pass # Replace with function body.

func _on_ModName_text_changed(new_text=""):
	$"%ModNameMissingLabel".visible = get_mod_name() == ""
	
	has_name = !$"%ModNameMissingLabel".visible
	if has_name:
		$"%InfoLabel".modulate = Color.white
	else:
		$"%InfoLabel".modulate = Color("ff333d")
	update_workshop_button()

func _on_UploadButton_pressed():
	save()
	refresh(false)
	$"%UploadButton".disabled = true
	if !is_valid_workshop_item():
		return
	update_workshop_button()

	var id = 0 if get_mod_id() == "" else int(get_mod_id())
	var item = UGCItem.new(id)
	if id != 0:
		update_item(item, false)
	item.connect("item_created", self, "_on_item_created")
	item.connect("item_updated", self, "_on_item_updated")

func update_has_tags():
#	$"%ModTagMissingLabel".hide()
	$"%TagsLabel".modulate = Color.white
	$"%TagsMissingLabel".hide()
	for child in $"%TagsContainer".get_children():
		if child.pressed:
			has_tag = true
			update_workshop_button()
			return
#	$"%ModTagMissingLabel".show()
	$"%TagsLabel".modulate = Color("ff333d")
	$"%TagsMissingLabel".show()
	has_tag = false
	update_workshop_button()

func update_item(item: UGCItem, new=true):
	var data = get_mod_data()
	item.set_tags(data.tags)
	item.set_title(data.name)
	item.set_description(data.desc)
	item.set_content(get_dir())
	item.set_preview(get_image_path())
	item.set_visibility(0)
	item.update($"%ModUpdateNotes".text)

func _on_item_created(p_file_id):
	var item = UGCItem.new(p_file_id)
	$"%ModID".text = str(p_file_id)
	save()
	update_item(item)

func _on_item_updated(url):
	$"%WorkshopItemLink".show()
	$"%WorkshopItemLink".clear()
	$"%WorkshopItemLink".append_bbcode("[center][u][url=%s]Workshop item uploaded." % url)

func _on_WorkshopItemLink_meta_clicked(meta):
	OS.shell_open(meta)
	pass # Replace with function body.

func _on_VisitWorkshopButton_pressed():
	Steam.activateGameOverlayToWebPage("https://steamcommunity.com/app/2212330/workshop/")
	pass # Replace with function body.
