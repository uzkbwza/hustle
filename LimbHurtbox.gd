tool

extends CollisionBox

class_name LimbHurtbox

export var _c_Frame_Data = 0
export var start_tick = 0
export var active_ticks = 0
export var endless = false

var active = false

func _ready():
	z_index = 999

func can_draw_box():
	if Global.get("show_hitboxes"):
		return (active and Global.show_hitboxes)
	else:
		return .can_draw_box()
