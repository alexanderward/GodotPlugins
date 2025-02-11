extends BaseCharacter
class_name Player

# Data Variables
var user_id: String

# Player variables
var input_map: Array[StringName]


func _set_data(data: Dictionary):
	super._set_data(data)
	
	# Primatives
	for key in ['user_id']:
		set(key, data[key])	

func _ready():
	super._ready()
	input_map = InputMap.get_actions()
	add_to_group("player")
	hitbox.connect("area_entered", _on_hitbox_area_entered)
	_set_animation("idle")

# TODO - to a rebinding and spell bar system.
var keybinds_to_abilities: Dictionary = { # todo - cleanup
	#"ui_hotbar_1": "fireball",
	"dash": "dash",
	"teleport": "teleport",
	#"ui_hotbar_3": "teleport"
}

func _process(delta):
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).x
	# Flip the sprite if the mouse is on the left
	sprite.flip_h = direction < 0
	
	for action_name in keybinds_to_abilities.keys():
		
		if Input.is_action_just_pressed(action_name):
			var ability_name = keybinds_to_abilities[action_name]
			if ability_name in abilities:
				cast_ability(ability_name)
	


func _physics_process(_delta: float):
	# Only move if the player is alive
	if is_alive:
		var direction = get_input_direction()
		move_character(direction)

func get_input_direction() -> Vector2:
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1

	return direction.normalized()

func _on_hitbox_area_entered(area: Area2D):
	# Handle hit detection logic
	print("Player hitbox collided with: ", area.name)
	
func update_animation(direction: Vector2):
	if direction == Vector2.ZERO:
		_set_animation("idle")
	else:
		_set_animation("run")
		
