extends Node

"""
Able to resize a sprite and an array of nodes that will find all recursive collision shapes and scale to image
Utils.image.resize_animated_sprite(sprite, Vector2(16, 16), [collision_shape])
"""

func resize_animated_sprite(sprite: Node2D, new_size: Vector2, parent_nodes: Array[Node]):
	# Resize the sprite
	var debug = System.env.get_default("COLLISION_FRAMES_DEBUG", false)
	if sprite is Sprite2D:
		var original_size = sprite.texture.get_size()
		sprite.scale = new_size / original_size
		
	elif sprite is AnimatedSprite2D:
		var frames = sprite.sprite_frames
		if frames and frames.has_animation(sprite.animation):
			var texture = frames.get_frame_texture(sprite.animation, 0)
			if texture:
				var original_size = texture.get_size()
				sprite.scale = new_size / original_size

	# ✅ Automatically find all CollisionShape2D nodes under each parent node
	var collision_shapes: Array[CollisionShape2D] = []
	for parent_node in parent_nodes:
		_find_collision_shapes(parent_node, collision_shapes)  # Collect all collision shapes

	# ✅ Apply scaling to each found CollisionShape2D
	var scale_factor = sprite.scale  # Get the correct scale

	for collision_shape in collision_shapes:
		if collision_shape.shape:
			var shape = collision_shape.shape.duplicate()  # Duplicate to avoid modifying the original resource

			# Reset collision shape position to avoid offset scaling issues
			collision_shape.position = Vector2.ZERO  

			# Scale different shape types correctly
			if shape is RectangleShape2D:
				shape.size *= scale_factor  
			elif shape is CapsuleShape2D:
				shape.radius *= scale_factor.x
				shape.height *= scale_factor.y
			elif shape is CircleShape2D:
				shape.radius *= scale_factor.x
			elif shape is CollisionPolygon2D:
				var new_polygon = []
				for point in shape.polygon:
					new_polygon.append(point * scale_factor)
				shape.polygon = new_polygon

			# Apply the modified shape
			collision_shape.shape = shape
			
			# Restore the original offset after scaling (prevents weird shifts)
			collision_shape.position *= scale_factor

			# ✅ If debug mode is on, create a blue Polygon2D overlay
			if debug:
				_add_debug_overlay(collision_shape)

# 🔍 Recursive function to find all CollisionShape2D nodes inside a given parent node
func _find_collision_shapes(node: Node, results: Array[CollisionShape2D]):
	if node is CollisionShape2D:
		results.append(node)  # ✅ This modifies `results` directly
	
	for child in node.get_children():
		_find_collision_shapes(child, results)  # ✅ Updates `results` recursively

# ✅ Function to add a debug overlay (Polygon2D) for visualization
func _add_debug_overlay(collision_shape: CollisionShape2D):
	# Ensure the shape is a supported type for visualization
	var shape = collision_shape.shape
	if not (shape is RectangleShape2D or shape is CapsuleShape2D or shape is CircleShape2D):
		return

	# Create a new Polygon2D for visualization
	var debug_polygon = Polygon2D.new()
	debug_polygon.color = Color(0, 0, 1, 0.3)  # Semi-transparent blue

	if shape is RectangleShape2D:
		debug_polygon.polygon = PackedVector2Array([
			Vector2(-shape.size.x / 2, -shape.size.y / 2),
			Vector2(shape.size.x / 2, -shape.size.y / 2),
			Vector2(shape.size.x / 2, shape.size.y / 2),
			Vector2(-shape.size.x / 2, shape.size.y / 2)
		])
	elif shape is CircleShape2D:
		var radius = shape.radius
		debug_polygon.polygon = PackedVector2Array([
			Vector2(-radius, -radius),
			Vector2(radius, -radius),
			Vector2(radius, radius),
			Vector2(-radius, radius)
		])
	elif shape is CapsuleShape2D:
		var radius = shape.radius
		var height = shape.height
		debug_polygon.polygon = PackedVector2Array([
			Vector2(-radius, -height / 2),
			Vector2(radius, -height / 2),
			Vector2(radius, height / 2),
			Vector2(-radius, height / 2)
		])

	# Add the debug polygon as a child of the collision shape's parent
	collision_shape.get_parent().add_child(debug_polygon)
	debug_polygon.global_position = collision_shape.global_position
	debug_polygon.rotation = collision_shape.rotation
