# StatusEffect.gd
class_name StatusEffect
extends Resource

signal effect_expired(effect)

enum TriggerType {
	TURN_START,
	TURN_END,
	ON_DAMAGE_TAKEN,
	ON_HEALING_RECEIVED
}

enum EffectBehavior {
	APPLY_ABILITY,  # Default behavior - applies the ability
	REDUCE_DAMAGE   # Special behavior for damage reduction
}

enum ExpiryBehavior {
	NONE,           # Nothing special happens when effect expires
	APPLY_ABILITY   # Apply another ability when this effect expires
}

enum StackingBehavior {
	REPLACE,        # New effect replaces the old one
	REFRESH,        # New effect refreshes the duration of existing effect
	ADD_DURATION,   # Add duration of new effect to existing effect
	STACK           # Allow multiple instances of the same effect
}

# Stat modification properties
enum StatModificationType {
	FLAT,    # Add/subtract a flat value
	PERCENT  # Modify by a percentage
}

# Tracks which stats this effect modifies
class StatModifier:
	var stat_name: String = ""  # "physical_attack", "magic_defense", etc.
	var modification_type: int = StatModificationType.FLAT
	var value: float = 0.0
	var applied: bool = false   # Tracks if this modifier has been applied
	
	func _init(stat: String, mod_type: int, val: float):
		stat_name = stat
		modification_type = mod_type
		value = val
		
	# Apply the modification to a combatant
	func apply(combatant: Combatant) -> void:
		if applied:
			return
			
		# Store original value if not already tracked
		if not combatant.has_meta("original_" + stat_name):
			combatant.set_meta("original_" + stat_name, combatant.get(stat_name))
		
		var original_value = combatant.get_meta("original_" + stat_name)
		var new_value = original_value
		
		if modification_type == StatModificationType.FLAT:
			new_value = original_value + value
		else:  # PERCENT
			new_value = original_value * (1 + value / 100.0)
		
		# Apply the new value
		combatant.set(stat_name, new_value)
		applied = true
		
		print("Applied " + stat_name + " modifier: " + str(value) + 
			  " (original: " + str(original_value) + ", new: " + str(new_value) + ")")
	
	# Remove the modification from a combatant
	func remove(combatant: Combatant) -> void:
		if not applied:
			return
			
		# Only restore if we have the original value
		if combatant.has_meta("original_" + stat_name):
			var original_value = combatant.get_meta("original_" + stat_name)
			combatant.set(stat_name, original_value)
			applied = false
			
			print("Removed " + stat_name + " modifier, restored to: " + str(original_value))

# Add these as properties to the StatusEffect class
@export var stat_modifiers: Array = []  # Will store StatModifier instances
var damage_dealt_percent_mod: float = 0.0  # % increase/decrease to damage dealt
var healing_dealt_percent_mod: float = 0.0  # % increase/decrease to healing dealt

# Add this method to initialize a stat modifier
func add_stat_modifier(stat_name: String, modification_type: int, value: float) -> void:
	var modifier = StatModifier.new(stat_name, modification_type, value)
	stat_modifiers.append(modifier)

# Add this to the apply method, after the return statement
func apply_stat_modifiers() -> void:
	if target_combatant == null:
		return
		
	for modifier in stat_modifiers:
		modifier.apply(target_combatant)

# Add this to the clean-up code when an effect expires or is removed
func remove_stat_modifiers() -> void:
	if target_combatant == null:
		return
		
	for modifier in stat_modifiers:
		modifier.remove(target_combatant)

@export var name: String
@export var description: String
@export var duration: int # Number of turns this effect lasts
@export var trigger_type: TriggerType
@export var ability: Ability # The ability to apply when triggered

# Enhanced status effects properties
@export var effect_behavior: EffectBehavior = EffectBehavior.APPLY_ABILITY
@export var expiry_behavior: ExpiryBehavior = ExpiryBehavior.NONE
@export var stacking_behavior: StackingBehavior = StackingBehavior.REPLACE
@export var expiry_ability: Ability = null # The ability to apply when this effect expires
@export var damage_reduction_percent: int = 0 # For damage reduction effects

# Runtime properties (not exported)
var source_combatant: Combatant # Who applied this status effect
var remaining_turns: int
var target_combatant: Combatant # Who the effect is applied to
var unique_id: String = "" # Used to identify specific instances when stacking

# Reference to source resource (if created from a resource)
var source_resource: Resource = null

func _init():
	remaining_turns = duration
	# Generate a unique ID for this instance
	unique_id = str(randi())

# Updated apply method for StatusEffect.gd
func apply(target: Combatant, source: Combatant):
	target_combatant = target
	source_combatant = source
	remaining_turns = duration
	
	# Check if target already has this effect
	var existing_effect = find_existing_effect(target)
	
	if existing_effect != null:
		# Handle according to stacking behavior
		match stacking_behavior:
			StackingBehavior.REPLACE:
				# Remove the old effect and apply this one
				target.remove_status_effect(existing_effect)
				target.add_status_effect(self)
				# Apply stat modifiers
				apply_stat_modifiers()
				return "%s's %s was replaced with a new instance!" % [target.display_name, name]
				
			StackingBehavior.REFRESH:
				# Refresh the duration of the existing effect
				existing_effect.remaining_turns = duration
				return "%s's %s duration was refreshed to %d turns!" % [target.display_name, name, duration]
				
			StackingBehavior.ADD_DURATION:
				# Add this effect's duration to the existing effect
				existing_effect.remaining_turns += duration
				return "%s's %s duration was extended by %d turns to %d turns!" % [
					target.display_name, 
					name, 
					duration,
					existing_effect.remaining_turns
				]
				
			StackingBehavior.STACK:
				# Add this as a new instance
				target.add_status_effect(self)
				# Apply stat modifiers
				apply_stat_modifiers()
				return "%s was affected by another instance of %s for %d turns!" % [target.display_name, name, duration]
	else:
		# No existing effect, just add this one
		target.add_status_effect(self)
		# Apply stat modifiers
		apply_stat_modifiers()
		return "%s was affected by %s for %d turns!" % [target.display_name, name, duration]
		

# Find an existing effect of the same type on the target
func find_existing_effect(target: Combatant) -> StatusEffect:
	for effect in target.status_effects:
		# Compare by name to find effects of the same type
		if effect.name == name and effect != self:
			return effect
	return null


func trigger(damage = null):
	if remaining_turns <= 0:
		return ""
	
	var result = ""
	
	match effect_behavior:
		EffectBehavior.APPLY_ABILITY:
			if ability != null:
				# Make sure source and target combatants are valid
				if source_combatant != null and target_combatant != null:
					result = ability.execute(source_combatant, target_combatant)
				else:
					# Handle missing combatants gracefully
					var source_name = source_combatant.name if source_combatant else "Unknown"
					var target_name = target_combatant.name if target_combatant else "Unknown"
					result = "Effect failed: missing source or target combatant"
			else:
				result = "Effect has no ability to apply"
				
		EffectBehavior.REDUCE_DAMAGE:
			# For damage reduction, we'll modify the input damage parameter
			if damage != null:
				var reduction = int(float(damage) * (damage_reduction_percent / 100.0))
				var reduced_damage = max(damage - reduction, 0)
				
				# Handle potential null target
				var target_name = "Unknown"
				if target_combatant != null:
					target_name = target_combatant.display_name
				
				result = "%s's %s reduced damage from %d to %d!" % [
					target_name, 
					name, 
					damage, 
					reduced_damage
				]
				return reduced_damage
	
	# Decrement remaining duration
	remaining_turns -= 1
	
	# Check if effect has expired
	if remaining_turns <= 0:
		# Get display name with proper fallbacks
		var target_name = "Unknown"
		if target_combatant != null:
			target_name = target_combatant.display_name
			
		var expiry_message = "%s has worn off from %s!" % [name, target_name]
		
		# Handle expiry behavior
		if expiry_behavior == ExpiryBehavior.APPLY_ABILITY and expiry_ability != null:
			# Make sure source and target combatants are valid
			if source_combatant != null and target_combatant != null:
				var expiry_result = expiry_ability.execute(source_combatant, target_combatant)
				expiry_message += "\n" + expiry_result
			else:
				expiry_message += "\nCouldn't apply expiry effect due to missing combatants"
		
		emit_signal("effect_expired", self)
		return result + "\n" + expiry_message
	
	# Check if effect has expired
	if remaining_turns <= 0:
		# Get display name with proper fallbacks
		var target_name = "Unknown"
		if target_combatant != null:
			target_name = target_combatant.display_name
			
		var expiry_message = "%s has worn off from %s!" % [name, target_name]
		
		# Remove stat modifiers when the effect expires
		remove_stat_modifiers()
		
		# Handle expiry behavior
		if expiry_behavior == ExpiryBehavior.APPLY_ABILITY and expiry_ability != null:
			# Make sure source and target combatants are valid
			if source_combatant != null and target_combatant != null:
				var expiry_result = expiry_ability.execute(source_combatant, target_combatant)
				expiry_message += "\n" + expiry_result
			else:
				expiry_message += "\nCouldn't apply expiry effect due to missing combatants"
		
		emit_signal("effect_expired", self)
		return result + "\n" + expiry_message
		
	return result

# Method specifically for damage reduction effects 
func reduce_damage(damage_amount):
	if effect_behavior != EffectBehavior.REDUCE_DAMAGE:
		return damage_amount
	
	# Calculate reduction/increase
	var modification_factor = damage_reduction_percent / 100.0
	var modified_damage = damage_amount
	
	if damage_reduction_percent >= 0:
		# Positive percentage means damage reduction
		var reduction = int(float(damage_amount) * modification_factor)
		modified_damage = max(damage_amount - reduction, 0)
		print("Reducing damage by " + str(damage_reduction_percent) + "%: " + str(damage_amount) + " -> " + str(modified_damage))
	else:
		# Negative percentage means damage increase
		var increase = int(float(damage_amount) * abs(modification_factor))
		modified_damage = damage_amount + increase
		print("Increasing damage by " + str(abs(damage_reduction_percent)) + "%: " + str(damage_amount) + " -> " + str(modified_damage))
	
	return modified_damage

# Method to create a duplicate with the same properties
func create_duplicate() -> StatusEffect:
	var newStatusEffect = StatusEffect.new()
	newStatusEffect.name = name
	newStatusEffect.description = description
	newStatusEffect.duration = duration
	newStatusEffect.trigger_type = trigger_type
	newStatusEffect.ability = ability
	newStatusEffect.effect_behavior = effect_behavior
	newStatusEffect.expiry_behavior = expiry_behavior
	newStatusEffect.stacking_behavior = stacking_behavior
	newStatusEffect.expiry_ability = expiry_ability
	newStatusEffect.damage_reduction_percent = damage_reduction_percent
	newStatusEffect.unique_id = str(randi()) # Generate a new unique ID
	newStatusEffect.remaining_turns = duration
	newStatusEffect.source_resource = source_resource
	return newStatusEffect

# Static method to create a status effect from a resource
static func from_resource(effect_resource: StatusEffectResource) -> StatusEffect:
	if effect_resource == null:
		return null
	return effect_resource.create_status_effect_instance()

# Check if this status effect was created from a resource
func is_from_resource() -> bool:
	return source_resource != null