extends DefaultFireball

const MOVE_SPEED = "20"
onready var swept_hitbox = $SweptHitbox

func _tick():
	._tick()
	host.sprite.visible = active and current_tick > 0 and !host.disabled

func fizzle():
	.fizzle()
	host.sprite.hide()
	host.spawn_particle_effect_relative(preload("res://characters/mutant/projectiles/CausticThornEffect2.tscn"), Vector2())

func _enter():
	._enter()
	host.sprite.hide()
#	._frame_0()
	var move_vec = fixed.normalized_vec_times(data.dir.x, data.dir.y, MOVE_SPEED)
#	print(move_vec)
	move_x_string = move_vec.x
	move_y_string = move_vec.y
	host.flip.rotation = (Utils.ang2vec(float(data.angle) - TAU/4) * Vector2(1, 1)).angle()
	if fixed.ge(move_y_string, "0"):
		host.flip.rotation += TAU/2
	swept_hitbox.to_x = fixed.round(fixed.mul(data.dir.x, "-10"))
	swept_hitbox.to_y = fixed.round(fixed.mul(data.dir.y, "-10"))

func move():
	host.move_directly(move_x_string, move_y_string)
