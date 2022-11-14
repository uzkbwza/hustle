extends ObjectState

var num_hitboxes
var dir_x
var dir_y
onready var hitboxes = get_children()

func _ready():
	num_hitboxes = get_child_count()

func _frame_0():
	host.set_pos(data["x"], data["y"])

func _frame_5():
	terminate_hitboxes()
	host.sprite.hide()
	host.stop_particles()
	host.disabled = true
