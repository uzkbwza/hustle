tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("RabidHolePuncher", "res://addons/rabidholepuncher/RabidHolePuncher.tscn")


func _exit_tree() -> void:
	remove_autoload_singleton("RabidHolePuncher")
