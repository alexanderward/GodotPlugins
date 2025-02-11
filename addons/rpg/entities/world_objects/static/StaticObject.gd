extends DataNode2D
class_name StaticObject

var is_solid: bool = false

func get_schema_conversion() -> Dictionary:
	var merged_schema = super.get_schema_conversion()
	merged_schema.merge({
		"is_solid": TYPE_BOOL
	})
	return merged_schema
	

func _ready():
	var collider = $StaticBody2D/CollisionShape2D if has_node("StaticBody2D/CollisionShape2D") else null
	
	if collider:
		collider.disabled = not is_solid
		print(display_name + " is a static object. Solid: " + str(is_solid))
