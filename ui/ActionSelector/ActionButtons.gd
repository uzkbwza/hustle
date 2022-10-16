extends Control

signal action_selected(action, data, extra)
signal action_clicked(action, data, extra)

const BUTTON_SCENE = preload("res://ui/ActionSelector/ActionButton.tscn")
const NUDGE_SCENE = preload("res://ui/ActionSelector/ActionUIData/NudgeActionUIData.tscn")
const BUTTON_CATEGORY_CONTAINER_SCENE = preload("res://ui/ActionSelector/ButtonCategoryContainer.tscn")

const BUTTON_CATEGORY_DISTANCE = 100

export var player_id = 1

var fighter: Fighter
#onready var button_container = $"%ButtonContainer"

var buttons = []
var last_button = null
var current_action = null
var current_button = null
var current_extra = null
var current_data = null
var button_pressed = null
var game

var continue_button

var spread_amount = 0.0
var spread_tween: SceneTreeTween = null

var nudge_button

var button_category_containers = {
	
}

func _input(event):
	if event is InputEventAction:
		if event.is_action_pressed("submit_action"):
			_on_submit_pressed()

func _ready():
	hint_tooltip = name
	$"%SelectButton".connect("pressed", self, "_on_submit_pressed")
#	$"%ContinueButton".connect("pressed", self, "on_action_selected", [$"%ContinueButton"])
	buttons.append($"%ContinueButton")
	$"%UndoButton".connect("pressed", self, "_on_undo_pressed")
	if player_id == 1:
		$"%BottomRow".alignment = BoxContainer.ALIGN_END
		$"%TopRow".alignment = BoxContainer.ALIGN_END
	else:
		$"%BottomRow".alignment = BoxContainer.ALIGN_BEGIN
		$"%TopRow".alignment = BoxContainer.ALIGN_BEGIN
	$"%AutoButton".hint_tooltip = "Skips your turn when no actions are available."
	$"%DI".hint_tooltip = "Adjusts the angle you are knocked back next time you are hit."
	$"%DI".connect("data_changed", self, "send_ui_action")
	if !player_id == 1:
		var top_row_items = $"%TopRow".get_children()
		top_row_items.invert()
		for i in range(top_row_items.size()):
			$"%TopRow".move_child(top_row_items[i], i)
#		$"%DIPlotContainer".alignment = BoxContainer.ALIGN_BEGIN

func _on_submit_pressed():
	var data = null
	if current_button:
		data = current_button.get_data()
	if current_action:
		on_action_submitted(current_action, data)

func _on_continue_pressed():
	on_action_submitted("Continue")

func _on_undo_pressed():
	on_action_submitted("Undo")

func reset():
	for button_category_container in button_category_containers.values():
		button_category_container.free()
	for button in buttons:
		if is_instance_valid(button):
			button.free()
	
	button_category_containers.clear()
#	for container in [category_container, action_container, action_data_container]:
#		for child in container.get_items():
#			child.free()
	current_action = null
	current_button = null
	last_button = null
	buttons = []

func init(game, id):
	reset()
	self.game = game
	fighter = game.get_player(id)
	Network.action_button_panels[id] = self
	buttons = []
#	for button in button_container.get_children():
#		button.free()
	var states = []
	for category in fighter.action_cancels:
		for state in fighter.action_cancels[category]:
			if state.show_in_menu and not state in states:
				states.append(state)
				create_button(state.name, state.title, state.get_ui_category(), state.data_ui_scene)
	nudge_button = create_button("Nudge", "DI", "Defense", NUDGE_SCENE)
	connect("action_selected", fighter, "on_action_selected")
	fighter.connect("action_selected", self, "_on_fighter_action_selected")
	hide()
	if player_id == 1:
		for i in range(button_category_containers.size()):
			$"%CategoryContainer".move_child(button_category_containers[button_category_containers.keys()[i]], button_category_containers.size() - i)
		$"%CategoryContainer".move_child($"%TurnButtons", $"%CategoryContainer".get_children().size() - 1)
	continue_button = create_button("Continue", "Continue", "Movement", null, preload("res://ui/ActionSelector/ContinueButton.tscn"))
	continue_button.get_parent().remove_child(continue_button)
	continue_button["custom_fonts/font"] = null
	$"%TurnButtons".add_child(continue_button)
	$"%TurnButtons".move_child(continue_button, 1)

func _on_fighter_action_selected(_action, _data, _extra):
	hide()

func create_button(name, title, category, data_scene=null, button_scene=BUTTON_SCENE):
	var button
	var data_node
	button = button_scene.instance()
	button.setup(name, title)
	buttons.append(button)
	
#	button_container.add_child(button)
	if not category in button_category_containers:
		create_category(category)
	var container = button_category_containers[category]
	container.add_button(button)
	if data_scene:
		data_node = data_scene.instance()
		container.add_data_node(data_node)
	button.set_data_node(data_node)
	button.connect("data_changed", self, "send_ui_action")
	button.container = container
	button.connect("was_pressed", self, "on_action_selected", [button])
	return button

func create_category(category):
	var scene = BUTTON_CATEGORY_CONTAINER_SCENE.instance()
	button_category_containers[category] = scene
	scene.show_behind_parent = true
	scene.init(category)
	scene.game = game
	scene.player_id = player_id
	$"%CategoryContainer".add_child(scene)

func send_ui_action(action=null):
	if game == null:
		return
	if action == null:
		action = current_action
	if !button_pressed:
		action = "Continue"
	if action:
		yield(get_tree(), "idle_frame")
		emit_signal("action_clicked", action, current_button.get_data() if current_button else null, get_extra())

func on_action_selected(action, button):
	button_pressed = true
	for b in buttons:
		if button != b:
			b.set_pressed_no_signal(false)
	button.set_pressed_no_signal(true)
	var same_button = button == current_button
	current_button = button
	current_action = action
#	if same_button:
#		return
	for category in button_category_containers.values():
		category.refresh()
	for button in buttons:
		if button.data_node:
			button.data_node.hide()
			button.container.hide_data_container()

	last_button = button
	if button.data_node:
		button.data_node.show()
		button.data_node.set_facing(fighter.get_opponent_dir())
		button.data_node.init()
		button.container.show_data_container()
	send_ui_action()

func get_extra():
	return {
		"DI": $"%DI".get_data()
	}

func on_action_submitted(action, data=null):
	var extra = get_extra()
	emit_signal("action_selected", action, data, extra)
	if Network.player_id == player_id:
		Network.submit_action(action, data, extra)
	hide()
#func debug_text():
#	$"%DebugLabel".text = str(center_panel.rect_size)

func get_visible_category_containers():
	var category_containers = []
	for container in button_category_containers.values():
		if container.any_buttons_visible():
			category_containers.append(container)
	return category_containers

func show_categories():
	for container in button_category_containers.values():
		container.hide()
	var category_containers = get_visible_category_containers()
	var num_button_categories = category_containers.size()
#	var distance = max(center_panel_container.rect_size.x, center_panel_container.rect_size.y) * 1.4
	for i in range(num_button_categories):
		if category_containers.size() <= i:
			break
		var scene = category_containers[i]
		scene.show()

func tween_spread():
	if spread_tween:
		spread_tween.kill()
	spread_amount = 0.0
	spread_tween = create_tween()
	spread_tween.set_ease(Tween.EASE_OUT)
	spread_tween.set_trans(Tween.TRANS_EXPO)
	spread_tween.tween_property(self, "spread_amount", 1.0, 0.20)

func activate():
	if visible:
		return
	var user_facing = game.singleplayer or Network.player_id == player_id
	if Network.multiplayer_active:
		if user_facing:
			$"%YouLabel".show()
			modulate = Color.white
		else:
			$"%YouLabel".hide()
			modulate = Color("b3b3b3")

	var showing = true
	if game.current_tick == 0:
		$"%UndoButton".set_disabled(true)
	else:
		$"%UndoButton".set_disabled(false)
	if Network.multiplayer_active:
		$"%UndoButton".hide()

#	tween_spread()
	current_action = null
	current_button = null
	var state = fighter.state_machine.state
	
	if showing:
		Network.turns_ready = {
			1: false,
			2: false
		}
		show()
#		Network.turn_started()
		

		for button in buttons:
			button.hide()
			button.set_disabled(true)
			if button.data_node:
				button.data_node.hide()
	#	if fighter.state_interruptable:
#		$"%SelectButton".show()
#		$"%SelectButton".disabled = false
	if !user_facing:
		$"%SelectButton".disabled = true
	else:
		$"%SelectButton".disabled = false

	var cancel_into
	if !fighter.busy_interrupt:
		cancel_into = (state.interrupt_into if !fighter.state_hit_cancellable else state.hit_cancel_into)
	else:
		cancel_into = state.busy_interrupt_into
	var any_available_actions = false

	for button in buttons:
		var found = false
		for category in cancel_into:
			if fighter.action_cancels.has(category):
				for cancel_state in fighter.action_cancels[category]:
					if cancel_state.state_name == button.action_name:
						if cancel_state.is_usable() and cancel_state.allowed_in_stance():
							if fighter.state_hit_cancellable:
								if cancel_state.state_name == state.state_name:
									if !state.self_hit_cancellable:
										continue
							found = true
#							$"%SelectButton".disabled = false
							any_available_actions = true
							
							if showing:
								button.set_disabled(false)
								button.show()
							break

#	if fighter.can_nudge and "Nudge" in cancel_into:
#		nudge_button.show()
#		nudge_button.set_disabled(false)

	if showing:
		if last_button and !last_button.get_disabled():
				last_button.set_pressed(true)
				last_button.on_pressed()
		else:
#			for button in buttons:
#				if !button.get_disabled():
#					button.set_pressed(true)
#					button.on_pressed()
#					break
			continue_button.set_pressed(true)
			continue_button.on_pressed()

	show_categories()
	
	if fighter.dummy:
		on_action_submitted("ContinueAuto", null)
		hide()

	fighter.any_available_actions = any_available_actions
	if user_facing and $"%AutoButton".pressed:
		if !any_available_actions:
			print("no available actions!")
			on_action_submitted("Continue", null)
			current_action = "Continue"

	yield(get_tree(), "idle_frame")
	if is_instance_valid(continue_button):
		continue_button.show()
		continue_button.set_disabled(false)
	button_pressed = false
	send_ui_action("Continue")
