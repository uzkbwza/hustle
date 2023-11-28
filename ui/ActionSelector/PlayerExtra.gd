extends HBoxContainer

signal data_changed()

class_name PlayerExtra

var fighter: Fighter
var player_id
var selected_move
var can_feint = true

func _ready():
	connect("data_changed", self, "on_data_changed")

func on_data_changed():
	pass

func set_fighter(fighter: Fighter):
	self.fighter = fighter
	player_id = fighter.id

func get_extra():
	return {}

func show_options():
	return

func reset():
	selected_move = null
	pass

func update_selected_move(move_state):
	can_feint = true
	selected_move = move_state
	pass
