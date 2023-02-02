extends RobotState

const DAMAGE_PER_BAR = 85
const COMBO_DAMAGE_PER_BAR = 40
const MIN_DAMAGE_PER_BAR = 20
const MIN_COMBO_DAMAGE_PER_BAR = 20

onready var hitbox = $Hitbox

func _enter():
	hitbox.damage = DAMAGE_PER_BAR * host.kill_process_super_level
	hitbox.damage_in_combo = COMBO_DAMAGE_PER_BAR * host.kill_process_super_level
	hitbox.minimum_damage = (MIN_DAMAGE_PER_BAR * host.kill_process_super_level) if host.combo_count <= 0 else MIN_COMBO_DAMAGE_PER_BAR * host.kill_process_super_level
	var camera = host.get_camera()
	if camera:
		camera.bump(Vector2.UP, 50, 30 / 60.0)
