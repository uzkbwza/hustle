extends Panel

signal spectate_requested(player)

var p1
var p2

func init(member1, member2):
	$"%P1Username".text = member1.steam_name
	$"%P2Username".text = member2.steam_name

	$"%P1Character".text = member1.character
	$"%P2Character".text = member2.character
	p1 = member1
	p2 = member2

func _ready():
	$"%SpectateButton".connect("pressed", self, "_on_spectate_button_pressed")

func _on_spectate_button_pressed():
	randomize()
	emit_signal("spectate_requested", p1 if randi() % 2 == 0 else p2)
