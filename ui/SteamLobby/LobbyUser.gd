extends Panel

signal challenge_pressed()
signal avatar_loaded()

var member

func _ready():
	Steam.connect("avatar_loaded", self, "_loaded_Avatar")
	$"%ChallengeButton".connect("pressed", self, "on_challenge_pressed")

func init(member):
#	if $"%AvatarIcon".texture == null:
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, member.steam_id)
	$"%Username".text = member.steam_name
	self.member = member
	$"%OwnerIcon".visible = false
	$"%ChallengeButton".hide()
	if SteamYomi.STEAM_ID != member.steam_id:
		$"%ChallengeButton".show()
	if Steam.getLobbyOwner(SteamLobby.LOBBY_ID) == member.steam_id:
		$"%OwnerIcon".visible = true
	var status = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, member.steam_id, "status")
	if status != "idle":
		$"%ChallengeButton".disabled = true
		$"%ChallengeButton".text = status
		if status == "fighting":
			$"%ChallengeButton".text = "fighting " + Steam.getFriendPersonaName(int(Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, member.steam_id, "opponent_id")))
	
#func _process(_delta):
#	$"%ChallengeButton".disabled = true
#	$"%Username".modulate = Color.white
#	if member:
#		if member.steam_id in SteamLobby.CLIENT_TICKETS and SteamLobby.CLIENT_TICKETS[member.steam_id].authenticated:
#		var m = SteamLobby.get_lobby_member(member.steam_id)
#			$"%Username".modulate = Color.green
#			$"%ChallengeButton".disabled = false
#		if SteamLobby.has_supporter_pack(member.steam_id):
#			$"%Username".modulate = Color.blue

func update_avatar():
	Steam.getPlayerAvatar(Steam.AVATAR_MEDIUM, member.steam_id)

func on_challenge_pressed():
	if member:
		emit_signal("challenge_pressed")
		SteamLobby.challenge_user(member)

func _loaded_Avatar(id: int, size: int, buffer: PoolByteArray) -> void:
	if id != member.steam_id:
		return
	print("Avatar for user: "+str(id))
	print("Size: "+str(size))
	# Create the image and texture for loading
	var AVATAR = Image.new()
	var AVATAR_TEXTURE: ImageTexture = ImageTexture.new()
	AVATAR.create_from_data(size, size, false, Image.FORMAT_RGBA8, buffer)
	# Apply it to the texture
	AVATAR_TEXTURE.create_from_image(AVATAR)
	# Set it
	$"%AvatarIcon".set_texture(AVATAR_TEXTURE)
	emit_signal("avatar_loaded")
