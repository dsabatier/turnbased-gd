# StatusEffectResource.gd
class_name StatusEffectResource
extends Resource

# Enums (same as in StatusEffect.gd for compatibility)
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

# Basic properties
@export var name: String = ""
@export_multiline var description: String = ""
@export var duration: int = 1 # Number of turns this effect lasts
@export_enum("Turn Start", "Turn End", "On Damage Taken", "On Healing Received") var trigger_type: int = TriggerType.TURN_END
@export var ability: Resource # AbilityResource reference

# Enhanced status effect properties
@export_enum("Apply Ability", "Reduce Damage") var effect_behavior: int = EffectBehavior.APPLY_ABILITY
@export_enum("None", "Apply Ability") var expiry_behavior: int = ExpiryBehavior.NONE
@export_enum("Replace", "Refresh", "Add Duration", "Stack") var stacking_behavior: int = StackingBehavior.REPLACE
@export var expiry_ability: Resource # AbilityResource reference for when effect expires
@export_range(0, 100) var damage_reduction_percent: int = 0 # For damage reduction effects

# Creates a StatusEffect instance from this resource
func create_status_effect_instance() -> StatusEffect:
    var effect = StatusEffect.new()
    effect.name = name
    effect.description = description
    effect.duration = duration
    effect.trigger_type = trigger_type
    effect.effect_behavior = effect_behavior
    effect.expiry_behavior = expiry_behavior
    effect.stacking_behavior = stacking_behavior
    effect.damage_reduction_percent = damage_reduction_percent
    
    # Set ability if present
    if ability != null and ability is AbilityResource:
        effect.ability = ability.create_ability_instance()
    
    # Set expiry ability if present
    if expiry_ability != null and expiry_ability is AbilityResource:
        effect.expiry_ability = expiry_ability.create_ability_instance()
    
    # Initialize remaining turns
    effect.remaining_turns = duration
    
    return effect