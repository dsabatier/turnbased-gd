# Combatant.gd updated with stat modifier system
class_name Combatant
extends Node

signal defeated
signal hp_changed(current_hp, max_hp)
signal mp_changed(current_mp, max_mp)
signal status_effect_added(effect)
signal status_effect_removed(effect)
signal status_effect_triggered(effect, result)
signal damage_taken(amount, damage_type_id, flags)

# Basic combatant identification
@export var display_name: String
@export var is_player: bool

# Core stats (these are now BASE values)
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var physical_attack: int = 10
@export var magic_attack: int = 10
@export var physical_defense: int = 10
@export var magic_defense: int = 10
@export var speed: int = 10

# Damage resistances and weaknesses
# Values < 1.0 are resistances (0.5 = 50% less damage)
# Values > 1.0 are weaknesses (1.5 = 50% more damage)
# Value of 0 means immune
@export var damage_resistances: Dictionary = {}

# Current values
var current_hp: int
var current_mp: int
var abilities: Array[Ability] = []
var is_defeated: bool = false
var status_effects: Array[StatusEffect] = []

# Source resource reference
var source_resource: Resource = null

# Dictionary to store all stat modifiers
var stat_modifiers: Dictionary = {
	"physical_attack": [], # List of modifiers affecting physical_attack
	"magic_attack": [],    # List of modifiers affecting magic_attack
	"physical_defense": [], # List of modifiers affecting physical_defense
	"magic_defense": [],   # List of modifiers affecting magic_defense
	"speed": [],           # List of modifiers affecting speed
	"max_hp": [],          # List of modifiers affecting max_hp
	"max_mp": []           # List of modifiers affecting max_mp
}

func _ready():
	current_hp = max_hp
	current_mp = max_mp
	
	# Initialize display_name if not set
	if display_name == null or display_name.is_empty():
		display_name = name

# Get a combatant's resistance to a specific damage type
func get_damage_resistance(damage_type_id: String) -> float:
	if damage_resistances.has(damage_type_id):
		return damage_resistances[damage_type_id]
	# Default is 1.0 (normal damage)
	return 1.0

# Get the modified value of a stat after applying all modifiers
func get_stat(stat_name: String):
	# Get the base value
	var base_value = self.get(stat_name)
	
	# If we don't have modifiers for this stat, return base value
	if not stat_modifiers.has(stat_name):
		return base_value
		
	var flat_modifiers = 0
	var percent_modifiers = 0.0
	
	# Apply all modifiers
	for modifier in stat_modifiers[stat_name]:
		if modifier.type == StatusEffect.StatModificationType.FLAT:
			flat_modifiers += modifier.value
		else: # PERCENT
			percent_modifiers += modifier.value / 100.0
	
	# Calculate final value: (base + flat) * (1 + percent)
	var modified_value = (base_value + flat_modifiers) * (1.0 + percent_modifiers)
	
	# Ensure we're returning an integer for stats
	return int(modified_value)

# Add a stat modifier
func add_stat_modifier(stat_name: String, value: float, modification_type: int, source: StatusEffect) -> void:
	if not stat_modifiers.has(stat_name):
		return
		
	var modifier = {
		"value": value,
		"type": modification_type,
		"source": source
	}
	
	stat_modifiers[stat_name].append(modifier)
	print("Added modifier to %s: %s (source: %s)" % [stat_name, value, source.name])

# Remove all stat modifiers from a specific source
func remove_stat_modifiers_from_source(source: StatusEffect) -> void:
	for stat_name in stat_modifiers.keys():
		var i = stat_modifiers[stat_name].size() - 1
		while i >= 0:
			if stat_modifiers[stat_name][i].source == source:
				stat_modifiers[stat_name].remove_at(i)
				print("Removed modifier from %s (source: %s)" % [stat_name, source.name])
			i -= 1

# Get effective stats with modifiers applied
func get_effective_physical_attack() -> int:
	return get_stat("physical_attack")
	
func get_effective_magic_attack() -> int:
	return get_stat("magic_attack")
	
func get_effective_physical_defense() -> int:
	return get_stat("physical_defense")
	
func get_effective_magic_defense() -> int:
	return get_stat("magic_defense")
	
func get_effective_speed() -> int:
	return get_stat("speed")
	
func get_effective_max_hp() -> int:
	return get_stat("max_hp")
	
func get_effective_max_mp() -> int:
	return get_stat("max_mp")

# Take damage with an optional damage type
func take_damage(amount: int, damage_type_id: String = "physical") -> int:
	# Apply damage
	current_hp = max(0, current_hp - amount)
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("damage_taken", amount, damage_type_id, {})
	
	if current_hp == 0 and not is_defeated:
		is_defeated = true
		emit_signal("defeated")
	
	# Trigger ON_DAMAGE_TAKEN effects 
	var effect_results = trigger_status_effects(StatusEffect.TriggerType.ON_DAMAGE_TAKEN)
	
	# Return the actual damage dealt
	return amount

func heal(amount: int, source = null) -> void:
	var old_hp = current_hp
	current_hp = min(get_effective_max_hp(), current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)
	
	# Trigger ON_HEALING_RECEIVED effects
	trigger_status_effects(StatusEffect.TriggerType.ON_HEALING_RECEIVED)

func use_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		emit_signal("mp_changed", current_mp, max_mp)
		return true
	return false
	
func restore_mp(amount: int) -> int:
	# Store original amount for return value
	var original_amount = amount
	
	# Calculate effective max MP
	var effective_max = get_effective_max_mp()
	
	# Apply any MP restoration modifiers from status effects
	# This would allow future status effects to boost MP regeneration
	var mp_modifier = 1.0
	for effect in status_effects:
		if effect.has_method("get") and effect.get("mp_restoration_mod") != null:
			mp_modifier += effect.mp_restoration_mod / 100.0
	
	# Apply the modifier to the amount
	amount = int(amount * mp_modifier)
	
	# Update MP, capped at max
	var old_mp = current_mp
	current_mp = min(effective_max, current_mp + amount)
	
	# Calculate actual MP restored
	var actual_restored = current_mp - old_mp
	
	# Emit signal for UI updates
	emit_signal("mp_changed", current_mp, effective_max)
	
	# Return the actual amount restored (for logging)
	return actual_restored

# Use an ability
func use_ability(ability_index: int, target = null) -> String:
	if is_defeated:
		return "%s is defeated and cannot act!" % display_name
		
	# Validate ability index
	if ability_index < 0 or ability_index >= abilities.size():
		return "%s tried to use an invalid ability!" % display_name
	
	var ability = abilities[ability_index]
	
	# Check for null ability
	if ability == null:
		return "%s tried to use a null ability!" % display_name
	
	# Check if we have enough MP to use this ability
	var mp_cost = 0
	if ability.has_method("get") and ability.get("mp_cost") != null:
		mp_cost = ability.mp_cost
		
	if mp_cost > 0 and current_mp < mp_cost:
		return "%s doesn't have enough MP to use %s!" % [display_name, ability.name]
	
	# Handle SELF target type automatically
	if ability.target_type == Ability.TargetType.SELF:
		# Consume MP if needed (unless it's an MP restore ability)
		if mp_cost > 0 and ability.effect_type != Ability.EffectType.MP_RESTORE:
			use_mp(mp_cost)
			
		# Try to get the damage manager from the scene
		var damage_manager = null
		if Engine.has_singleton("DamageTypeManager"):
			damage_manager = Engine.get_singleton("DamageTypeManager")
			
		return ability.execute(self, self, damage_manager)
	
	# Ensure target is provided for non-SELF abilities
	if target == null:
		return "No target selected for %s!" % ability.name
	
	# Check if the ability can target the selected target
	if (ability.target_type == Ability.TargetType.ENEMY and target.is_player == is_player) or \
	   (ability.target_type == Ability.TargetType.FRIENDLY and target.is_player != is_player) or \
	   (ability.target_type == Ability.TargetType.OTHER_FRIENDLY and (target.is_player != is_player or target == self)):
		return "Invalid target for %s!" % ability.name
	
	# Consume MP if needed
	if mp_cost > 0:
		use_mp(mp_cost)
	
	# Try to get the damage manager from the scene
	var damage_manager = null
	if Engine.has_singleton("DamageTypeManager"):
		damage_manager = Engine.get_singleton("DamageTypeManager")
		
	print("Executing ability: " + ability.name + " on target: " + target.display_name)
	return ability.execute(self, target, damage_manager)
	
# AI logic for CPU-controlled combatants
func choose_action(friendlies: Array, enemies: Array):
	if is_defeated:
		return null
	
	# Simple AI that randomly chooses an ability and a valid target
	var valid_abilities = []
	for i in range(abilities.size()):
		var ability = abilities[i]
		
		# Skip null abilities
		if ability == null:
			continue
			
		# Check MP cost safely
		var mp_cost = 0
		if ability.has_method("get") and ability.get("mp_cost") != null:
			mp_cost = ability.mp_cost
			
		if mp_cost <= current_mp:
			valid_abilities.append(i)
	
	if valid_abilities.size() == 0:
		print("No valid abilities found for " + name)
		return null
		
	var ability_index = valid_abilities[randi() % valid_abilities.size()]
	
	# Double-check that the ability exists (belt and suspenders approach)
	if ability_index >= abilities.size():
		print("Invalid ability index: " + str(ability_index))
		return null
		
	var ability = abilities[ability_index]
	
	# Another null check for safety
	if ability == null:
		print("Null ability at index: " + str(ability_index))
		return null
	
	# Handle SELF target type immediately
	if ability.target_type == Ability.TargetType.SELF:
		return {
			"ability": ability_index,
			"target": self
		}
	
	var possible_targets = []
	if ability.target_type == Ability.TargetType.ENEMY:
		possible_targets = enemies.filter(func(enemy): return not enemy.is_defeated)
	elif ability.target_type == Ability.TargetType.FRIENDLY:
		possible_targets = friendlies.filter(func(friendly): return not friendly.is_defeated)
	elif ability.target_type == Ability.TargetType.OTHER_FRIENDLY:
		possible_targets = friendlies.filter(func(friendly): return not friendly.is_defeated and friendly != self)
	else:
		# For "any" target type
		possible_targets = friendlies + enemies
		possible_targets = possible_targets.filter(func(combatant): return not combatant.is_defeated)
	
	if possible_targets.size() == 0:
		print("No valid targets found for ability: " + ability.name)
		return null
	
	var target_index = randi() % possible_targets.size()
	var target = possible_targets[target_index]
	
	return {
		"ability": ability_index,
		"target": target
	}

# Status effect management
func add_status_effect(effect: StatusEffect) -> void:
	print(effect.name)
	# The effect's apply method now handles stacking behavior
	status_effects.append(effect)
	effect.effect_expired.connect(_on_status_effect_expired)
	
	# Apply stat modifiers from this effect
	if effect.modify_physical_attack != 0:
		add_stat_modifier("physical_attack", effect.modify_physical_attack, effect.modification_type, effect)
	
	if effect.modify_magic_attack != 0:
		add_stat_modifier("magic_attack", effect.modify_magic_attack, effect.modification_type, effect)
	
	if effect.modify_physical_defense != 0:
		add_stat_modifier("physical_defense", effect.modify_physical_defense, effect.modification_type, effect)
	
	if effect.modify_magic_defense != 0:
		add_stat_modifier("magic_defense", effect.modify_magic_defense, effect.modification_type, effect)
	
	if effect.modify_speed != 0:
		add_stat_modifier("speed", effect.modify_speed, effect.modification_type, effect)
	
	if effect.modify_max_hp != 0:
		add_stat_modifier("max_hp", effect.modify_max_hp, effect.modification_type, effect)
	
	if effect.modify_max_mp != 0:
		add_stat_modifier("max_mp", effect.modify_max_mp, effect.modification_type, effect)
	
	emit_signal("status_effect_added", effect)
	print("Added status effect: " + effect.name + " to " + display_name)
	print("Effect modifies speed by: " + str(effect.modify_speed) + "%")

func remove_status_effect(effect: StatusEffect) -> void:
	if effect in status_effects:
		# Remove all stat modifiers from this effect
		remove_stat_modifiers_from_source(effect)
		
		status_effects.erase(effect)
		if effect.is_connected("effect_expired", _on_status_effect_expired):
			effect.disconnect("effect_expired", _on_status_effect_expired)
		emit_signal("status_effect_removed", effect)
		print("Removed status effect: " + effect.name + " from " + display_name)

# Handle status effect expiration with possible additional effects
func _on_status_effect_expired(effect: StatusEffect) -> void:
	remove_status_effect(effect)

func trigger_status_effects(trigger: int) -> Array[String]:
	var results : Array[String] = []
	
	# Create a copy of the array since effects might be removed during iteration
	var effects_to_trigger = status_effects.duplicate()
	
	for effect in effects_to_trigger:
		if effect.trigger_type == trigger:
			var result = effect.trigger()
			if result != "":
				results.append(result)
				emit_signal("status_effect_triggered", effect, result)
	
	return results