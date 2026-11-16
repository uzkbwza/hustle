extends "res://ui/UILayer.gd"

var noSteam = false

func _process(delta):
	$"%VersionLabel".text = "version " + Global.VERSION

func _ready():
	var ver = -1
	#if ("1.0." in Global.VERSION):
	#    ver = int(Global.VERSION.split("1.0.")[1][0])
	#if !(ver > 3 or ver == -1):
	#    noSteam = true
	#    $"%ButtonContainer".grow_horizontal = 2
