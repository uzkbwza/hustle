extends PlayerInfo

func _process(delta):
	$"%ArmorTexture".visible = fighter.armor_pips > 0

func set_fighter(fighter):
	.set_fighter(fighter)
	$"%PaddingLeft".visible = player_id == 2
	$"%PaddingRight".visible = player_id == 1
