extends RobotState

const DAMAGE_PER_BAR = 75
const COMBO_DAMAGE_PER_BAR = 30
const MIN_DAMAGE_PER_BAR = 20
const MIN_COMBO_DAMAGE_PER_BAR = 20
const MIN_DAMAGE = 150
const MIN_COMBO_DAMAGE = 150

onready var hitbox = $Hitbox

func _enter():
	hitbox.damage = MIN_DAMAGE + DAMAGE_PER_BAR * host.kill_process_super_level
	hitbox.damage_in_combo = MIN_COMBO_DAMAGE + COMBO_DAMAGE_PER_BAR * host.kill_process_super_level
	hitbox.minimum_damage = (MIN_DAMAGE_PER_BAR * host.kill_process_super_level) if host.combo_count <= 0 else MIN_COMBO_DAMAGE_PER_BAR * host.kill_process_super_level
#	print("damage: ", hitbox.damage)
#	print("combo damage: ", hitbox.damage_in_combo)
#	print("min damage: ", hitbox.minimum_damage)
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, 50, 30 / 60.0)
	host.start_invulnerability()
	host.super_armor_installed = true
