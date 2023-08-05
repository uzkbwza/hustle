extends PlayerExtra

onready var bomb_button = $"%BombButton"
onready var pull_button = $"%PullButton"
#onready var end_bomb_button = $"%EndbombButton"
onready var detach_button = $"%DetachButton"
onready var release_button = $"%ReleaseButton"
onready var boost_dir = $"%BoostDir"
onready var store_button = $"%StoreButton"

func _ready():
	bomb_button.connect("toggled", self, "_on_bomb_button_toggled")
	pull_button.connect("toggled", self, "_on_bomb_button_toggled")
	detach_button.connect("toggled", self, "_on_bomb_button_toggled")
	release_button.connect("toggled", self, "_on_bomb_button_toggled")
	store_button.connect("toggled", self, "_on_bomb_button_toggled")
	store_button.connect("toggled", self, "_on_store_button_toggled")
	release_button.connect("toggled", self, "_on_release_button_toggled")
	boost_dir.connect("data_changed", self, "_on_bomb_button_toggled", [null])
#	end_bomb_button.connect("toggled", self, "_on_bomb_button_toggled")

func _on_bomb_button_toggled(_on):
	emit_signal("data_changed")

func _on_release_button_toggled(on):
	boost_dir.visible = on
	if on:
		store_button.set_pressed_no_signal(false)

func _on_store_button_toggled(on):
	if on:
		release_button.set_pressed_no_signal(false)
	if on:
		boost_dir.hide()

func show_options():
	bomb_button.hide()
	pull_button.hide()
	detach_button.hide()
	boost_dir.hide()
	release_button.hide()
	store_button.hide()
	store_button.set_pressed_no_signal(false)
	bomb_button.set_pressed_no_signal(false)
	pull_button.set_pressed_no_signal(fighter.pulling)
	detach_button.set_pressed_no_signal(false)
	release_button.set_pressed_no_signal(false)
	boost_dir.set_facing(fighter.get_opponent_dir())
	boost_dir.limit_angle = fighter.combo_count <= 0
	if fighter.momentum_stores > 0:
		release_button.show()
#	if (fighter.momentum_stores < 3 and !fighter.boosted_during_combo) or fighter.infinite_resources:
#		store_button.show()

	if fighter.bomb_thrown:
		bomb_button.show()
	
	var obj = fighter.obj_from_name(fighter.grappling_hook_projectile)
	if obj and obj.is_locked:
		pull_button.show()
	if obj:
		detach_button.show()

func update_selected_move(move_state):
	.update_selected_move(move_state)
	release_button.disabled = false
	if move_state is CharacterState:
		if move_state.type == CharacterState.ActionType.Defense \
		or move_state.type == CharacterState.ActionType.Movement:
			boost_dir.hide()
			release_button.set_pressed_no_signal(false)
			release_button.disabled = true
	elif move_state == null:
		boost_dir.hide()
		release_button.set_pressed_no_signal(false)
		release_button.disabled = true
func get_extra():
	var extra = {
		"explode": bomb_button.pressed,
		"pull": pull_button.pressed,
		"detach": detach_button.pressed,
#		"store": store_button.pressed,
		"release": release_button.pressed,
		"release_dir": boost_dir.get_data(),
	}
	return extra

func reset():
	bomb_button.set_pressed_no_signal(false)
	release_button.set_pressed_no_signal(false)
	store_button.set_pressed_no_signal(false)
