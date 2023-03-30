extends SuperMove

func _frame_0():
	interruptible_on_opponent_turn = false

func process_projectile(projectile):
	host.add_spark_bomb(projectile.obj_name)
	interruptible_on_opponent_turn = true
	pass
