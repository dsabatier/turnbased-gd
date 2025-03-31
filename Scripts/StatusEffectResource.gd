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
@export_enum("None", "Apply Ability") var expiry_behavior: int = ExpiryBehavior.NONE
@export_enum("Replace", "Refresh", "Add Duration", "Stack") var stacking_behavior: int = StackingBehavior.REPLACE
@export var expiry_ability: Resource # AbilityResource reference for when effect expires

# Stat modification properties
@export_group("Stat Modifications")
@export var modify_physical_attack: int = 0  # Positive for buff, negative for debuff
@export var modify_magic_attack: int = 0
@export var modify_physical_defense: int = 0
@export var modify_magic_defense: int = 0
@export var modify_speed: int = 0
@export var modify_max_hp: int = 0
@export var modify_max_mp: int = 0

@export var modification_type: StatusEffect.StatModificationType = StatusEffect.StatModificationType.FLAT
@export var damage_reduction_percent: float = 0
@export var damage_dealt_percent_mod: float = 0.0  # % increase/decrease to damage dealt
@export var healing_dealt_percent_mod: float = 0.0  # % increase/decrease to healing dealt

# Creates a StatusEffect instance from this resource
func create_status_effect_instance() -> StatusEffect:
    var effect = StatusEffect.new()
    
    # Set basic properties
    effect.name = name
    effect.description = description
    effect.duration = duration
    effect.remaining_turns = duration
    effect.trigger_type = trigger_type
    
    # Set behavior properties
    effect.expiry_behavior = expiry_behavior
    effect.stacking_behavior = stacking_behavior
    
    # Handle ability reference
    if ability is AbilityResource:
        effect.ability = ability.create_ability_instance()
    elif ability is Ability:
        effect.ability = ability
    
    # Handle expiry ability reference
    if expiry_ability is AbilityResource:
        effect.expiry_ability = expiry_ability.create_ability_instance()
    elif expiry_ability is Ability:
        effect.expiry_ability = expiry_ability
    
    # Set stat modification values
    effect.modify_physical_attack = modify_physical_attack
    effect.modify_magic_attack = modify_magic_attack
    effect.modify_physical_defense = modify_physical_defense
    effect.modify_magic_defense = modify_magic_defense
    effect.modify_speed = modify_speed
    effect.modify_max_hp = modify_max_hp
    effect.modify_max_mp = modify_max_mp
    effect.modification_type = modification_type
    
    # Set damage and healing modifiers
    effect.damage_reduction_percent = damage_reduction_percent
    effect.damage_dealt_percent_mod = damage_dealt_percent_mod
    effect.healing_dealt_percent_mod = healing_dealt_percent_mod
    
    # Store reference to this resource
    effect.source_resource = self
    
    print("Created status effect instance from resource: " + name)
    print("Speed modifier: " + str(modify_speed) + "%")
    
    return effect