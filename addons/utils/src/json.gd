extends RefCounted

# Equivalent to Python's `json.load(file)`
func load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: " + path)
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	return loads(content)

# Equivalent to Python's `json.loads(string)`
func loads(json_string: String) -> Dictionary:
	var parsed_data = JSON.parse_string(json_string)

	if parsed_data == null:
		push_error("Failed to parse JSON string")
		return {}

	return parsed_data

# Equivalent to Python's `json.dump(data, file)`
func dump(data: Dictionary, path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(dumps(data))  # Write the formatted JSON
	file.close()

# Equivalent to Python's `json.dumps(data)`
func dumps(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")  # Pretty print JSON
