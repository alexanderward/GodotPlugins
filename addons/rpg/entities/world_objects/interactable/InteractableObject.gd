#extends DataNode2D
#class_name InteractableObject
#
#signal interacted
#
#var interactable_object_schema = {}
#
#func get_schema_conversion() -> Dictionary:
	#var merged_schema = super.get_schema_conversion()
	#merged_schema.merge(interactable_object_schema)
	#return merged_schema
#
#func interact():
	#interacted.emit()
	#print(display_name + " was interacted with.")
