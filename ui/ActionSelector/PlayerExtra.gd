extends HBoxContainer

signal data_changed()

class_name PlayerExtra

var fighter: Fighter
var player_id

func set_fighter(fighter: Fighter):
	self.fighter = fighter
	player_id = fighter.id

func get_extra():
	return {}

func show_options():
	return

func reset():
	pass
