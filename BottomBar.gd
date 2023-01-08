extends VBoxContainer

func _ready():
	$"%P1ActionButtons".connect("visibility_changed", self, "_on_action_buttons_visibility_changed")
	$"%P2ActionButtons".connect("visibility_changed", self, "_on_action_buttons_visibility_changed")
	$"%P1ActionButtons".opposite_buttons = $"%P2ActionButtons"
	$"%P2ActionButtons".opposite_buttons = $"%P1ActionButtons"

func _on_action_buttons_visibility_changed():
	if !$"%P1ActionButtons".visible and !$"%P2ActionButtons".visible:
		$"%OptionsBarContainer".hide()
		$"%PredictionSettingsOpenButton".hide()
	else:
		$"%OptionsBarContainer".show()
		if !$"%OptionsBar".visible:
			$"%PredictionSettingsOpenButton".show()
		else:
			$"%PredictionSettingsOpenButton".hide()
