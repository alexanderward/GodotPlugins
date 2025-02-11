extends Ability

@export var dash_distance: float = 100.0
@export var dash_duration: float = 0.25
@export var invincibility_duration: float = 0.25 # Duration of invincibility while dashing


func _execute_ability(caster: BaseCharacter):
	var direction = caster.velocity.normalized()

	# ✅ Ensure valid direction (fallback to mouse direction)
	if direction.is_zero_approx():
		direction = (caster.get_global_mouse_position() - caster.global_position).normalized()
	if direction.is_zero_approx():
		return

	# ✅ Predict collision before dashing
	var space_state = caster.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(caster.global_position, caster.global_position + (direction * dash_distance), 1)
	var result = space_state.intersect_ray(query)

	var final_position = caster.global_position + (direction * dash_distance)
	if result:
		final_position = result.position  # ✅ Stop exactly at collision point

	# ✅ Enable invincibility
	caster.invincible = true

	# ✅ Tween for smooth dash movement
	var tween = get_tree().create_tween()
	tween.tween_property(caster, "global_position", final_position, dash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): 
		caster.invincible = false # Disable invincibility after dash
	)

	# ✅ Start cooldown **if this ability does not use charges**
	if max_charges == 1:
		_start_cooldown()

	print("%s dashed forward!" % caster.display_name)
