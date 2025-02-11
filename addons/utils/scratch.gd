extends CharacterBody2D

var speed = 50
@onready var sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var cursor_node = $CursorNode
@onready var dash_component: DashComponent = $Actions/Dash
@onready var sword_hitbox = $Weapon/Sword/AttackHitbox  # Define attack hitbox node

var current_animation = ""
var is_attacking = false  # True while the slash animation is playing

func _ready() -> void:
	# Connect animation finished signal
	Utils.image.resize_animated_sprite(sprite, Vector2(16, 16), [collision_shape, sword_hitbox])
	sprite.animation_finished.connect(_on_sprite_animation_finished)

	sword_hitbox.body_entered.connect(_on_attack_area_entered)  # Detect enemy hits	
	sword_hitbox.set_deferred("monitoring", true)  # Disable attack hitbox initially

func face_direction():
	# Rotate sprite based on cursor position
	var mouse_pos = get_global_mouse_position()
	sprite.flip_h = mouse_pos.x < global_position.x

func _unhandled_input(event):

	if event.is_action_pressed("attack") and not is_attacking:
		is_attacking = true
		sword_hitbox.set_deferred("monitoring", true)  # Enable attack hitbox

		# Attack animation logic
		if velocity.length() > 0:
			_set_animation("run_slash")
		else:
			_set_animation("slash")

func _physics_process(_delta: float) -> void:
	var direction = Vector2.ZERO

	# Standard top-down movement
	if not Console.is_open:
		if Input.is_action_pressed("ui_up"):
			direction.y -= 1  # Move up
		if Input.is_action_pressed("ui_down"):
			direction.y += 1  # Move down
		if Input.is_action_pressed("ui_left"):
			direction.x -= 1  # Move left
		if Input.is_action_pressed("ui_right"):
			direction.x += 1  # Move right

	# Normalize movement to avoid diagonal speed boost
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Apply movement if not dashing
	if not dash_component.is_dashing:
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO  # Stop normal movement while dashing

	# Update animation states
	if direction != Vector2.ZERO and not is_attacking:
		_set_animation("run")
	elif direction == Vector2.ZERO and not is_attacking:
		_set_animation("idle")

	# Process movement
	face_direction()
	move_and_slide()

func _on_sprite_animation_finished():
	# Reset attack state after animation completes
	if is_attacking and (current_animation == "slash" or current_animation == "run_slash"):
		is_attacking = false
		sword_hitbox.set_deferred("monitoring", false)  # Disable attack hitbox after attack
		# Return to proper animation
		if velocity.length() > 0:
			_set_animation("run")
		else:
			_set_animation("idle")

func _set_animation(new_animation: String) -> void:
	if current_animation != new_animation:
		current_animation = new_animation
		sprite.play(new_animation)

# Handle enemy hit detection
func _on_attack_area_entered(body):
	if is_attacking and body.is_in_group("enemies"):
		body.on_damage(1)  # Apply 10 damage to the enemy
