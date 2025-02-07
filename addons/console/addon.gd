@tool
extends EditorPlugin

const AUTOLOAD_NAME = "Console"
const AUTOLOAD_PATH = "res://addons/console/console_autoload.gd"

func _enter_tree():
	# Add the autoload globally
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

func _exit_tree():
	# Remove autoload on plugin disable
	remove_autoload_singleton(AUTOLOAD_NAME)
