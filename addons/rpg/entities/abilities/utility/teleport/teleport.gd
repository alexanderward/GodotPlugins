extends Ability

@export var teleport_distance: float = 200.0

func _execute_ability(caster: BaseCharacter):
	var direction = caster.velocity.normalized()
	
	# ✅ Ensure direction is valid (fallback to mouse direction)
	if direction.is_zero_approx():
		direction = (caster.get_global_mouse_position() - caster.global_position).normalized()
	
	# ✅ Safety check to prevent invalid calculations
	if direction.is_zero_approx():
		return

	# ✅ Get world space for physics queries
	var space_state = caster.get_world_2d().direct_space_state

	# ✅ Define raycast parameters
	var from_position = caster.global_position
	var to_position = caster.global_position + (direction * teleport_distance)
	var query = PhysicsRayQueryParameters2D.create(from_position, to_position)

	# ✅ Check for collisions
	var result = space_state.intersect_ray(query)

	# ✅ Adjust teleport position if a collision is detected
	var final_position = to_position
	if result:
		final_position = result.position  # ✅ Stop at the collision point instead

	# ✅ Apply valid teleportation
	caster.global_position = final_position
	print("%s teleported to %s!" % [caster.display_name, final_position])
