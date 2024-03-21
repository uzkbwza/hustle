extends Panel

signal challenge_pressed()
signal avatar_loaded()

#const MEMBER_MIN_SIZE = 30
#const OWNER_MIN_SIZE = 44
onready var owner_actions = $OwnerActions

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
	if SteamHustle.STEAM_ID != member.steam_id:
		$"%ChallengeButton".show()
	if Steam.getLobbyOwner(SteamLobby.LOBBY_ID) == member.steam_id:
		$"%OwnerIcon".visible = true
	var status = Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, member.steam_id, "status")
	if status != "idle":
		$"%ChallengeButton".disabled = true
		$"%ChallengeButton".text = status
		if status == "fighting":
			$"%ChallengeButton".text = "fighting " + Steam.getFriendPersonaName(int(Steam.getLobbyMemberData(SteamLobby.LOBBY_ID, member.steam_id, "opponent_id")))

#	var lobby_owner = SteamLobby.am_i_lobby_owner()
#	rect_min_size.y = MEMBER_MIN_SIZE if !lobby_owner else OWNER_MIN_SIZE
#	owner_actions.visible = lobby_owner

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
