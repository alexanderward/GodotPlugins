extends Node

@onready var console_ui: CanvasLayer = null
@onready var console_scene = preload("res://addons/console/ui/console.tscn")

var is_open: bool = false:
	set(value):
		is_open = value
		if console_ui:
			console_ui.visible = value

func _ready():
	console_ui = console_scene.instantiate()
	get_tree().root.call_deferred("add_child", console_ui)  # Deferred to avoid errors
	## ✅ Listen for `is_open` changes from `console_ui`
	console_ui.connect("is_open_changed", Callable(self, "_on_console_is_open_changed"))

func toggle_console():
	is_open = !is_open  # This will automatically update console_ui.visible

func _on_console_is_open_changed(new_state: bool):
	is_open = new_state  # ✅ Keep `is_open` in sync
