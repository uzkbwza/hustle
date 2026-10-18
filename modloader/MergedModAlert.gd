extends Window



func _ready():
	$"%OkayButton".connect("pressed", self, "queue_free")



func add_mod_name(text):
	var new_label = Label.new()
	new_label.text = "- " + text
	$"%List".add_child(new_label)
	if $"%List".get_child_count() == 2:
		$"%LabelTop".text = "The following mods have been disabled, as their functionality is now present in the base game."
		$"%LabelBottom".text = "To disable this popup, please uninstall these mod."
