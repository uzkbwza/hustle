extends Control

class_name PlayerInfo

var fighter: Fighter
var player_id = 1

var under_healthbar = false

func set_fighter(fighter):
	self.fighter = fighter
	player_id = fighter.id

func on_position_changed(under_healthbar):
	self.under_healthbar = under_healthbar

func _process(delta):
	if fighter and !is_instance_valid(fighter):
		queue_free()
		return
