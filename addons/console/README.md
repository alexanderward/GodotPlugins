
## Setup
- Drag into addons folder

## Command Registration

## Use
- use the `~` to toggle console
- history - shows all previous commands
- history clear - clears history
- $<#> - replay a command at history #

## Prevent characters from going to other scenes
```
func _physics_process(_delta: float) -> void:
	# Standard top-down movement
	if not Console.is_open:
		if Input.is_action_pressed("ui_up"):
			input_vector.y -= 1  # Move up
		if Input.is_action_pressed("ui_down"):
			input_vector.y += 1  # Move down
		if Input.is_action_pressed("ui_left"):
			input_vector.x -= 1  # Move left
		if Input.is_action_pressed("ui_right"):
			input_vector.x += 1  # Move right
```
