extends ObjectState

var dir_x
var dir_y

onready var hitbox = $Hitbox

func _ready():
	pass

func _frame_0():
	hitbox.damage = host.scale_damage(hitbox.damage)
	hitbox.damage_in_combo = host.scale_damage(hitbox.damage_in_combo)
	hitbox.minimum_damage = host.scale_damage(hitbox.minimum_damage)
	hitbox.hitstun_ticks = host.scale_hitstun(hitbox.hitstun_ticks)
	host.set_pos(data["x"], data["y"])

func _frame_5():
	terminate_hitboxes()
	host.sprite.hide()
	host.stop_particles()
	host.disabled = true
