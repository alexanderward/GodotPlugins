extends Enemy
class_name Boss

signal special_attack_used(phase)

# Data Variables
var phase: int = 1

func _set_data(data: Dictionary):
	for key in ['phase']:
		set(key, data[key])	

func _process(delta: float) -> void:
	if phase == 1:
		chase_target()
	elif phase == 2:
		special_attack()

func special_attack():
	print(display_name + " is using a powerful ability!")
	emit_signal("special_attack_used", phase)
