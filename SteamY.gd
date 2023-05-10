extends Node

const FX_IDS = [76561198255503675, 76561198166940679]
const FX_NAMES = ["ivy sly", "graf"]

signal started

var IS_ONLINE: bool
var IS_OWNED: bool

var STEAM_ID: int
var STEAM_NAME: String = ""

var APP_ID

var STARTED = false

var WORKSHOP_ENABLED = true

func _enter_tree():
	if "steam" in Global.VERSION:
		_initialize_steam()
	
func _initialize_steam():
	Steam.connect("current_stats_received", self, "_on_current_stats_received")

	STARTED = true
	var INIT: Dictionary = Steam.steamInit()
	print("Did steam initialize?: " + str(INIT))
	
	if INIT['status'] != 1:
		print("Failed to initialize Steam. " + str(INIT['verbal']))
	
	APP_ID = Steam.getAppID()
	IS_ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	IS_OWNED = Steam.isSubscribed()
	Steam.requestCurrentStats()
	emit_signal("started")
	
func _process(_delta):
	if STARTED:
		Steam.run_callbacks()

func record_winner(winner):
	if !Network.multiplayer_active:
		return
	if !SteamHustle.STARTED:
		return
	if ReplayManager.playback or ReplayManager.replaying_ingame:
		return
	var is_me = winner == Network.player_id
	var draw = winner == 0
	if SteamLobby.SPECTATING:
		return
	if draw:
		print("draw game :|")
		incr_stat("num_draws")
		unlock_achievement("ACH_DRAW_GAME")
	elif is_me:
		print("you won!:)")
		incr_stat("num_wins")
		unlock_achievement("ACH_WIN_ONCE")
		var num_wins = Steam.getStatInt("num_wins")
		if num_wins >= 10:
			unlock_achievement("ACH_WIN_10_TIMES")
		if num_wins >= 50:
			unlock_achievement("ACH_WIN_50_TIMES")
	else:
		print("you lost! :(")
		incr_stat("num_losses")
		unlock_achievement("ACH_LOSE_ONCE")
	incr_stat("num_matches")

func print_all_achievements():
	if !STARTED:
		return
	for i in range(Steam.getNumAchievements()):
		var ach = Steam.getAchievementName(i)
		print(ach + ": " + str(Steam.getAchievement(ach)["achieved"]))
#		Steam.clearAchievement(ach)

func incr_stat(stat_name: String):
	if !STARTED:
		return
	var stat_count = Steam.getStatInt(stat_name)
	if stat_count is int:
		set_stat(stat_name, stat_count + 1)

func set_stat(stat_name: String, value):
	if !STARTED:
		return
	print("setting stat " + stat_name + " to value " + str(value))
	if value is int:
		Steam.setStatInt(stat_name, value)
	Steam.storeStats()
	
func unlock_achievement(achievement_name: String):
	if !STARTED:
		return
	if ReplayManager.playback or is_instance_valid(Global.current_game) and Global.current_game.is_in_replay:
		return
	if SteamLobby.SPECTATING:
		return
	print("unlocked achievement: " + achievement_name)
	Steam.setAchievement(achievement_name)
	Steam.storeStats()

func has_supporter_pack(steam_id):
	return true

func _on_current_stats_received(game_id: int, result: int, user_id: int):
	if result == 1:
		print("retrieved user stats")
	else:
		print("could not retrieve stats from steam")
