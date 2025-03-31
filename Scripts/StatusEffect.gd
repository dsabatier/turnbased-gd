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

@export var name: String
@export var description: String
@export var duration: int # Number of turns this effect lasts
@export var trigger_type: TriggerType
@export var ability: Ability # The ability to apply when triggered

# Enhanced status effects properties
@export var expiry_behavior: ExpiryBehavior = ExpiryBehavior.NONE
@export var stacking_behavior: StackingBehavior = StackingBehavior.REPLACE
@export var expiry_ability: Ability = null # The ability to apply when this effect expires

# Direct stat modification values
var modify_physical_attack: float = 0
var modify_magic_attack: float = 0
var modify_physical_defense: float = 0
var modify_magic_defense: float = 0
var modify_speed: float = 0
var modify_max_hp: float = 0
var modify_max_mp: float = 0
var modification_type: StatModificationType = StatModificationType.PERCENT

# Damage modifiers
var damage_reduction_percent: float = 0
var damage_dealt_percent_mod: float = 0.0  # % increase/decrease to damage dealt
var healing_dealt_percent_mod: float = 0.0  # % increase/decrease to healing dealt

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
				return "%s was affected by another instance of %s for %d turns!" % [target.display_name, name, duration]
	else:
		# No existing effect, just add this one
		target.add_status_effect(self)
		return "%s was affected by %s for %d turns!" % [target.display_name, name, duration]

# Find an existing effect of the same type on the target
func find_existing_effect(target: Combatant) -> StatusEffect:
	for effect in target.status_effects:
		# Compare by name to find effects of the same type
		if effect.name == name and effect != self:
			return effect
	return null

func trigger():
	print("Triggering status effect " + name)
	if remaining_turns <= 0:
		return ""
	
	var result = ""
	
	# Apply ability if one is set
	if ability != null:
		# Make sure source and target combatants are valid
		if source_combatant != null and target_combatant != null:
			result = ability.execute(source_combatant, target_combatant)
		else:
			# Handle missing combatants gracefully
			var source_name = source_combatant.name if source_combatant else "Unknown"
			var target_name = target_combatant.name if target_combatant else "Unknown"
			result = "Effect failed: missing source or target combatant"
	
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
		
	return result

# Method to create a duplicate with the same properties
func create_duplicate() -> StatusEffect:
	var newStatusEffect = StatusEffect.new()
	newStatusEffect.name = name
	newStatusEffect.description = description
	newStatusEffect.duration = duration
	newStatusEffect.trigger_type = trigger_type
	newStatusEffect.ability = ability
	newStatusEffect.expiry_behavior = expiry_behavior
	newStatusEffect.stacking_behavior = stacking_behavior
	newStatusEffect.expiry_ability = expiry_ability
	newStatusEffect.unique_id = str(randi()) # Generate a new unique ID
	newStatusEffect.remaining_turns = duration
	newStatusEffect.source_resource = source_resource
	
	# Copy stat modifiers
	newStatusEffect.modify_physical_attack = modify_physical_attack
	newStatusEffect.modify_magic_attack = modify_magic_attack
	newStatusEffect.modify_physical_defense = modify_physical_defense
	newStatusEffect.modify_magic_defense = modify_magic_defense
	newStatusEffect.modify_speed = modify_speed
	newStatusEffect.modify_max_hp = modify_max_hp
	newStatusEffect.modify_max_mp = modify_max_mp
	newStatusEffect.modification_type = modification_type
	
	# Copy damage/healing modifiers
	newStatusEffect.damage_reduction_percent = damage_reduction_percent
	newStatusEffect.damage_dealt_percent_mod = damage_dealt_percent_mod
	newStatusEffect.healing_dealt_percent_mod = healing_dealt_percent_mod
	
	return newStatusEffect

# Static method to create a status effect from a resource
static func from_resource(effect_resource: StatusEffectResource) -> StatusEffect:
	if effect_resource == null:
		return null
	return effect_resource.create_status_effect_instance()

# Check if this status effect was created from a resource
func is_from_resource() -> bool:
	return source_resource != null
