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

# Stat modification properties
@export_group("Stat Modifications")
@export var modify_physical_attack: int = 0  # Positive for buff, negative for debuff
@export var modify_magic_attack: int = 0
@export var modify_physical_defense: int = 0
@export var modify_magic_defense: int = 0
@export var modify_speed: int = 0
@export var modify_max_hp: int = 0
@export var modify_max_mp: int = 0

@export var modification_type: int = 0  # 0 = flat, 1 = percent
@export var damage_dealt_percent_mod: float = 0.0  # % increase/decrease to damage dealt
@export var healing_dealt_percent_mod: float = 0.0  # % increase/decrease to healing dealt

# Creates a StatusEffect instance from this resource
# Update the create_status_effect_instance method to include the new properties
func create_status_effect_instance() -> StatusEffect:
    var effect = StatusEffect.new()
    # [existing code remains the same]
    
    # Add stat modifiers
    if modify_physical_attack != 0:
        effect.add_stat_modifier("physical_attack", modification_type, modify_physical_attack)
    
    if modify_magic_attack != 0:
        effect.add_stat_modifier("magic_attack", modification_type, modify_magic_attack)
    
    if modify_physical_defense != 0:
        effect.add_stat_modifier("physical_defense", modification_type, modify_physical_defense)
    
    if modify_magic_defense != 0:
        effect.add_stat_modifier("magic_defense", modification_type, modify_magic_defense)
    
    if modify_speed != 0:
        effect.add_stat_modifier("speed", modification_type, modify_speed)
    
    if modify_max_hp != 0:
        effect.add_stat_modifier("max_hp", modification_type, modify_max_hp)
    
    if modify_max_mp != 0:
        effect.add_stat_modifier("max_mp", modification_type, modify_max_mp)
    
    # Set damage and healing modifiers
    effect.damage_dealt_percent_mod = damage_dealt_percent_mod
    effect.healing_dealt_percent_mod = healing_dealt_percent_mod
    
    return effect