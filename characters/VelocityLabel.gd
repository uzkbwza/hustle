extends RichTextLabel

# var b = "text"

var fighter

func _ready():
	fighter = get_parent().get_parent()

func _process(delta):
	if is_instance_valid(fighter):
		visible = Global.show_extra_info and !fighter.is_ghost
		clear()
		var vel = fighter.get_vel()
		append_bbcode("[center][color=#%s]" % (fighter.P1_COLOR.to_html(false) if fighter.id == 1 else fighter.P2_COLOR.to_html(false)))
		append_bbcode("spd: %0.2f\n" % float(fighter.fixed.vec_len(vel.x, vel.y)))
#		append_bbcode("x: %s, y: %s" % [fighter.get_pos().x, fighter.get_pos().y])

	

func _input(event):
	if event is InputEventMouseMotion:
		if Global.mouse_world_position.distance_squared_to(fighter.get_hurtbox_center_float()) < Global.mouse_world_position.distance_squared_to(fighter.opponent.get_hurtbox_center_float()):
			fighter.opponent.velocity_label_container.z_index = 1023
			get_parent().z_index = 1024
