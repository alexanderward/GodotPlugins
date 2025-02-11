#extends InteractableObject
#class_name DestructibleObject
#
#var loot_table: Array  # List of items it can drop
#var destructable_object_schema = {
		#"loot_table": TYPE_ARRAY
	#}
	#
#func get_schema_conversion() -> Dictionary:
	#var merged_schema = super.get_schema_conversion()
	#merged_schema.merge(destructable_object_schema)
	#return merged_schema
#
#func interact():
	#super.interact()
	#destroy()
#
#func destroy():
	#destroyed.emit()
	#queue_free()  # ✅ Removes the object from the scene
	#print(display_name + " was destroyed!")
#
	## 🔹 Drop loot if available
	#for item in loot_table:
		#print("Dropped: " + item)
