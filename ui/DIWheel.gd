extends XYPlot

func _process(delta):
	panel.hint_tooltip = ""
	var data = get_data()
	if value_float.x == 0 and value_float.y == 0:
		panel.hint_tooltip = "Use this to change your knockback direction next time you're hit! \nStronger effect as the combo goes on."
