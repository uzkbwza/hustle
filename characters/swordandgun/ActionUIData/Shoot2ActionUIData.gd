extends ActionUIData
onready var di_label = $Direction/Control/Control/Label2

func fighter_update():
	di_label.rect_position.x = abs(di_label.rect_position.x) * -1 if fighter.id == 1 else 1
