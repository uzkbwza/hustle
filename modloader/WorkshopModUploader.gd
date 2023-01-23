extends PanelContainer

var mod = null

func load_mod(mod):
	self.mod = mod

func _on_UploadButton_pressed():
	$"%Popup".popup_centered()
	print(mod)
