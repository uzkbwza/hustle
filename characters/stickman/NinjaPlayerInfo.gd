extends PlayerInfo

onready var h_box_container = $"%HBoxContainer"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var texture_rect_1 = $"%TextureRect1"
onready var texture_rect_2 = $"%TextureRect2"
onready var texture_rect_3 = $"%TextureRect3"

func set_fighter(fighter):
	.set_fighter(fighter)
	if fighter.id == 2:
		$"%HBoxContainer".alignment = BoxContainer.ALIGN_END
		$"%HBoxContainer".call_deferred("move_child", $"%TextureRect1", 2)
		$"%HBoxContainer".call_deferred("move_child", $"%TextureRect3", 0)



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	texture_rect_1.hide()
	texture_rect_2.hide()
	texture_rect_3.hide()
	if fighter.momentum_stores > 0:
		texture_rect_1.show()
	if fighter.momentum_stores > 1:
		texture_rect_2.show()
	if fighter.momentum_stores > 2:
		texture_rect_3.show()

	pass
