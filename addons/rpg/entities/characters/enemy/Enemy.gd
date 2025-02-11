extends BaseCharacter
class_name Enemy

signal attacked(target)

# Data Variables
var aggression_level: int = 1  # 1 = Passive, 2 = Attacks on sight

# Class Variables
var target: Player = null

func _set_data(data: Dictionary):
	for key in ['aggression_level']:
		set(key, data[key])

func _process(delta: float) -> void:
	if aggression_level > 1 and target:
		chase_target()

func _physics_process(delta: float) -> void:
	move_and_slide()  # Apply AI movement

func chase_target():
	if target and target.is_alive:
		var direction = (target.global_position - global_position).normalized()
		move_character(direction)
	else:
		target = find_closest_player()

func find_closest_player() -> Player:
	var players = get_tree().get_nodes_in_group("players")
	if players.size() == 0:
		return null

	var closest_player = players[0]
	var min_distance = global_position.distance_to(closest_player.global_position)

	for player in players:
		var distance = global_position.distance_to(player.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_player = player

	return closest_player

func attack(target: BaseCharacter):
	print(display_name + " attacks " + target.display_name + "!")
	emit_signal("attacked", target)
	target.take_damage(10)
