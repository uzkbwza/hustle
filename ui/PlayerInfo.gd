extends Control

class_name PlayerInfo

var fighter: Fighter
var player_id = 1

func set_fighter(fighter):
	self.fighter = fighter
	player_id = fighter.id
