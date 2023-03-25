extends Node2D

onready var host = get_parent()
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Label.text = "P" + str(host.id)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var game = Global.current_game
	visible = game and game.game_paused and !host.disabled and Global.show_projectile_owners and !host.is_ghost
	update()

func _draw():
	if !host.disabled:
		var color = Color("ff7a81") if host.id == 2 else Color("aca2ff")
		var pos = to_local(host.get_hurtbox_center_float())
		var radius = max((host.hurtbox.width + host.hurtbox.height) / 2.0, 7.0)
#			draw_arc(to_local(host.get_hurtbox_center_float()), (host.hurtbox.width + host.hurtbox.height) / 2.0, 0, TAU, 32, Color.white, 3.0)
		draw_arc(pos, radius * 1.3 + (radius / 10.0) * Utils.wave(-1.0, 1.0, 4.0, 2.0 if host.id == 2 else 0), 0, TAU, 32, color, 2.0)
#		$Label.modulate = color
		$Label.rect_position = pos - $Label.rect_size / 2
		$Label.modulate = color.linear_interpolate(Color.white, Utils.wave(0.5, 1.0, 1.0))

		if Global.mouse_world_position.distance_to(host.get_hurtbox_center_float()) < max(32.0, radius):
			modulate.a = 1.0
		else:
			modulate.a = 0.15
