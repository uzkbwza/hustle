extends ActionUIData
onready var di_label = $Direction/Control/Control/Label2
onready var direction = $Direction
onready var activate_temporal = $ActivateTemporal

func fighter_update():
	di_label.rect_position.x = abs(di_label.rect_position.x) * -1 if fighter.id == 1 else 1
	activate_temporal.visible = fighter.obj_from_name(fighter.temporal_round) != null
func get_data():
	return {
		"x": direction.get_data().x,
		"y": direction.get_data().y,
		"ActivateTemporal": activate_temporal.get_data(),
		"holster": true,
	}
