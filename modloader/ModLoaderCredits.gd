extends Window

func _ready():
	$"%Close".connect("pressed", self, "_close_clicked")
	
#	print(self.get_path())
	hide()

func _close_clicked():
	hide()
