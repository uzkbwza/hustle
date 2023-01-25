tool

extends Panel

var anim_name: String

var anim_length = 0
var loop_animation = false

var frame_buttons = []

var frame_map = {
	
}

var frame_array = []

var loaded_object: BaseObj
var loaded_state: ObjectState = null
var loaded_sprite: AnimatedSprite = null
var loaded_sprite_frames: SpriteFrames = null

var states = []
var anims = []

var tick_data = {
	
}

var throw_positions = {

}

var texture_mouse_positions = {
	
}

var texture_mouse_pos = Vector2()

var selected_frame = 0
var selected_frame_texture: Texture = null

func _ready():
	$"%SelectedAnimation".connect("item_selected", self, "_on_animation_selected")
	$"%SelectedState".connect("item_selected", self, "_on_state_selected")
	$"%ClearThrowPositionButton".connect("pressed", self, "_on_clear_throw_position_pressed")
	$"%SaveToState".connect("pressed", self, "save_to_state")
	$"%ReloadState".connect("pressed", self, "reload_state")
	$"%ReloadObject".connect("pressed", self, "reload_object")

func _on_animation_selected(index):
#	print(anims)
	if anims.size() > index:
		load_animation_data(loaded_state, anims[index])

func _on_state_selected(index):
	if states.size() > index:
		load_state(states[index])

func _on_clear_throw_position_pressed():
	throw_positions.erase(selected_frame_texture)
	texture_mouse_positions.erase(selected_frame_texture)
	texture_mouse_pos = Vector2()
	$"%FrameDisplay".reset()
	update_menu()

func save_to_state():
	if !loaded_state:
		return
	loaded_state.anim_length = anim_length
	var positions = throw_positions.duplicate(true)
	loaded_state.throw_positions = positions
	for frame in positions:
		if !frame in loaded_object.throw_positions:
			loaded_object.throw_positions[frame] = positions[frame]
	save_animation(anim_name)

func save_animation(anim_name):
	loaded_sprite_frames = loaded_sprite_frames.duplicate(true)
	loaded_sprite_frames.clear(anim_name)
	for frame in frame_array:
		loaded_sprite_frames.add_frame(anim_name, frame)
	loaded_sprite_frames.take_over_path(loaded_sprite_frames.resource_path)
	loaded_sprite.frames = loaded_sprite_frames

func reload_state():
	load_node(loaded_object)
	load_state(loaded_state)

func reload_object():
	load_node(loaded_object)

func set_throw_position():
	var pos_x = texture_mouse_pos.x
	var pos_y = texture_mouse_pos.y
	var x_diff = $"%FrameDisplay".rect_size.x / selected_frame_texture.get_size().x
	var y_diff = $"%FrameDisplay".rect_size.y / selected_frame_texture.get_size().y
	pos_x /= x_diff
	pos_y /= y_diff
	pos_x -= selected_frame_texture.get_size().x / 2
	pos_y -= selected_frame_texture.get_size().x / 2
	throw_positions[selected_frame_texture] = {
		"x": int(pos_x),
		"y": int(pos_y),
	}
	texture_mouse_positions[selected_frame_texture] = texture_mouse_pos
	$"%FrameDisplay".set_throw_pos(texture_mouse_pos)
	update_menu()

func sort_states(a, b):
	return a.name < b.name

func load_node(node: BaseObj, force=true):
	var same_object = loaded_object == node
	if same_object and !force:
		return
	var current_anim
	if same_object:
		current_anim = anim_name

	loaded_object = node
	states.clear()
	anims.clear()
	tick_data.clear()
	
	$"%SelectedState".clear()
	$"%SelectedAnimation".clear()

	for state in node.get_node("StateMachine").get_children():
		if state is ObjectState:
			states.append(state)

	states.sort_custom(self, "sort_states")
	for state in states:
		$"%SelectedState".add_item(state.name)
	
	var sprite: AnimatedSprite = node.get_node("Flip/Sprite")
	if sprite:
		for animation in sprite.frames.get_animation_names():
			anims.append(animation)
	anims.sort()
	for animation in anims:
		$"%SelectedAnimation".add_item(animation)
	loaded_sprite = sprite

	if states:
		if !same_object:
			load_state(states[0])
		else:
			for state in states:
				if get_anim_name(state) == current_anim:
					load_state(state)
					for i in range($"%SelectedState".get_item_count()):
						if $"%SelectedState".get_item_text(i) == current_anim:
							$"%SelectedState".selected = i
					break

func load_state(state):
	loaded_state = state
	load_animation_data(loaded_state)

func get_anim_name(state):
	return state.sprite_animation if state.sprite_animation else state.name

func load_animation_data(node: ObjectState, animation=null):
	throw_positions.clear()
	var host = node.get_parent().get_parent()
	var sprite = host.get_node("Flip/Sprite")
	var frames = sprite.frames.duplicate(true)
	throw_positions = node.throw_positions.duplicate(true)
	anim_name = get_anim_name(node) if !animation else animation
	for i in range($"%SelectedAnimation".get_item_count()):
		if $"%SelectedAnimation".get_item_text(i) == anim_name:
			$"%SelectedAnimation".selected = i
			break

#	print(loaded_state.name)
	anim_length = node.anim_length
	loop_animation = node.loop_animation

	var current_frame = null
	
	frame_array.clear()
	frame_map.clear()
	
	for i in range(frames.get_frame_count(anim_name)):
		if i > node.anim_length:
			break
		var frame = frames.get_frame(anim_name, i)
		if frame:
			if frame != current_frame:
				frame_map[i] = frame
				current_frame = frame
	loaded_sprite_frames = frames
#	print(anim_length)
	
	update_frame_array()
	update_menu()
	_on_frame_button_pressed(0)

func update_menu():
	update_frame_array()
	for child in $"%FrameButtonContainer".get_children():
		child.queue_free()
		
	frame_buttons.clear()
	$"%ClearThrowPositionButton".set_pressed_no_signal(false)
	
	for i in range(anim_length):
		if loop_animation and frame_array.size() <= i:
			break
		var frame_button = preload("res://addons/helpers/AnimationEditor/FrameButton.tscn").instance()
		$"%FrameButtonContainer".add_child(frame_button)
		frame_buttons.append(frame_button)
		frame_button.set_frame(i)
		frame_button.connect("pressed", self, "_on_frame_button_pressed", [i])
		frame_button.connect("insert_before", self, "insert_frame", [i - 1])
		frame_button.connect("insert_after", self, "insert_frame", [i])
		frame_button.connect("delete", self, "delete_frame", [i])

	var current_frame = null
	for i in range(frame_array.size()):
		if i > anim_length:
			break
		var frame = frame_array[i]
		if frame:
			if frame_buttons.size() > i:
				frame_buttons[i].set_image(frame)
				frame_buttons[i].set_keyframe(false)
				if frame != current_frame:
					current_frame = frame
					frame_buttons[i].set_keyframe(true)

	update_frame_array()

func update_frame_array():
	frame_array.clear()
	var current_frame = null
	for i in range(anim_length):
		if frame_map.has(i):
			current_frame = frame_map[i]
		frame_array.append(current_frame)

func insert_frame(i):
	var old_map = {}
	
	for key in frame_map.keys():
		if key > i:
			var value = frame_map[key]
			old_map[key] = value
			frame_map.erase(key)

	for key in old_map:
		frame_map[key + 1] = old_map[key]
		if key == selected_frame:
			_on_frame_button_pressed(key + 1)
	
	anim_length += 1
	
	update_frame_array()
	update_menu()

func delete_frame(i):
	if frame_map.has(i):
		frame_map.erase(i)
	for key in frame_map.keys():
		if key > i:
			var value = frame_map[key]
			frame_map.erase(key)
			frame_map[key - 1] = value
			if key == selected_frame:
				_on_frame_button_pressed(key - 1)
	anim_length -= 1
	update_menu()

func _on_frame_button_pressed(index):
	var frame = frame_array[index]
	selected_frame = index
	selected_frame_texture = frame
	$"%FrameLabel".text = "Frame " + str(index + 1)
	$"%FrameDisplay".set_texture(frame)
	$"%FrameDisplay".reset()
	
	if throw_positions.has(frame):
		texture_mouse_pos = throw_pos_to_texture_mouse_pos(throw_positions[frame])
		$"%FrameDisplay".set_throw_pos(texture_mouse_pos)
	

func throw_pos_to_texture_mouse_pos(throw_pos):
	var pos_x = throw_pos.x
	var pos_y = throw_pos.y
	pos_x += selected_frame_texture.get_size().x / 2.0
	pos_y += selected_frame_texture.get_size().y / 2.0
	var x_diff = selected_frame_texture.get_size().x / $"%FrameDisplay".rect_size.x 
	var y_diff = selected_frame_texture.get_size().y / $"%FrameDisplay".rect_size.y
	pos_x /= x_diff
	pos_y /= y_diff
	texture_mouse_pos = Vector2(pos_x, pos_y)
	return texture_mouse_pos


func _on_FrameDisplay_gui_input(event):
	if !selected_frame_texture:
		return
	if event is InputEventMouseButton:
		if event.button_mask == BUTTON_LEFT and event.pressed:
			texture_mouse_pos = event.position
			set_throw_position()

func _draw():
	pass
