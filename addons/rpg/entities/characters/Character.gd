extends CharacterBody2D
class_name BaseCharacter

signal health_changed(new_health)
signal mana_changed(new_mana)
signal died(display_name)
signal moved(new_position)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var healthRegenTimer: Timer = $HealthRegenTimer
@onready var manaRegenTimer: Timer = $ManaRegenTimer

var id: String
var display_name: String

# =======================
# BASE STATS (EXPORTED)
# =======================
@export_group("Base Stats")

@export var ability_power_base: int = 0:
	set(value):
		ability_power_base = value
		_calculate_resources()

@export var armor_base: int = 25:
	set(value):
		armor_base = value
		_calculate_resources()

@export var attack_damage_base: int = 55:
	set(value):
		attack_damage_base = value
		_calculate_resources()

@export var attack_range: int = 500:
	set(value):
		attack_range = value
		_calculate_resources()

@export var attack_speed_base: float = 0.68:
	set(value):
		attack_speed_base = value
		_calculate_resources()

@export var crit_chance: int = 0:
	set(value):
		crit_chance = value
		_calculate_resources()

@export var crit_damage: int = 175:
	set(value):
		crit_damage = value
		_calculate_resources()

@export var health_base: int = 600:
	set(value):
		health_base = value
		_calculate_resources()

@export var magic_resistance_base: int = 30:
	set(value):
		magic_resistance_base = value
		_calculate_resources()

@export var mana_base: int = 400:
	set(value):
		mana_base = value
		_calculate_resources()

@export var movement_speed_base: int = 330:
	set(value):
		movement_speed_base = value
		_calculate_resources()

@export var invincible: bool = false:
	set(value):
		invincible = value
		_calculate_resources()
		
# =======================
# GROWTH STATS (EXPORTED)
# =======================
@export_group("Growth Stats")

@export var ability_power_per_level: int = 0:
	set(value):
		ability_power_per_level = value
		_calculate_resources()

@export var armor_per_level: int = 4:
	set(value):
		armor_per_level = value
		_calculate_resources()

@export var attack_damage_per_level: int = 3:
	set(value):
		attack_damage_per_level = value
		_calculate_resources()

@export var attack_speed_per_level: float = 2.5:
	set(value):
		attack_speed_per_level = value
		_calculate_resources()

@export var health_per_level: int = 100:
	set(value):
		health_per_level = value
		_calculate_resources()

@export var magic_resistance_per_level: float = 1.5:
	set(value):
		magic_resistance_per_level = value
		_calculate_resources()

@export var mana_per_level: int = 50:
	set(value):
		mana_per_level = value
		_calculate_resources()

# =======================
# LEVEL SYSTEM
# =======================
@export_group("Level")

@export var level_max: int = 18:
	set(value):
		level_max = value
		_calculate_resources()

@export var level_current: int = 1:
	set(value):
		level_current = value
		_calculate_resources()

@export var experience_max: int = 1000:
	set(value):
		experience_max = value
		_calculate_resources()

@export var experience_current: int = 0:
	set(value):
		experience_current = value
		_calculate_resources()

# =======================
# OTHER PROPERTIES
# =======================
@export_group("Currency")

@export var gold: float = 0.0:
	set(value):
		gold = value
		_calculate_resources()

@export_group("Mobility")

@export var movement_speed_bonus: float = 0.0:
	set(value):
		movement_speed_bonus = value
		_calculate_resources()

@export_group("Inventory & Status")

@export var inventory: Array = []:
	set(value):
		inventory = value
		_calculate_resources()

@export var modifiers: Array = []:
	set(value):
		modifiers = value
		_calculate_resources()

@export var status_effects: Array = []:
	set(value):
		status_effects = value
		_calculate_resources()

@export_group("Abilities")

@export var abilities_list: Array = []:
	set(value):
		abilities_list = value
		_calculate_resources()

# =======================
# CALCULATED STATS (EXPORTED)
# =======================
@export_group("Calculated Stats")

@export var ability_power: int = 0
@export var armor: int = 0
@export var attack_damage: int = 0
@export var attack_speed: float = 0
@export var health_max: int = 0
@export var health_regen: int = 0
@export var health_current: int = 0
@export var magic_resistance: int
@export var mana_max: int = 0
@export var mana_regen: int = 0
@export var mana_current: int = 0
@export var movement_speed: int = 0

var abilities: Dictionary = {}
var queued_ability: Ability = null
var current_ability: Ability = null
var current_animation = ""
var is_alive: bool = true

# =======================
# SETUP & INIT
# =======================
func _ready() -> void:
	add_to_group("character")
	print(display_name + " initialized at " + str(global_position))
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	healthRegenTimer.timeout.connect(_on_health_regen)
	manaRegenTimer.timeout.connect(_on_mana_regen)	


func _set_data(data: Dictionary):
	print('level', data.get('level'))
	id = data.get("id", "")
	display_name = data.get("display_name", "")
	level_current = data.get("level", 1)
	experience_current = data.get("experience", 0)
	gold = data.get("gold", 0)

	# Load mobility
	movement_speed_bonus = data.get("movement_speed_bonus", movement_speed_bonus)

	# Load inventory & modifiers
	inventory = data.get("inventory", [])
	modifiers = data.get("modifiers", [])
	status_effects = data.get("status_effects", [])

	# Load abilities
	abilities_list = data.get("abilities", [])
	load_abilities(abilities_list)

	# Positioning
	position = Vector2(data["position"]["x"], data["position"]["y"])
	global_position = position

	# Calculate Derived Stats
	_calculate_resources()

func get_ability_map() -> Dictionary:
	push_error("Developer Action: You must override 'get_ability_map' in %s" % self)
	return {}
	
# =======================
# ABILITIES
# =======================
func load_abilities(ability_list: Array):
	var ability_map := get_ability_map()
	ability_map["dash"] = "res://addons/rpg/entities/abilities/utility/dash/dash.tscn"
	ability_map["teleport"] = "res://addons/rpg/entities/abilities/utility/teleport/teleport.tscn"

	for ability_name in ability_list:
		if ability_map.has(ability_name):
			var ability_scene = load(ability_map[ability_name])
			if ability_scene:
				var ability_instance = ability_scene.instantiate()
				abilities[ability_name] = ability_instance
				add_child(ability_instance)
		else:
			push_warning("Attempting to initialize unknown ability: %s" % ability_name)

	print("Loaded abilities: ", abilities.keys())

# =======================
# STAT RETRIEVAL FUNCTIONS
# =======================

func _calculate_resources():
	# Reset values to base before applying level scaling & modifiers
	ability_power = ability_power_base
	armor = armor_base
	attack_damage = attack_damage_base
	attack_speed = attack_speed_base
	health_max = health_base
	magic_resistance = magic_resistance_base
	mana_max = mana_base
	movement_speed = movement_speed_base + movement_speed_bonus

	# Apply level scaling
	ability_power += ability_power_per_level * (level_current - 1)
	armor += armor_per_level * (level_current - 1)
	attack_damage += attack_damage_per_level * (level_current - 1)
	attack_speed += attack_speed_per_level * (level_current - 1)
	health_max += health_per_level * (level_current - 1)
	magic_resistance += magic_resistance_per_level * (level_current - 1)
	mana_max += mana_per_level * (level_current - 1)

	# Apply inventory item bonuses
	for item in inventory:
		for mod in item.get("modifiers", []):
			match mod.get("stat", ""):
				"ability_power": ability_power += mod.get("value", 0)
				"armor": armor += mod.get("value", 0)
				"attack_damage": attack_damage += mod.get("value", 0)
				"attack_speed": attack_speed += mod.get("value", 0)
				"health": health_max += mod.get("value", 0)
				"magic_resistance": magic_resistance += mod.get("value", 0)
				"mana": mana_max += mod.get("value", 0)
				"movement_speed": movement_speed += mod.get("value", 0)

	# Apply buffs and debuffs
	for effect in modifiers:
		for mod in effect.get("modifiers", []):
			match mod.get("stat", ""):
				"ability_power": ability_power += mod.get("value", 0)
				"armor": armor += mod.get("value", 0)
				"attack_damage": attack_damage += mod.get("value", 0)
				"attack_speed": attack_speed += mod.get("value", 0)
				"health": health_max += mod.get("value", 0)
				"magic_resistance": magic_resistance += mod.get("value", 0)
				"mana": mana_max += mod.get("value", 0)
				"movement_speed": movement_speed += mod.get("value", 0)

	# Emit health/mana changes
	emit_signal("health_changed", health_max)
	emit_signal("mana_changed", mana_max)
	
# =======================
# DAMAGE SYSTEM
# =======================
func cast_ability(ability_name: String):
	if not abilities.has(ability_name):
		print("Ability not found:", ability_name)
		return

	var ability = abilities[ability_name]

	# ✅ Only queue if an ability is actively casting or channeling
	if current_ability and (current_ability.is_casting or current_ability.is_channeling):
		if ability.can_be_buffered:
			queued_ability = ability
			print("%s queued after %s" % [ability_name, current_ability.ability_name])
		return

	# Set the current ability
	current_ability = ability

	# Execute ability
	ability.cast(self)
	
func calculate_damage_taken(damage: float, damage_type: String) -> float:
	# No damage if invincible
	if invincible:
		return 0.0

	# Use current values instead of recalculating scaling every time

	# Armor & Magic Resistance mitigation (LoL formula)
	var mitigation = 0.0
	if damage_type == "physical":
		mitigation = armor / (100.0 + armor)
	elif damage_type == "magic":
		mitigation = magic_resistance / (100.0 + magic_resistance)

	return max(damage * (1.0 - mitigation), 0.0)

	
# =======================
# OTHER UTILITIES
# =======================
func _on_health_regen():
	if health_current < health_max:
		health_current = min(health_current + health_regen, health_max)
		emit_signal("health_changed", health_current)

func _on_mana_regen():
	if mana_current < mana_max:
		mana_current = min(mana_current + mana_regen, mana_max)
		emit_signal("mana_changed", mana_current)

# =======================
# ANIMATION
# =======================
func _on_sprite_animation_finished():
	if current_animation == "hurt":
		sprite.modulate = Color(1, 1, 1)
		_set_animation("idle")
	elif current_animation == "dying":
		queue_free()
		
func _set_animation(new_animation: String):
	if current_animation != new_animation:
		current_animation = new_animation
		sprite.play(new_animation)
		
func update_animation(direction: Vector2):
	push_error("'update_animation' not implemented on: %s" % self)
	
func move_character(direction: Vector2):
	velocity = direction.normalized() * movement_speed
	emit_signal("moved", global_position)
	update_animation(direction)
	move_and_slide()
