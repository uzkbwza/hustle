extends VBoxContainer

func _ready():
	$"%P1ActionButtons".connect("visibility_changed", self, "_on_action_buttons_visibility_changed")
	$"%P2ActionButtons".connect("visibility_changed", self, "_on_action_buttons_visibility_changed")


func _on_action_buttons_visibility_changed():
	if !$"%P1ActionButtons".visible and !$"%P2ActionButtons".visible:
		$"%OptionsBar".hide()
	else:
		$"%OptionsBar".show()
