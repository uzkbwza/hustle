extends Node

func _init(modLoader = ModLoader):
	modLoader.installScriptExtension("res://SoupModOptions/MLMainHook.gd")
	modLoader.installScriptExtension("res://SoupModOptions/UIHook.gd")

func _ready():
	pass
