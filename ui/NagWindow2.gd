extends Window

const MOVE_SPEED = 0.15 * 60
var STEAM_URL = "https://store.steampowered.com/app/2212330/Your_Only_Move_Is_HUSTLE"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dir = Vector2(1, 1)

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	dir.x = 1 if randi() % 2 == 0 else -1
	dir.y = 1 if randi() % 2 == 0 else -1
	$"%ShowButton".connect("pressed", self, "queue_free")
	$"%StoreButton".connect("pressed", self, "_on_store_button_pressed")
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _on_LabelBlink_timeout():
	if $"%Title".modulate.a == 0.0:
		$"%Title".modulate.a = 1.0
	else:
		$"%Title".modulate.a = 0.0

func _on_store_button_pressed():
#	Steam.activateGameOverlayToStore(Custom.SUPPORTER_PACK)
	OS.shell_open(STEAM_URL)

func _process(delta):
	rect_position += MOVE_SPEED * dir * delta
	var viewport_size = get_viewport_rect().size
	if rect_global_position.x < 0:
		dir.x = -dir.x
		rect_global_position.x = 0
	if rect_global_position.y < 0:
		dir.y = -dir.y
		rect_global_position.y = 0
	if rect_global_position.x + rect_size.x > viewport_size.x:
		dir.x = -dir.x
		rect_global_position.x = viewport_size.x - rect_size.x
	if rect_global_position.y + rect_size.y > viewport_size.y:
		dir.y = -dir.y
		rect_global_position.y = viewport_size.y - rect_size.y
