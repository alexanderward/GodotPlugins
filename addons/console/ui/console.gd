extends CanvasLayer



@onready var panel := $Panel
@onready var text_label := $Panel/ScrollContainer/RichTextLabel
@onready var input_field := $Panel/LineEdit
@onready var scroll_container := $Panel/ScrollContainer
@onready var suggestion_container := $SuggestionScrollContainer
@onready var suggestion_label := $SuggestionScrollContainer/SuggestionLabel



const HISTORY_FILE = "user://console_history.cfg"
const MAX_HISTORY_SIZE = 50  # Number of commands to keep
var history: Array = []  # Stores command history
var history_position: int = -1  # Tracks history index (-1 means new command)




var is_open := false:
	set(value):
		is_open = value
		emit_signal("is_open_changed", is_open)  # ✅ Emit when toggled

var command_tree = {}
var current_command_tree = command_tree

signal visibility_changed_signal(is_open)  # ✅ Signal for visibility updates

func hide_console():
	panel.hide()
	input_field.hide()
	suggestion_container.hide()

func show_console():
	panel.show()
	input_field.clear()
	input_field.show()

func _init():
	add_user_signal("is_open_changed", [{"name": "is_open", "type": TYPE_BOOL}])  # ✅ Force register

func _ready():
	_load_history()
	# Register core commands
	register_command(["?"], help_command, "Displays available commands")
	register_command(["clear"], clear_command, "Clears the console")
	
	register_command(["history"], history_command, "Shows the command history")
	register_command(["history", "clear"], history_clear_command, "Clears the command history")


	# Player Commands
	register_command(["/player", "level"], level_command, "Shows player level")
	register_command(["/player", "level", "set"], level_set_command, "Sets player level with a multiplier")
	register_command(["/player", "stats"], stats_command, "Shows player stats")
	register_command(["/player", "stats", "set"], stats_set_command, "Updates player stats")


	input_field.text_submitted.connect(_on_command_entered)
	input_field.text_changed.connect(_on_command_typing)
	input_field.gui_input.connect(_on_input_navigation)

	# Ensure input field always receives focus but doesn't block _input()
	input_field.focus_mode = Control.FOCUS_ALL
	hide_console()  # Console starts hidden


func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_QUOTELEFT:
		toggle_console()
		get_viewport().set_input_as_handled()
		return

	# Block in-game inputs if console is open
	if is_open and not input_field.has_focus():
		input_field.grab_focus()


func toggle_console():
	if not is_open:
		panel.position = Vector2(0, -panel.size.y)
		show_console()

	var target_position: Vector2
	if not is_open:
		target_position = Vector2(0, 0)
	else:
		target_position = Vector2(0, -panel.size.y)

	# Kill any old tween
	if panel.has_meta("tween"):
		var old_tween = panel.get_meta("tween")
		if is_instance_valid(old_tween):
			old_tween.kill()

	var new_tween := create_tween()
	panel.set_meta("tween", new_tween)
	new_tween.tween_property(panel, "position", target_position, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if not is_open:
		# Opening console
		input_field.grab_focus()
		input_field.focus_mode = Control.FOCUS_ALL
		input_field.set_deferred("editable", true)
	else:
		# Closing console
		input_field.release_focus()
		input_field.set_deferred("editable", false)
		input_field.hide()

		# Hide & clear suggestions
		suggestion_container.hide()
		suggestion_label.clear()

	is_open = not is_open


func register_command(path: Array, callback: Callable, description: String = ""):
	var current = command_tree
	for part in path:
		if not current.has(part):
			current[part] = {}
		current = current[part]

	# Extract param info (both usage strings and actual type IDs)
	var info = _get_function_arguments(callback)
	var param_types = info["param_types"]
	var usage_args = info["usage_args"]

	# Build usage string
	var usage = " ".join(path)
	if usage_args.size() > 0:
		usage += " " + " ".join(usage_args)

	current["callback"] = callback
	current["description"] = description
	current["usage"] = usage
	current["param_types"] = param_types  # We'll use this to check arguments at runtime


func _get_function_arguments(callback: Callable) -> Dictionary:
	# Return both:  param_types (TYPE_INT, TYPE_FLOAT, etc.)
	#               usage_args (the color-tagged <name:type> strings)
	var result = { "param_types": [], "usage_args": [] }

	var obj = callback.get_object()
	if obj == null or obj.get_script() == null:
		return result

	var method_list = obj.get_script().get_script_method_list()
	var method_name = callback.get_method()

	for method in method_list:
		if method["name"] == method_name:
			var param_types = []
			var usage_args = []
			for param in method["args"]:
				var t = param["type"]
				var type_name = _get_type_name(t)
				# Color-coded usage placeholder
				var colored_arg = "[color=orange]<" + param["name"] + ":" + type_name + ">[/color]"
				usage_args.append(colored_arg)
				param_types.append(t)

			result["param_types"] = param_types
			result["usage_args"] = usage_args
			break

	return result


func _get_type_name(type_id: int) -> String:
	match type_id:
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "string"
		TYPE_BOOL:
			return "bool"
		_:
			return "unknown"


func _on_command_entered(command: String):
	if not is_open:
		return
		
	if command.strip_edges() == "":
		return
		
	# Handle history recall ($0, $1, etc.)
	if command.begins_with("$"):
		var index = command.substr(1).to_int()
		if index >= 0 and index < history.size():
			command = history[index]  # Replace with actual command
			text_label.append_text("\n[color=yellow]Re-running:[/color] " + command)  # Show execution
			input_field.clear()
			return _on_command_entered(command)
		else:
			text_label.append_text("\n[color=red]Invalid history index![/color]")
			return

	# Save command to history (only if it's not duplicate of last entry)
	if history.is_empty() or history[-1] != command:
		history.append(command)
		if history.size() > MAX_HISTORY_SIZE:
			history.pop_front()  # Keep within limit
		_save_history()  # Persist history

	# Reset history position
	history_position = -1  
	
	input_field.text = ""
	text_label.append_text("\n> " + command)
	

	var args = command.strip_edges().split(" ", false)
	var current = command_tree
	var command_path = []
	var final_command = null
	
	

	var i = 0
	while i < args.size() and args[i] in current:
		command_path.append(args[i])
		current = current[args[i]]
		i += 1

	if "callback" not in current:
		text_label.append_text("\n[color=red]Unknown Command! Type '?' for available commands.[/color]")
		return

	final_command = current

	# ============== CUSTOM ARGUMENT CHECKING ===============
	var param_types = final_command["param_types"]
	var call_args = args.slice(command_path.size())
	if call_args.size() != param_types.size():
		# Mismatch in argument count
		text_label.append_text("\n[color=red]There is a mismatch in input! (Wrong number of arguments)[/color]")
		text_label.append_text("\n[color=yellow]Usage: [/color][color=grey]" + str(final_command["usage"]) + "[/color]\n")
		return

	# Convert string inputs to correct typed values
	var converted_args = []
	for idx in range(param_types.size()):
		var t = param_types[idx]
		var raw_arg = call_args[idx]			
		match t:
			TYPE_INT:
				if not raw_arg.is_valid_int():
					text_label.append_text("\n[color=red]There is a mismatch in input! (Expected int, got: '" + raw_arg + "')[/color]")
					text_label.append_text("\n[color=yellow]Usage: [/color][color=grey]" + str(final_command["usage"])+ "[/color]\n")
					return
				converted_args.append(int(raw_arg))

			TYPE_FLOAT:
				if not raw_arg.is_valid_float():
					text_label.append_text("\n[color=red]There is a mismatch in input! (Expected float, got: '" + raw_arg + "')[/color]")
					text_label.append_text("\n[color=yellow]Usage: [/color][color=grey]" + str(final_command["usage"]) + "[/color]\n")
					return
				converted_args.append(float(raw_arg))

			TYPE_BOOL:
				# There's no built-in 'is_valid_bool()'; parse or check manually
				var lower = raw_arg.to_lower()
				if lower == "true" or lower == "1":
					converted_args.append(true)
				elif lower == "false" or lower == "0":
					converted_args.append(false)
				else:
					text_label.append_text("\n[color=red]There is a mismatch in input! (Expected bool, got: '" + raw_arg + "')[/color]")
					text_label.append_text("\n[color=yellow]Usage: [/color][color=grey]" + str(final_command["usage"]) + "[/color]\n")
					return

			TYPE_STRING:
				converted_args.append(raw_arg)  # Always a string, no check needed
			_:
				# Unknown or custom type
				converted_args.append(raw_arg)

	# If we reach here, all arguments matched
	final_command["callback"].callv(converted_args)


func _on_command_typing(new_text: String):
	if not is_open:
		return
	suggestion_label.clear()
	
	# Split input text into tokens.
	var tokens = new_text.strip_edges().split(" ", false)
	if tokens.size() == 0:
		suggestion_container.hide()
		return
	
	# Traverse the command tree as far as possible.
	var node = command_tree
	var matched_tokens = []
	for token in tokens:
		if token in node:
			matched_tokens.append(token)
			node = node[token]
		else:
			break
	
	# Determine the partial token used for matching children.
	var partial_token = ""
	if matched_tokens.size() < tokens.size():
		partial_token = tokens[matched_tokens.size()]
	else:
		partial_token = ""
	
	var suggestions = []
	
	# If the current node is a complete command, show its usage.
	if "callback" in node:
		# Cast values to string explicitly.
		suggestions.append("[color=darkgrey]" + str(node["usage"]) +
			"[color=green] - " + str(node["description"]) + "[/color]")
	
	# Now, check for child suggestions from the current node.
	for key in node.keys():
		if key in ["callback", "description", "usage", "param_types"]:
			continue
		# Suggest if the child key begins with the partial token.
		if key.begins_with(partial_token):
			var child = node[key]
			if "usage" in child:
				suggestions.append("[color=darkgrey]" + str(child["usage"]) +
					"[color=green] - " + str(child["description"]) + "[/color]")
			# Optionally, recursively add deeper suggestions.
			suggestions += _collect_command_paths(key, child)
	
	if suggestions.size() > 0:
		suggestion_container.show()
		suggestion_label.append_text("[color=yellow]Suggestions:\n[/color]" +
			"\n".join(suggestions))
	else:
		suggestion_container.hide()


func _traverse_command_tree(tree, args, depth):
	if depth >= args.size():
		return tree
	var key = args[depth]
	if key in tree:
		return _traverse_command_tree(tree[key], args, depth + 1)
	return null


func _collect_command_paths(prefix: String, tree: Dictionary) -> Array:
	var paths = []
	for cmd in tree.keys():
		if cmd in ["callback", "description", "usage", "param_types"]:
			continue
		if "usage" in tree[cmd]:
			paths.append("[color=darkgrey]" + tree[cmd]["usage"] +
						 "[color=green] - " + tree[cmd]["description"] + "[/color]")
		paths += _collect_command_paths(prefix + " " + cmd, tree[cmd])
	return paths


# ----------------------------------------------------------------
#   Example Command Callbacks
# ----------------------------------------------------------------

func help_command():
	# Build the help text.
	var help_text = "[color=yellow]Available Commands:[/color]\n\n"
	
	# Gather top-level category keys (ignoring metadata).
	var categories = []
	for key in command_tree.keys():
		if key in ["callback", "description", "usage", "param_types"]:
			continue
		categories.append(key)
	
	# Sort the categories alphabetically (case-insensitive).
	categories.sort_custom(_compare_string)
	
	# For each top-level category, flatten its runnable commands.
	for category in categories:
		help_text += "[color=magenta]" + str(category) + "[/color]\n"
		var cmds = _flatten_commands(command_tree[category])
		# Sort the commands alphabetically by their usage string.
		cmds.sort_custom(_compare_usage)
		
		# Append each command (with two-space indentation).
		for cmd in cmds:
			help_text += "  [color=cyan]" + str(cmd["usage"]) + "[/color]"
			if cmd.has("description") and str(cmd["description"]) != "":
				help_text += " [color=green]- " + str(cmd["description"]) + "[/color]"
			help_text += "\n"
		help_text += "\n"
	
	text_label.append_text(help_text)


# Helper function: recursively flatten runnable commands (nodes with a callback)
func _flatten_commands(tree: Dictionary) -> Array:
	var result = []
	# If this node is runnable, add it.
	if tree.has("callback"):
		result.append(tree)
	# Then check its children.
	for key in tree.keys():
		# Skip metadata keys.
		if key in ["callback", "description", "usage", "param_types"]:
			continue
		result += _flatten_commands(tree[key])
	return result


# Helper function for sorting by usage (alphabetically, case-insensitive)
# Inverted: returns 1 when A < B, so that the final sort order is ascending (A at top, Z at bottom).
# Helper function for sorting by command name (ignoring arguments)
func _compare_usage(a, b):
	var A = str(a["usage"]).split(" ")[0].to_lower()  # Extracts the base command name
	var B = str(b["usage"]).split(" ")[0].to_lower()
	if A < B:
		return -1  # A appears before B (Ascending order)
	elif A > B:
		return 1   # B appears after A
	else:
		return 0   # Keeps equal items in order

# Helper function for sorting top-level categories alphabetically
func _compare_string(a, b):
	var A = str(a).to_lower()
	var B = str(b).to_lower()
	if A < B:
		return -1  # A appears before B
	elif A > B:
		return 1   # B appears after A
	else:
		return 0   # Keeps equal items in order



func clear_command():
	text_label.clear()
	
# Function to show history in the console
func history_command():
	if history.is_empty():
		text_label.append_text("\n[color=gray]No command history available.[/color]")
		return

	text_label.append_text("\n[color=yellow]Command History:[/color]\n")
	for i in range(history.size()):
		text_label.append_text("[color=cyan]$" + str(i) + ":[/color] " + history[i] + "\n")


# Function to clear history
func history_clear_command():
	history.clear()
	_save_history()  # Save empty history to remove file content
	text_label.append_text("\n[color=red]Command history cleared.[/color]")

func level_command():
	text_label.append_text("\n[color=green]Current Level: 10[/color]")

func level_set_command(level: int, multiplier: float):
	text_label.append_text("\n[color=green]Level set to " + str(level)
		+ " with multiplier " + str(multiplier) + "[/color]")

func stats_command():
	text_label.append_text("\n[color=green]Player Stats: HP=100, MP=50, ATK=20[/color]")

func stats_set_command(hp: int, atk: int):
	text_label.append_text("\n[color=green]Stats updated! HP: " + str(hp)
		+ ", ATK: " + str(atk) + "[/color]")


#### History
func _on_input_navigation(event: InputEvent):
	if is_open:
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					input_field.clear()
				KEY_C:
					if event.ctrl_pressed:
						input_field.clear()
				KEY_UP:
					_navigate_history(-1)
					get_viewport().set_input_as_handled()
				KEY_DOWN:
					_navigate_history(1)
					get_viewport().set_input_as_handled()

func _navigate_history(direction: int):
	if history.is_empty():
		return
	
	# Reverse navigation order
	history_position -= direction  # Invert direction
	
	# Keep within valid range
	history_position = clamp(history_position, 0, history.size())

	# Set input text to history entry
	if history_position == history.size():
		input_field.clear()  # No more history, new command
	else:
		input_field.text = history[history.size() - 1 - history_position]  # Reverse index
		input_field.caret_column = input_field.text.length()  # Move cursor to end


func _save_history():
	var config = ConfigFile.new()
	for i in range(history.size()):
		config.set_value("history", str(i), history[i])
	config.save(HISTORY_FILE)

func _load_history():
	var config = ConfigFile.new()
	if config.load(HISTORY_FILE) == OK:
		history.clear()
		for key in config.get_section_keys("history"):
			history.append(config.get_value("history", key))
