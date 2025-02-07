extends Node
# Make sure to - AutoLoad to be accessible from any script.
# Usage: Env.<name>

var env_vars: Dictionary = {}

func _ready():
	_load_env_file("res://.env")  # Load the .env file on game startup
	_log_env_vars()  # Pretty print the loaded environment variables

func _load_env_file(file_path: String):
	if not FileAccess.file_exists(file_path):
		print("\n❌ [EnvLoader] .env file not found at: ", file_path, "\n")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line == "" or line.begins_with("#"):  # Ignore empty lines and comments
			continue
		var key_value = line.split("=", false)
		if key_value.size() == 2:
			env_vars[key_value[0]] = _convert_value(key_value[1])  # Store with auto-conversion

func get_default(key: String, default_value = null):
	return env_vars.get(key, default_value)

# ✅ Converts "true" → true, "false" → false, numbers → int/float
static func _convert_value(value: String):
	value = value.strip_edges().to_lower()  # Normalize case

	if value == "true":
		return true
	elif value == "false":
		return false
	elif value.is_valid_int():
		return value.to_int()
	elif value.is_valid_float():
		return value.to_float()
	return value  # Return original string if not a recognized type

func _log_env_vars():
	if env_vars.is_empty():
		print("\n⚠️ [EnvLoader] No environment variables found.\n")
		return

	var separator = "=".repeat(40)  # ✅ Correct usage in Godot

	print("\n🌍 **Loaded Environment Variables:**")
	print(separator)
	for key in env_vars.keys():
		print("🔹 %s = %s (%s)" % [key, env_vars[key], typeof(env_vars[key])])  # ✅ Shows type
	print(separator + "\n")
