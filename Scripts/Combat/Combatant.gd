# Combatant.gd
class_name Combatant
extends RefCounted

signal hp_changed(new_hp, max_hp)
signal mp_changed(new_mp, max_mp)
signal status_effect_added(effect)
signal status_effect_removed(effect)
signal defeated()

# Base attributes
var resource: CombatantResource
var display_name: String
var is_player: bool
var icon: Texture2D

# Stats
var max_hp: int
var max_mp: int
var physical_attack: int
var magic_attack: int
var physical_defense: int
var magic_defense: int
var speed: int

# Current values
var current_hp: int
var current_mp: int

# Status effects
var status_effects: Array[StatusEffect] = []

# Damage resistances
var damage_resistances: Array[DamageTypeResource] = []

# Abilities
var abilities: Array[AbilityResource] = []

# Initialize from resource
func initialize(combatant_resource: CombatantResource, is_player_combatant: bool) -> void:
	resource = combatant_resource
	display_name = combatant_resource.display_name
	is_player = is_player_combatant
	icon = combatant_resource.icon
	
	# Set base stats
	max_hp = combatant_resource.base_hp
	max_mp = combatant_resource.base_mp
	physical_attack = combatant_resource.physical_attack
	magic_attack = combatant_resource.magic_attack
	physical_defense = combatant_resource.physical_defense
	magic_defense = combatant_resource.magic_defense
	speed = combatant_resource.speed
	
	# Set current values to max
	current_hp = max_hp
	current_mp = max_mp
	
	# Copy damage resistances
	for resistance in combatant_resource.damage_resistances:
		if resistance:
			damage_resistances.append(resistance)
	
	# Copy abilities
	for ability in combatant_resource.abilities:
		if ability:
			abilities.append(ability)

# Get modified stat value (base + all modifications from status effects)
func get_modified_stat(stat_name: String) -> int:
	var base_value = 0
	
	# Get base value
	match stat_name:
		"max_hp": base_value = max_hp
		"max_mp": base_value = max_mp
		"physical_attack": base_value = physical_attack
		"magic_attack": base_value = magic_attack
		"physical_defense": base_value = physical_defense
		"magic_defense": base_value = magic_defense
		"speed": base_value = speed
		_: return 0
	
	# Apply modifiers from status effects
	var modifier = 0
	for effect in status_effects:
		match stat_name:
			"max_hp": modifier += effect.modify_max_hp
			"max_mp": modifier += effect.modify_max_mp
			"physical_attack": modifier += effect.modify_physical_attack
			"magic_attack": modifier += effect.modify_magic_attack
			"physical_defense": modifier += effect.modify_physical_defense
			"magic_defense": modifier += effect.modify_magic_defense
			"speed": modifier += effect.modify_speed
	
	return max(1, base_value + modifier)  # Ensure no stat goes below 1

# Apply damage
func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	emit_signal("hp_changed", current_hp, get_modified_stat("max_hp"))
	
	if current_hp <= 0:
		emit_signal("defeated")

# Apply healing
func heal(amount: int) -> void:
	var max_hp_value = get_modified_stat("max_hp")
	current_hp = min(max_hp_value, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp_value)

# Restore MP
func restore_mp(amount: int) -> void:
	var max_mp_value = get_modified_stat("max_mp")
	current_mp = min(max_mp_value, current_mp + amount)
	emit_signal("mp_changed", current_mp, max_mp_value)

# Add a status effect to the combatant
func add_status_effect(effect: StatusEffect) -> void:
	# Handle stacking based on the effect's stacking behavior
	var existing_effect_index = -1
	for i in range(status_effects.size()):
		if status_effects[i].display_name == effect.display_name:
			existing_effect_index = i
			break
	
	if existing_effect_index >= 0:
		var existing_effect = status_effects[existing_effect_index]
		
		match effect.stacking_behavior:
			StatusEffectResource.StackingBehavior.REPLACE:
				# Remove old effect and add new one
				status_effects.remove_at(existing_effect_index)
				status_effects.append(effect)
				emit_signal("status_effect_removed", existing_effect)
				emit_signal("status_effect_added", effect)
				
			StatusEffectResource.StackingBehavior.REFRESH:
				# Just reset duration
				existing_effect.duration = effect.duration
				
			StatusEffectResource.StackingBehavior.ADD_DURATION:
				# Add durations together
				existing_effect.duration += effect.duration
				
			StatusEffectResource.StackingBehavior.STACK:
				# Add as a separate effect
				status_effects.append(effect)
				emit_signal("status_effect_added", effect)
	else:
		# No existing effect, just add it
		status_effects.append(effect)
		emit_signal("status_effect_added", effect)

# Process status effects based on trigger type
func process_status_effects(trigger_type: int) -> void:
	var effects_to_remove = []
	
	# Process all matching effects
	for effect in status_effects:
		if effect.trigger_type == trigger_type:
			# Apply effect based on its type (damage, healing, etc.)
			apply_effect_result(effect)
			
			# Reduce duration unless it's permanent (duration < 0)
			if effect.duration > 0:
				effect.duration -= 1
				if effect.duration <= 0:
					effects_to_remove.append(effect)
	
	# Remove expired effects
	for effect in effects_to_remove:
		remove_status_effect(effect)

# Apply the result of an effect (damage, healing, etc.)
func apply_effect_result(effect: StatusEffect) -> void:
	# Process recurring effects (DoT/HoT)
	if effect.recurring_effect_type == EffectResource.EffectType.Damage:
		# Damage over time
		take_damage(effect.recurring_effect_power)
	elif effect.recurring_effect_type == EffectResource.EffectType.Healing:
		# Healing over time
		heal(effect.recurring_effect_power)

# Remove a status effect
func remove_status_effect(effect: StatusEffect) -> void:
	var index = status_effects.find(effect)
	if index >= 0:
		status_effects.remove_at(index)
		emit_signal("status_effect_removed", effect)
		
		# Execute effect's expiry ability if it has one
		if effect.expiry_ability:
			# This would be handled by your ability system
			pass
