extends Control

func _ready():
	UIManager.register_menu(self, [
		$"%ButtonContainer",
		$"%SingleplayerButton",
		$"%MultiplayerButton",
		$"%CustomizeButton",
		$"%ReplayButton",
		$"%OptionsButton",
		$"%QuitProgramButton",
		$"%WorkshopUploader",
		$"%ModListButtonContainer",
		$"%RoadmapContainer",
		$"%RoadmapButton",
		$"%AnnouncementContainer",
	])
