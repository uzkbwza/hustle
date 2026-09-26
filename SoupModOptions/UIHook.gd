extends "res://ui/UILayer.gd"


func _on_quit_program_button_pressed():
	var ModOptions = get_tree().get_current_scene().get_node("ModOptions")
	ModOptions.menu._close_clicked() #should ensure settings save
	._on_quit_program_button_pressed()
