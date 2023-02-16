extends PlayerExtra

onready var bomb_button = $"%BombButton"
onready var pull_button = $"%PullButton"
#onready var end_bomb_button = $"%EndbombButton"
onready var detach_button = $"%DetachButton"

func _ready():
	bomb_button.connect("toggled", self, "_on_bomb_button_toggled")
	pull_button.connect("toggled", self, "_on_bomb_button_toggled")
	detach_button.connect("toggled", self, "_on_bomb_button_toggled")
#	end_bomb_button.connect("toggled", self, "_on_bomb_button_toggled")

func _on_bomb_button_toggled(_on):
	emit_signal("data_changed")

func show_options():
	bomb_button.hide()
	pull_button.hide()
	detach_button.hide()
	bomb_button.set_pressed_no_signal(false)
	pull_button.set_pressed_no_signal(fighter.pulling)
	detach_button.set_pressed_no_signal(false)

	if fighter.bomb_thrown:
		bomb_button.show()
	
	var obj = fighter.obj_from_name(fighter.grappling_hook_projectile)
	if obj and obj.is_locked:
		pull_button.show()
	if obj:
		detach_button.show()

func get_extra():
	var extra = {
		"explode": bomb_button.pressed,
		"pull": pull_button.pressed,
		"detach": detach_button.pressed
	}
	return extra

func reset():
	bomb_button.set_pressed_no_signal(false)
