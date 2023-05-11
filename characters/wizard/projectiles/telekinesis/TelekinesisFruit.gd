extends TelekinesisProjectile

const HEAL_AMOUNT = 20

func hit_action(obj):
	obj.hp += HEAL_AMOUNT
