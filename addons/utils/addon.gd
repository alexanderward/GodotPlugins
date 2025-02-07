@tool
extends EditorPlugin

const AUTOLOAD_NAME = "Utils"
const AUTOLOAD_PATH = "res://addons/utils/autoload.gd"  # Main Utils script

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)  # Only add one autoload

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)
