extends "res://ui/CSS/CharacterSelect.gd"

### Custom Character Loader ###
# the way this works: modders will use addCustomChar that will add their character's data to an array, queue its button creation and ONLY load the character's portrait.

# thanks to that, whenever a player clicks on a character button it will use the character's data to load its scene and all of the assets on the spot (if no .import
# folder is included with the character, the game will take some time to convert all of the .png and .wav files to their import formats).

# after a character gets loaded for the first time it remains loaded until the game is closed. (the data itself may get unloaded after changing menus but the assets remain loaded)

# as modloader can't extend global, Network will be used as a global object for now
var _Global = Network


# Character data vars #
var customCharNumber = 0

var charFolders = []
var charList = [] # will hold all of the data needed to load every character
var loadedChars = [] # will hold the name of the characters that are already loaded
var buttonsToLoad = [] # will hold the same data as charList, but is used only to load buttons. this data gets set on addCustomChar()

var charPortrait = {} # will hold the portrait textures to be shown on unloaded characters
var errorMessage = {} # will hold a list of missing files for any characters that don't load correctly

var loadThread # a thread that will be used to load characters so the game doesn't get completely stuck
var currentlyLoading = false # remains true while a character is loading, used to prevent weird shit from happening


# Button vars #
var rows = 1
var charPage = 0;
var buttons_x = 0;
var maxRows = 5;

var arrowSprites = [null, null]

onready var bttContainer = self.get_node("CharacterButtonContainer")
var btt_disableTimer = 0 # this is a countdown, whenever it's greater than 0 all of the buttons are disabled


# Finder maps and functions #
var name_to_folder = {}
var name_to_index = {} # "index" refers to the index of the character in the charList array
var hash_to_folder = {}

func dict_findKey(_dictionary, _value):
	for key in _dictionary.keys():
		if (_dictionary[key] == _value):
			return key
	return -1

func folder_to_name(_folder): # having the names as keys and the folders as values ensures that no character will get replaced when there's more than 1 in the same mod folder
	return dict_findKey(name_to_folder, _folder)

func folder_to_hash(_folder): # same here, there might be multiple .zip files that have the same mod folder name
	return dict_findKey(hash_to_folder, _folder)


# Label things #
var loadingLabel
var loadingText = ""
var retract_loaded = false # whenever this is true the loading label will start to dissapear after a few seconds...
var labelTimer = 0 # ...using this timer

var pageLabel
var searchBar

func loadingLabel_start():
	retract_loaded = false
	loadingLabel.percent_visible = 1

func loadingLabel_vanish():
	retract_loaded = true
	labelTimer = 0

func loadingLabel_stop():
	loadingLabel.percent_visible = 0
	retract_loaded = false


# These are fighter variables that are used both when a character is added and when a character is loaded #
# They represent the 'current' fighter that's trying to be added/loaded #
var curModFolder
var curFighter
var curBttName

func update_fighter_vars(_name, _charPath, _bttName):
	curModFolder = "res://" + _charPath.split("://")[1].split("/")[0]
	curFighter = str("F-" + folder_to_hash(curModFolder) + "__" + _name).validate_node_name() # the name set under the hood has some extra info (F-[mod hash]__[name])

	curBttName = _name
	if (_bttName != ""):
		curBttName = _bttName.substr(0, 10) # more than 10 letters makes the button bigger


# General mod vars #
var serverMods = []
var charPackages = {}
onready var clVersion = ModLoader.CL_VERSION

# Header vars #
var sample_header
var oggstr_header


## Character data functions ##

func addCustomChar(_name, _charPath, _bttName = ""):
	update_fighter_vars(_name, _charPath, _bttName)
	if !(curFighter in name_to_folder.keys()): # prevent duplicates
		buttonsToLoad.append([_name, _charPath, _bttName])
		charList.append([_name, _charPath, _bttName])
		name_to_folder[curFighter] = curModFolder
		name_to_index[curFighter] = len(charList) - 1

		charFolders.append(curModFolder)

func addCharButton(_name, _charPath, _bttName = ""):
	update_fighter_vars(_name, _charPath, _bttName)

	if (bttContainer.get_node_or_null(curFighter) == null): # this check is to prevent duplicate buttons
		customCharNumber += 1

		# adding a button row for every 10 characters
		if (_Global.default_chars + customCharNumber - 10 * (rows - 1) > 10):
			bttContainer.set_h_grow_direction(1)
			rows += 1
			updateButtonHeight(rows)
		
		# create the button
		var char_button = load("res://ui/CSS/CharacterButton.tscn").instance()
		bttContainer.add_child(char_button)
		char_button.text = curBttName
		char_button.name = curFighter
		
		# load placeholder portrait
		_importHolderPortrait(curModFolder, _charPath, curFighter)

		# move up player portraits if theres more than 5 buttons
		if (_Global.default_chars + customCharNumber > 5):
			self.get_node("HBoxContainer").set_position(Vector2(0, -50))

# the loadListChar function loads the character from the given index in the charList array.
# also acts as an issue catcher, returns an array of missing files (or an empty array if there aren't any)
# missing files can either be .png.import/.wav.import files or missing audio files in the .import folder, given that currently there's only support for .wav conversion
func loadListChar(index, hideName = false): # hide name parameter is for online, to not reveal the other player's choice
	currentlyLoading = true
	var _name = charList[index][0]
	var _charPath = charList[index][1]
	var _bttName = charList[index][2]

	update_fighter_vars(_name, _charPath, _bttName)

	if (curFighter in loadedChars):
		return []

	loadingLabel_start() # little message at the corner of the screen that shows up saying "Character Loaded"
	
	var displayName = curFighter if !hideName else "Opponent's Character"

	var miss = _createImportFiles(curModFolder, displayName, _charPath) # this function will return the missing files array, it also updates the loading percent
	
	loadingText = "Loading " + getCharName(displayName) + " scene..."

	# loading the scene. if there's missing files, the scene isn't loaded and a list shows up on screen
	# the scene is edited, the node name gets updated
	var char_scene
	if (miss == []):
		char_scene = load(_charPath).instance()
		char_scene.name = curFighter
	else:
		errorMessage[curFighter] = "ERROR - these files are missing:"
		for f in miss:
			errorMessage[curFighter] += "\n" + f
	
	ModLoader.saveScene(char_scene, _charPath)

	# update the button's character scene
	bttContainer.get_node(curFighter).character_scene = load(_charPath)
	
	if (miss != []):
		loadingLabel_stop()
		return miss

	loadedChars.append(curFighter)
	Global.name_paths[curFighter] = _charPath

	return miss


## Button functions ##

func getButtonHeight(_divisions):
	var h = 60
	if (_divisions > 5):
		_divisions = 5
	if (_divisions > 1):
		h = 76 / 2
		if (_divisions > 3):
			h = 140 / _divisions
	return h

func updateButtonHeight(_divisions):
	var height = getButtonHeight(_divisions)
	var btt_scene = load("res://ui/CSS/CharacterButton.tscn").instance()
	btt_scene.set_custom_minimum_size(Vector2(60, height))
	ModLoader.saveScene(btt_scene, "res://ui/CSS/CharacterButton.tscn")
	
	var r = self.get_node("CharacterButtonContainer")
	var btts = r.get_children()
	for b in btts:
		b.set_custom_minimum_size(Vector2(60, 0))
		b.set_size(Vector2(60, height))
	r.set_size(Vector2(300, height))

func async_loadButtonChar(button):
	var miss = loadListChar(name_to_index[button.name])
	_on_button_mouse_entered(button)
	
	if (miss == []):
		buffer_select(button)
	loadingText = getCharName(button.name) + " Loaded"
	loadingLabel_vanish()
	currentlyLoading = false

# this function encapsulates character selection, to be called either when a character finishes loading or when pressing a base character button
func buffer_select(button):
	var data = get_character_data(button)
	var display_data = get_display_data(button)
	display_character(current_player, display_data)
	selected_characters[current_player] = data
	
	if singleplayer and current_player == 1:
		current_player = 2
		$"%SelectingLabel".text = "P2 SELECT YOUR CHARACTER"
	else :
		for button in buttons:
			button.disabled = true
		if singleplayer:
			$"%GoButton".disabled = false
	if not singleplayer:
		Network.select_character(data, $"%P1Display".selected_style if current_player == 1 else $"%P2Display".selected_style)

# as of update 3.3, this function gets called on _process. hopefully in the future this can be added onto another init function
func createButtons():
	# in case there's no custom characters installed
	if (len(buttonsToLoad)) == 0:
		_Global.default_chars = len(bttContainer.get_children())
		return

	var prevBtts = bttContainer.get_children()
	var prevChars = []
	var prevCharNames = [] # to prevent duplicates

	for child in prevBtts:
		if (!isCustomChar(child.text) and !(child.text in prevCharNames)):
			prevChars.append([child.character_scene, child.text])
			prevCharNames.append(child.text)
		child.free()

	_Global.default_chars = len(prevChars) # only real way of actually knowing

	loadedChars = []
	buttons = []

	# re-add default buttons
	for charInfo in prevChars:
		var button = preload("res://ui/CSS/CharacterButton.tscn").instance()
		button.character_scene = charInfo[0]
		$"%CharacterButtonContainer".add_child(button)
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

		button.text = charInfo[1]
	
	# add custom character buttons
	customCharNumber = 0
	rows = 1
	for data in buttonsToLoad:
		addCharButton(data[0], data[1], data[2])
	
	# set button actions
	for button in bttContainer.get_children():
		buttons.append(button)
		if not button.is_connected("pressed", self, "_on_button_pressed"):
			button.connect("pressed", self, "_on_button_pressed", [button])
			button.connect("mouse_entered", self, "_on_button_mouse_entered", [button])


## Ready and Process ##

func _ready():
	var dir = Directory.new()

	# for retro compatibility reasons, copying PlayerInfo over from characters/ (5.0 onwards) to ui/ (4.10 and below)
	if (dir.file_exists("res://characters/PlayerInfo.tscn") && !dir.file_exists("res://ui/PlayerInfo.tscn")):
		var pi_scene = load("res://characters/PlayerInfo.tscn").instance()
		ModLoader.saveScene(pi_scene, "res://ui/PlayerInfo.tscn")

	# get all of the modsses
	_Global.css_instance = self
	self.visible = false
	hash_to_folder = {}
	serverMods = []
	Network.hash_to_folder = {}
	if (!dir.dir_exists("user://char_cache")):
		dir.make_dir("user://char_cache")
	charPackages = {}
	var caches = ModLoader._get_all_files("user://char_cache", "pck") # format: [mod name]-[author name]-[mod hash]-[game version].pck
	for zip in ModLoader._modZipFiles:
		var gdunzip = load("res://modloader/gdunzip/gdunzip.gd").new()
		gdunzip.load(zip)
		var folder = ""
		for modEntryPath in gdunzip.files:
			if (modEntryPath.find(".import") == -1):
				folder = "res://" + modEntryPath.rsplit("/")[0]
				break
		var hashy = ModLoader._hash_file(zip)
		hash_to_folder[hashy] = folder
		Network.hash_to_folder[hashy] = folder
		var md = ModLoader._readMetadata(folder + "/_metadata")
		if (md == null):
			continue
		var is_serverSided = true
		if md.has("client_side"):
			if md["client_side"]:
				is_serverSided = false
		if is_serverSided:
			serverMods.append(hashy)
		for f in caches:
			var fName = f.replace("user://char_cache/", "")
			if fName.find(md.name.validate_node_name()) == 0 && fName.find(md.author.validate_node_name()) != -1:
				if fName.find(hashy) == -1 || fName.find(clVersion.validate_node_name()) == -1:
					dir.remove(f)
				else:
					charPackages[md.name] = f

	var bttRow = self.get_node("CharacterButtonContainer")
	bttRow.margin_left = -305
	bttRow.margin_right = 305
	rows = 1
	bttRow.set_h_grow_direction(2)

	#get headers
	var h = File.new()
	h.open("res://cl_port/headers/sample.header", File.READ)
	sample_header = h.get_buffer(h.get_len())
	h.close()
	h.open("res://cl_port/headers/oggstr.header", File.READ)
	oggstr_header = h.get_buffer(h.get_len())
	h.close()
	loadingLabel = createLabel("Character Loaded", "Loaded", 0, 345)
	loadingLabel.percent_visible = 0

	pageLabel = createLabel("Page ", "PageLabel", 560, 345)
	
	searchBar = load("res://cl_port/searchbar.tscn").instance()

	self.add_child(searchBar)

	# page arrows
	var arrowName = ["left", "right"]
	var arrowPos = [8, 640 - 8]

	for i in 2:
		arrowSprites[i] = Sprite.new()
		arrowSprites[i].texture = textureGet("res://cl_port/visuals/arrow_" + arrowName[i] + ".png")
		self.add_child(arrowSprites[i])
		arrowSprites[i].position = Vector2(arrowPos[i], 263)

# variables to be used on _process
var updatedNetworkLists = false
var createdButtons = false

var buffer_go = false

func _process(delta):
	# new version code thing
#	Global.VERSION = _Global.ogVersion.split("Modded")[0] + "CL-" + clVersion

	# check if custom character buttons haven't been created yet and if they haven't then create them
	var makeButtons = false
	var curButtons = bttContainer.get_children()

	var isThereCustoms = false
	var bNames = []
	for b in curButtons:
		if isCustomChar(b.text):
			makeButtons = true
			break
		elif !(b.text in Global.name_paths.keys()):
			isThereCustoms = true
			break
	if (!isThereCustoms):
		makeButtons = true
	
	if (makeButtons):
		createButtons()
		createdButtons = true

	# move "Go & Quit buttons down when theres too many rows
	if (rows > 2):#6):
		var goBtt = get_node("GoButton")
		var quitBtt = get_node("QuitButton")

		goBtt.set_position(Vector2(260, 338))
		quitBtt.set_position(Vector2(336, 342))

		goBtt.set_size(Vector2(58, 19))
		quitBtt.set_size(Vector2(30, 12))
	
	# character buttons
	var btts = bttContainer.get_children()
	var visInd = 0
	var curPage = 0
	var pageNumber = getPageAmmount()

	for j in len(btts):
		var b = btts[j]
		if (!b.is_visible()):
			continue

		# disable chars that opponent doesnt have
		if (!net_isCharacterAvailable(b.name)):
			b.disabled = true

		# set buttons positions when theres more than 1 row (sorry for the bullshit formula)
		var searchFound = (b.text.to_lower().find(searchBar.text.to_lower()) != -1 or searchBar.text == "")
		if (rows > 1):
			if searchFound:
				var charNum = min(_Global.default_chars + customCharNumber - curPage * 50, 50)
				var pageRows = min(rows - 5 * curPage, 5)
				if (pageRows == 0):
					break
				var maxPerRow = int(1 + ceil(charNum / pageRows))
				if (charNum % pageRows == 0):
					maxPerRow -= 1
				var row = floor(visInd / maxPerRow)
				var col = visInd % maxPerRow
				var curRowLength = maxPerRow
				if row == pageRows - 1:
					curRowLength = charNum - (maxPerRow * (pageRows - 1))
				var bttWidth = 61
				var halfSize = (bttWidth * curRowLength) / 2
				b.set_position(Vector2(buttons_x + 640 * curPage + (305 + col * bttWidth - halfSize), (getButtonHeight(rows) + 1) * row))
			else:
				b.set_position(Vector2(-1000, -100))
		if searchFound:
			visInd += 1

		if (visInd >= 50):
			visInd = 0
			curPage += 1
	
	if (btt_disableTimer > 0):
		btt_disableTimer -= delta * 60
		btt_disableTimer = max(btt_disableTimer, 0)
	
	# manage pages when there's more than 50 characters
	if (pageNumber > 1):
		pageNumber = curPage + 1
		if (!searchBar.has_focus()):
			if Input.is_action_just_pressed("ui_right"):
				charPage += 1
			if Input.is_action_just_pressed("ui_left"):
				charPage -= 1
		if (charPage < 0):
			charPage = pageNumber - 1
			buttons_x = -640 * pageNumber
		if (charPage > pageNumber - 1):
			charPage = 0
			buttons_x = 640
		buttons_x += (-charPage * 640 - buttons_x) / 3 * delta * 60
		pageLabel.text = "Page " + str(charPage + 1) + "/" + str(pageNumber)

		arrowSprites[0].visible = true
		arrowSprites[1].visible = true
		pageLabel.visible = true
		searchBar.visible = true
	else:
		arrowSprites[0].visible = false
		arrowSprites[1].visible = false
		pageLabel.visible = false
		searchBar.visible = false
	
	$"%QuitButton".disabled = currentlyLoading

	# update network lists
	if !updatedNetworkLists:
		net_updateModLists()
		updatedNetworkLists = true

	# loading label thing, waits like 3 seconds to start dissapearing
	loadingLabel.text = loadingText

	if (retract_loaded):
		if labelTimer == 0:
			loadingLabel.percent_visible += delta * 3
		if (loadingLabel.percent_visible >= 1):
			labelTimer += delta
		if (labelTimer > 2):
			loadingLabel.percent_visible -= delta * 2
			if (loadingLabel.percent_visible - delta * 4 <= 0):
				retract_loaded = false
				loadingLabel.percent_visible = 0
	
	if _Global.isSteamGame:
		Network.multiplayer_host = Network.steam_isHost

	# this buffer go thing is done bc if the go() function is called inside of a thread the game doesn't load correctly
	if (buffer_go):
		if loadThread != null:
			loadThread.wait_to_finish()
		buffer_go = false
		go()

# managing clicks to the page arrows and click outside of the search bar
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			if event.position.y > 240 and event.position.y < 280:
				var pageChange = 0
				if event.position.x > 640 - 14:
					pageChange = 1
				elif event.position.x < 14:
					pageChange = -1
				if (pageChange != 0):
					charPage += pageChange
					btt_disableTimer = 20
					searchBar.release_focus()


## General helper functions ##

func getPageAmmount():
	return 1 + floor(rows / (maxRows + 1))

func textureGet(imagePath):
	var image = Image.new()
	var err = image.load(imagePath)
	if err != OK:
		return 0
	var tex = ImageTexture.new()
	tex.create_from_image(image, 0)
	return tex

func isCustomChar(_name):
	return _name.find("F-") == 0

func getCharName(_fullName):
	if (_fullName.find("__") != -1):
		return _fullName.split("__")[1]
	return _fullName

func retro_charName(_name):
	if (_name in name_to_index.keys()):
		return _name
	var realName = getCharName(_name)
	for k in name_to_index.keys():
		if getCharName(k) == realName:
			return k
	return name_to_index.keys()[0]

func createLabel(_text, _name, _x, _y, _from = self):
	var label = Label.new()
	label.text = _text
	label.name = _name
	label.set_position(Vector2(_x, _y))
	_from.add_child(label)
	return label
	

## Overwrites ##

func _on_button_pressed(button):
	if btt_disableTimer > 0 or currentlyLoading:
		button.set_pressed_no_signal(false)
		return
	var miss = []
	if (isCustomChar(button.name)):
		loadThread = Thread.new()
		loadThread.start(self, "async_loadButtonChar", button)
	else:
		buffer_select(button)

	for button in buttons:
		button.set_pressed_no_signal(false)

func get_display_data(button):
	var data = {}
	if !isCustomChar(button.name) or (button.name in loadedChars):
		var scene = button.character_scene.instance()
		data["name"] = scene.name
		data["portrait"] = scene.character_portrait
		scene.free()
	else:
		data["name"] = button.name
		data["portrait"] = charPortrait[button.name]

		if (button.name in errorMessage.keys()):
			data["name"] = errorMessage[button.name]
	return data

func _on_network_match_locked_in(match_data):
	network_match_data = match_data
	if SteamLobby.LOBBY_ID != 0 and SteamLobby.OPPONENT_ID != 0:
		Steam.setLobbyMemberData(SteamLobby.LOBBY_ID, "character", match_data.selected_characters[SteamLobby.PLAYER_SIDE].name)
	if (loadThread != null):
		loadThread.wait_to_finish()
	loadThread = Thread.new()
	loadThread.start(self, "net_async_loadOtherChar")


## Custom network things ##

var enable_online_go = false
func net_async_loadOtherChar():
	print("there should be 2 of these")
	for c in selected_characters.values():
		if (c != null):
			if (isCustomChar(c.name)):
				loadListChar(name_to_index[c.name], true)
				loadingText = "Character Loaded"
				loadingLabel_vanish()
				currentlyLoading = false

	if !Network.multiplayer_host:
		net_sendPacket("go_button_activate")
		#Network.rpc_("go_button_activate")
	else:
		$"%GoButton".show()
		$"%GoButton".connect("pressed", self, "net_startMatch")
		if enable_online_go:
			$"%GoButton".disabled = false
			enable_online_go = false

func net_startMatch():
	buffer_go = true
	net_sendPacket("go_button_pressed")
	#Network.rpc_("go_button_pressed")

func net_updateModLists():
	Network.normal_mods = []
	Network.char_mods = []
	var i = 0
	for mod in ModLoader.active_mods:
		if hash_to_folder[mod[0]] in charFolders:
			Network.char_mods.append(mod[0])
		else:
			if (mod[0] in serverMods):
				Network.normal_mods.append(mod[0])
		i += 1

# this function gets called on main.gd
func net_loadReplayChars(_replayChars):
	var rc = _replayChars
	if rc != []:
		if (isCustomChar(rc[0])):
			loadListChar(name_to_index[retro_charName(rc[0])])
		if (isCustomChar(rc[1])):
			loadListChar(name_to_index[retro_charName(rc[1])])

func net_isCharacterAvailable(_charName):
	if (!singleplayer and isCustomChar(_charName) and (Network.player1_chars != [] or Network.player2_chars != [])):
		var foundIt1 = false
		var foundIt2 = false
		for m in Network.player1_chars:
			if (hash_to_folder.has(m)):
				if (name_to_folder[_charName] == hash_to_folder[m]):
					foundIt1 = true
					break
		for m in Network.player2_chars:
			if (hash_to_folder.has(m)):
				if (name_to_folder[_charName] == hash_to_folder[m]):
					foundIt2 = true
					break
		if (!foundIt1 or !foundIt2):
			return false
	return true

func net_sendPacket(name):
	if (_Global.isSteamGame):
		var fullData = {"_packetName" : name}
		SteamLobby._send_P2P_Packet(SteamLobby.OPPONENT_ID, fullData)
	else:
		Network.rpc_(name)

## Import conversion things ##

# helper functions for hex values
func writeHex(_file, _hexList = [], _bits = 64):
	for h in _hexList:
		if _bits == 8:
			_file.store_8(h)
		elif _bits == 16:
			_file.store_8(h)
		elif _bits == 32:
			_file.store_16(h)
		else:
			_file.store_64(h)

var hexVal = { # yeah idk
	"0" : 0,
	"1" : 1,
	"2" : 2,
	"3" : 3,
	"4" : 4,
	"5" : 5,
	"6" : 6,
	"7" : 7,
	"8" : 8,
	"9" : 9,
	"A" : 10,
	"B" : 11,
	"C" : 12,
	"D" : 13,
	"E" : 14,
	"F" : 15
}

func writeStringHex(_file, _stringList = []):
	for s in _stringList:
		if (s[0] == "0" and s[1] == "x"):
			var num = _stringList.replace("0x", "").replace(" ", "")
			for i in len(num) / 2:
				var result = hexVal[num[i * 2]] * 16 + hexVal[num[i * 2 + 1]]
				_file.store_8(result)
		else:
			_file.store_string(s)

# save stex function taken from the aa_import plugin by lifelike
func save_stex(image, save_path):
	var tmppng = "%s-tmp.png" % [save_path]
	image.save_png(tmppng)
	var pngf = File.new()
	pngf.open(tmppng, File.READ)
	var pnglen = pngf.get_len()
	var pngdata = pngf.get_buffer(pnglen)
	pngf.close()
	Directory.new().remove(tmppng)
	var stexf = File.new()
	stexf.open(save_path, File.WRITE)
	stexf.store_string("GDST")
	stexf.store_32(image.get_width())
	stexf.store_32(image.get_height())
	stexf.store_32(0)
	stexf.store_32(0x07100000) # data format
	stexf.store_32(1) # nr mipmaps
	stexf.store_32(pnglen + 6)
	stexf.store_string("PNG ")
	stexf.store_buffer(pngdata)
	stexf.close()

# save sample function made specifically for char loader
func save_sample(og_file, dest_file):

	## READING ##
	var f = File.new()
	f.open(og_file, File.READ)

	# read channel number and sample rate
	f.seek(0x00000016)
	var channels = f.get_8()
	f.seek(0x00000018)
	var sRate = f.get_32()
	
	# get to the data header position (some files have text before the data header)
	var ind = 40
	f.seek(ind - 4)
	var data32 = f.get_32()
	while data32 != 1635017060: # this number is the word "data" spelled in hex
		ind += 1
		f.seek(ind - 4)
		data32 = f.get_32()

	# get data chunk size
	f.seek(ind)
	var leng = f.get_32()
	
	# read the data
	f.seek(ind + 4)
	var fullWav = f.get_buffer(leng)

	leng = leng * 2 # this will be needed for later, some wav files only work when having a duplicate ammount of data (maybe it has to do with an odd number?)
	
	f.close()

	## WRITING ##
	f.open(dest_file, File.WRITE)

	# header
	f.store_buffer(sample_header)

	# MAGIC NUMBER TIME (I honestly have no idea why this needs to exist but without it the thing breaks so)
	# 02 -> is a mono file with 44100 sample rate
	# 03 -> is a stereo file with 44100 sample rate / is a mono file with a sample rate that isn't 44100
	# 04 -> is a stereo file with a sample rate that isn't 44100
	var numb = channels + 1
	if (sRate != 44100):
		numb += 1
	
	# store it on file
	writeHex(f, [0x00, numb, 0x00, 0x00], 8)
	
	# something idk
	writeHex(f, [34084860461568])
	f.store_8(0)
	
	# store the actual data
	f.store_32(leng)
	f.store_buffer(fullWav)

	# filling the whole duplicate chunk of data with 0x00
	var wrote = 0
	var zeroChunk = 8 # doing loops in chunks of 8 bytes to do less loops
	for i in floor(leng/2 / zeroChunk): 
		writeHex(f, [0x00], 8 * zeroChunk)
		wrote += 8
	for i in leng/2 - wrote: # fill in the rest of the 0s
		writeHex(f, [0x00], 8)
	
	# standard bottomer(?)
	writeHex(f, [0x03, 0x00, 0x00, 0x00], 8)
	writeHex(f, [0x03, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00], 8)
	
	# storing some identifiers and their values, idk why they're so specific.
	if (sRate != 44100):
		writeHex(f, [0x07, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00], 8)
		f.store_32(sRate)
	
	if (channels == 2):
		writeHex(f, [0x08, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00], 8)
		writeHex(f, [0x01, 0x00, 0x00, 0x00], 8)
	
	# CLOSE!
	f.store_string("RSRC")
	f.close()

# save oggstr function by Supersonic#2382
func save_oggstr(og_file, dest_file):
	var f = File.new()
	f.open(og_file, File.READ)
	var _len = f.get_len()
	var buf = f.get_buffer(_len)
	f.close()

	f.open(dest_file, File.WRITE)
	f.store_buffer(oggstr_header)
	# Currently looping and loop_offset are part of the header and i'm not sure how exactly they're stored there.

	# This is probably not necessary anymore- i did this when i was confused at why it wasn't working
	# then it hit me- it was trying to save as stex at the time, and wasn't running this func at all
	var len_bytes = [_len&255,(_len&(65535))>>8,(_len&(16777216))>>16,_len>>24] 
	writeHex(f,len_bytes,8)
	f.store_buffer(buf)
	f.store_string("RSRC")
	f.close()
	

# this function finds the portrait image path inside a .tscn file
func _importHolderPortrait(folder, scenePath, charName):
	var sc

	var f = File.new()
	f.open(scenePath, File.READ)
	var portPath = "res://characters/stickman/sprites/idle.png"
	var content = f.get_as_text()
	var portSource = 0
	var portSourceInd = content.find("character_portrait = ExtResource")

	if (portSourceInd != -1):
		var startNumInd = portSourceInd + 33
		portSource = int(content.substr(startNumInd, content.find(" )", portSourceInd) - startNumInd))
	
		f.seek(0)
		var ids = ""
		var line = ""
		

		while ids != str(portSource) + "]":
			line = f.get_line().replace("\n", "").replace("\r", "")
			ids = line.split("id=")[1]
			if f.eof_reached():
				sc = load("res://characters/BaseChar.tscn").instance()
				sc.name = "Error\ncharacter scene must be unedited"
				ModLoader.saveScene(sc, scenePath)

				return scenePath
				break
	
		portPath = line.split("=")[1].split(" typ")[0].replace("\"", "")

	f.close()
	charPortrait[charName] = textureGet(portPath)

# iterates through all paths listed in a .tscn file and checks if they exist
func _validateScene(scenePath, _modFolder):
	var f = File.new()
	var dir = Directory.new()
	f.open(scenePath, File.READ)
	var hintMsg = []
	var missing = []
	var line = "]"
	var sceneName = scenePath.replace(scenePath.get_base_dir() + "/", "")

	var otherScenes = [] # if any of these resources is a scene then it should also validate its files. any scene found on this scene will be queued and then validated
	while line.find("]") != -1:
		line = f.get_line().replace("\n", "").replace("\r", "")
		if line == "":
			break
		if (line.find("gd_scene") == 1): # this is the first line of the tscn file
			f.get_line() # skip the next line, that should be empty
			continue
		var resPath = line.split("path=\"")[1].split("\" type=")[0]
		loadingText = "Validating"+ sceneName +"..."
		if !dir.file_exists(resPath):
			if !ResourceLoader.exists(resPath):
				var fullMiss = resPath
				missing.append(fullMiss)
				if (resPath.find(_modFolder) == -1):
					hintMsg = [
						"## NOTICE: all of the following paths are being read from \"" + sceneName + "\".",
						"## godot automatically generates all of these paths depending on their location in the FileSystem tab."
					]
		elif resPath.find(".tscn") != -1:
			otherScenes.append(resPath) # queue scene
	
	for s in otherScenes: # validate queued scenes
		missing += _validateScene(s, _modFolder)
	return hintMsg + missing

# opening and loading packages, used for the .import file conversions. also adds a temp folder to be deleted afterwards
var p
func _import_start():
	p = PCKPacker.new()
	p.pck_start("user://imagepack.pck")

	var dir = Directory.new()
	dir.make_dir("user://mod_temp")

func _import_copy(destFile):
	var dir = Directory.new()
	dir.copy("user://imagepack.pck", destFile)

func _import_end():
	p.flush()

	ProjectSettings.load_resource_pack("user://imagepack.pck")

func _createImportFiles(folder, _charName, _charPath): # returns an array of missing files
	var dir = Directory.new()

	# if mod cache exists, just import it and return
	var md = ModLoader._readMetadata(folder + "/_metadata")
	var modName = md.name
	if (modName in charPackages.keys()):
		loadingText = "Loading Cached Package"
		ProjectSettings.load_resource_pack(charPackages[modName])
		return []
	
	_import_start()

	var assets = ModLoader._get_all_files(folder, "png") + ModLoader._get_all_files(folder, "wav") + ModLoader._get_all_files(folder, "ogg")
	var delList = [] # list of all the temp files that should be deleted once the conversion is done
	
	var missingFiles = []

	for i in len(assets):
		if (!dir.file_exists(assets[i] + ".import")):
			missingFiles.append(assets[i] + ".import")
		else:
			loadingText = "Loading " + getCharName(_charName) + " - " + str(int((float(i) / len(assets)) * 100)) + "%"
			
			# read the destination .stex/.sample path from the .import file corresponding to the asset (it's basically a .ini file)
			var c = ConfigFile.new()
			c.load(assets[i] + ".import")
			var dest = c.get_value("remap", "path")

			if (!dir.file_exists(dest)):
				# save the conversion to the temp folder
				var tmpFile = "user://mod_temp/" + dest.split("://.import/")[1]
				if (dest.ends_with(".stex")):
					var img = Image.new()
					img.load(assets[i])
					save_stex(img, tmpFile)
				elif (dest.ends_with(".oggstr")):
					save_oggstr(assets[i], tmpFile)
				else:
					save_sample(assets[i], tmpFile)
				
				# add it to the package
				p.add_file(dest, tmpFile)
				delList.append(tmpFile)
	
	# include every file inside the res://[mod name]/.import folder to the package (not the same as the .import folder at the root of the zip)
	if (dir.dir_exists(folder + "/.import")):
		var imports = ModLoader._get_all_files(folder)
		for f in imports:
			p.add_file("res://.import/" + f.split(".import/")[1], f)
	
	_import_end() # this will close the package and install it, leaving the .import folder files in their place

	# check if every .import folder file is present after the conversion
	var imports = ModLoader._get_all_files(folder, "import")
	for f in imports:
		if (dir.file_exists(f.replace(".import", ""))):
			var im = ConfigFile.new()
			im.load(f)
			var expected = im.get_value("remap", "path")
			if !dir.file_exists(expected):
				missingFiles.append(expected)
	
	for f in delList:
		dir.remove(f)
	dir.remove("user://mod_temp")
	
	missingFiles += _validateScene(_charPath, name_to_folder[curFighter])

	if (missingFiles == []):
		_import_copy("user://char_cache/" + modName.validate_node_name() + "-" + md.author.validate_node_name() + "-" + folder_to_hash(folder) + "-" + clVersion.validate_node_name() + ".pck") # will cache the asset package for faster load times on subsequent sessions

	return missingFiles

