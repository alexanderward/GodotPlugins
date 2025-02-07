extends Node

var env = null  # Placeholder for the env instance

func _ready():
	env = load("res://addons/system/src/env.gd").new()  # ✅ Load dynamically at runtime
	add_child(env)
