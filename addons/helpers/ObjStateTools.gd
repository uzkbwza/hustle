tool

extends Control

#func load_state_data(node):
#	$"%AnimationEditor".load_animation_data(node)
func load_node(node):
	$"%AnimationEditor".load_node(node, false)
