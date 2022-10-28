extends CanvasLayer

var game: Game

onready var p1_healthbar = $"%P1HealthBar"
onready var p2_healthbar = $"%P2HealthBar"

onready var p1_burst_meter = $"%P1BurstMeter"
onready var p2_burst_meter = $"%P2BurstMeter"

onready var p1_super_meter = $"%P1SuperMeter"
onready var p2_super_meter = $"%P2SuperMeter"

onready var p1_num_supers = $"%P1NumSupers"
onready var p2_num_supers = $"%P2NumSupers"


onready var p1_combo_counter = $"%P1ComboCounter"
onready var p2_combo_counter = $"%P2ComboCounter"

var p1
var p2

func _ready():
	hide()

func init(game):
	self.game = game
	show()
	$"%GameUI".show()
	p1 = game.get_player(1)
	p2 = game.get_player(2)
	$"%P1Portrait".texture = p1.character_portrait
	$"%P2Portrait".texture = p2.character_portrait
	p1_healthbar.max_value = p1.MAX_HEALTH
	p2_healthbar.max_value = p2.MAX_HEALTH
	p1_super_meter.max_value = p1.MAX_SUPER_METER
	p2_super_meter.max_value = p2.MAX_SUPER_METER
	p1_burst_meter.fighter = p1
	p2_burst_meter.fighter = p2
	pass

func _process(_delta):
	if is_instance_valid(game):
		p1_healthbar.value = max(p1.hp, 0)
		p2_healthbar.value = max(p2.hp, 0)
		p1_super_meter.value = p1.super_meter
		p2_super_meter.value = p2.super_meter
		p1_num_supers.text = str(p1.supers_available)
		p2_num_supers.text = str(p2.supers_available)
		p1_combo_counter.text = "" if p1.combo_count < 2 else str(p1.combo_count)
		p2_combo_counter.text = "" if p2.combo_count < 2 else str(p2.combo_count)
		$"%Timer".text = str(game.get_ticks_left())
