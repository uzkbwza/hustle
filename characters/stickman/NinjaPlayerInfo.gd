extends PlayerInfo

onready var h_box_container = $"%HBoxContainer"

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var texture_rect_1 = $"%TextureRect1"
onready var texture_rect_2 = $"%TextureRect2"
onready var texture_rect_3 = $"%TextureRect3"
onready var label_1 = $"%Label1"
onready var label_2 = $"%Label2"
onready var label_3 = $"%Label3"

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
	if !is_instance_valid(fighter):
		return
	texture_rect_1.hide()
	texture_rect_2.hide()
	texture_rect_3.hide()
	if fighter.momentum_stores > 0:
		texture_rect_1.show()
	if fighter.momentum_stores > 1:
		texture_rect_2.show()
	if fighter.momentum_stores > 2:
		texture_rect_3.show()
#	if ReplayManager.playback:
#		label_1.hide()
#		label_2.hide()
#		label_3.hide()
#	else:
#		label_1.show()
#		label_2.show()
#		label_3.show()
	label_1.text = "%0.1f" % float(fighter.stored_speed_1)
	label_2.text = "%0.1f" % float(fighter.stored_speed_2)
	label_3.text = "%0.1f" % float(fighter.stored_speed_3)
