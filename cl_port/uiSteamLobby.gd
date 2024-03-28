extends "res://ui/SteamLobby/SteamLobby.gd"

var _Global = Network
var errorMsg = Label.new()

func _ready():
	add_child(errorMsg)
	errorMsg.set_position(Vector2(0, 345))
	errorMsg.text = ""
	_Global.steam_errorMsg = ""

func _process(delta):

	errorMsg.text = _Global.steam_errorMsg
	
	var css = _Global.css_instance
	if css != null:
		for game in $"%MatchList".get_children():
			#print("jesus")
			game.get_node("%P1Character").text = css.getCharName(game.p1.character)
			game.get_node("%P2Character").text = css.getCharName(game.p2.character)
			var cNames = css.name_to_index.keys()

			game.get_node("%SpectateButton").disabled = false
			
			if (!(game.p1.character in cNames) and css.isCustomChar(game.p1.character)) or (!(game.p2.character in cNames) and css.isCustomChar(game.p2.character)):
				game.get_node("%SpectateButton").disabled = true
