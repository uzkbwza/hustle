extends PlayerInfo

onready var h_box_container = $HBoxContainer

func set_fighter(fighter):
	.set_fighter(fighter)
	if player_id == 1:
		$HBoxContainer.alignment = BoxContainer.ALIGN_BEGIN
	else:
		$HBoxContainer.alignment = BoxContainer.ALIGN_END
		for i in range($HBoxContainer.get_child_count()):
			$HBoxContainer.get_child(i).visible = fighter.juke_pips > i
			$HBoxContainer.get_child(i).flip_h = true
			

func _process(delta):
	for i in range(h_box_container.get_child_count()):
		h_box_container.get_child(i).visible = fighter.juke_pips > i
