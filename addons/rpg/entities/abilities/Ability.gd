extends Node2D
class_name Ability

signal ability_used(ability_name)
signal cooldown_started(ability_name, cooldown_time)
signal cooldown_updated(ability_name, remaining_time)
signal cooldown_finished(ability_name)
signal charge_restored(ability_name, current_charges)
signal cast_started(ability_name, cast_time)
signal cast_updated(ability_name, remaining_time)
signal cast_finished(ability_name)
signal cast_interrupted(ability_name, reason)
signal ability_canceled(ability_name)
signal channel_started(ability_name, duration)
signal channel_interrupted(ability_name, reason)
signal pushback_applied(ability_name, pushback_amount)

@export_group("General Settings")
@export var ability_name: String = "Unknown Ability"
@export var ability_type: String = "mobility" # mobility, freefire, placement, melee, ranged
@export var schools: Array[String] = [] # ["fire", "frost"]
@export var category: String = "spell" # spell, curse, melee, ranged
@export var max_range: float = 400.0 # Max range (optional for placement)

@export_group("Cooldown & Casting")
@export var cooldown_time: float = 2.0 # Cooldown between uses
@export var cast_time: float = 0.0 # Short LoL-style delay before firing
@export var channel_duration: float = 0.0 # If > 0, this is a channeled ability
@export var cast_while_moving: bool = false # False means movement cancels the cast
@export var can_be_buffered: bool = true # If false, ability cannot be queued

@export_group("Charges (Optional)")
@export var max_charges: int = 1 # If > 1, ability uses charges
@export var charge_replenish_time: float = 5.0 # Time to restore 1 charge

@export_group("Damage & Scaling")
@export var base_damage: int = 50 # Base damage
@export var damage_variance: float = 0.2 # ±20% variation
@export var scaling: Dictionary = {} # Example: {"intellect": 2.0, "strength": 1.5}
@export var crit_chance: float = 0.2 # 20% chance for a critical hit
@export var crit_multiplier: float = 1.5 # Critical hits deal 1.5x damage

@export_group("Resource Costs")
@export var mana_cost: int = 0 # Cost to cast

@export_group("Interrupts & Pushback")
@export var interruptible: bool = true # Determines if this spell can be interrupted
@export var pushback_factor: float = 0.5 # Pushback when hit (percent of channel time)
@export var max_pushback: float = 1.5 # Max pushback time added

var is_on_cooldown: bool = false
var cooldown_remaining: float = 0.0
var cast_remaining: float = 0.0
var channel_remaining: float = 0.0
var is_casting: bool = false
var is_channeling: bool = false
var total_pushback: float = 0.0
var queued_ability: Ability = null

var current_charges: int = 1
var charge_cooldown_active: bool = false

func _ready():
	# ✅ If ability has charges, start at max
	if max_charges > 1:
		current_charges = max_charges

# 🔥 Cast Ability
func cast(caster: BaseCharacter):
	# ✅ Prevent ability use if it's on cooldown
	if is_on_cooldown:
		print("%s is on cooldown! %.2f seconds left." % [ability_name, cooldown_remaining])
		return

	# ✅ Prevent ability if out of charges
	if max_charges > 1:
		if current_charges <= 0:
			print("%s is out of charges!" % ability_name)
			return

		# ✅ Deduct charge **before execution**
		current_charges -= 1
		emit_signal("charge_restored", ability_name, current_charges)  # Signal UI update

		# ✅ Start charge replenishment **only if not full**
		if current_charges < max_charges and not charge_cooldown_active:
			_start_charge_recovery()

	# ✅ Apply cooldown **between uses** (whether charge-based or not)
	_start_cooldown()

	# ✅ Check Mana Cost
	if caster.mana_current < mana_cost:
		print("%s does not have enough mana to cast %s!" % [caster.display_name, ability_name])
		return

	# ✅ Deduct mana cost
	caster.mana_current -= mana_cost
	caster.emit_signal("mana_changed", caster.mana_current)

	# ✅ Handle cast time, channeling, or instant execution
	if cast_time > 0:
		_start_casting(caster)
	elif channel_duration > 0:
		_start_channeling(caster)
	else:
		_execute_ability(caster)


# 🔥 Execute the ability (override in child class)
func _execute_ability(_caster: BaseCharacter):
	push_error("BaseAbility::_execute_ability() should be overridden!")

# 🔥 Start Cast Time Delay
func _start_casting(caster: BaseCharacter):
	is_casting = true
	cast_remaining = cast_time
	emit_signal("cast_started", ability_name, cast_time)

	while cast_remaining > 0:
		await get_tree().create_timer(0.1).timeout
		cast_remaining -= 0.1
		emit_signal("cast_updated", ability_name, max(cast_remaining, 0.0))

		# ✅ Cancel if movement occurs and ability requires standing still
		if not cast_while_moving and caster.velocity.length() > 0:
			_cancel_cast("movement")
			return

	is_casting = false
	emit_signal("cast_finished", ability_name)
	_execute_ability(caster)
	if max_charges == 1:
		_start_cooldown()

# 🔥 Channeling Spells (Pushback & Interrupts)
func _start_channeling(caster: BaseCharacter):
	if channel_duration <= 0:
		return
	
	is_channeling = true
	channel_remaining = channel_duration
	total_pushback = 0.0
	emit_signal("channel_started", ability_name, channel_duration)

	while channel_remaining > 0:
		await get_tree().create_timer(0.1).timeout
		channel_remaining -= 0.1

		# ✅ Interrupt if movement occurs
		if not cast_while_moving and caster.velocity.length() > 0:
			interrupt_channel("movement")
			return

	is_channeling = false
	emit_signal("cast_finished", ability_name)
	_execute_ability(caster)
	if max_charges == 1:
		_start_cooldown()

# 🔥 Charge Replenishment (One at a Time)
func _start_charge_recovery():
	charge_cooldown_active = true
	while current_charges < max_charges:
		await get_tree().create_timer(charge_replenish_time).timeout
		current_charges = min(current_charges + 1, max_charges)
		print("%s charge restored! Now at: %d" % [ability_name, current_charges])
		emit_signal("charge_restored", ability_name, current_charges)
	charge_cooldown_active = false

# 🔥 Standard Cooldown (For Non-Charge Abilities)
func _start_cooldown():
	is_on_cooldown = true
	cooldown_remaining = cooldown_time
	emit_signal("cooldown_started", ability_name, cooldown_remaining)

	while cooldown_remaining > 0:
		await get_tree().create_timer(0.1).timeout
		cooldown_remaining -= 0.1
		emit_signal("cooldown_updated", ability_name, max(cooldown_remaining, 0.0))

	is_on_cooldown = false
	emit_signal("cooldown_finished", ability_name)

# 🔥 Cancel Cast
func _cancel_cast(reason: String):
	is_casting = false
	emit_signal("cast_interrupted", ability_name, reason)

# 🔥 Interrupt Channel
func interrupt_channel(reason: String):
	is_channeling = false
	emit_signal("channel_interrupted", ability_name, reason)
