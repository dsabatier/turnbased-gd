# AbilityResource.gd
class_name AbilityResource
extends Resource

# Enums (same as in Ability.gd for compatibility)
enum TargetType {ENEMY, FRIENDLY, SELF, OTHER_FRIENDLY, ANY}
enum EffectType {DAMAGE, HEALING, STATUS, UTILITY, MULTI, MP_RESTORE}

# Core properties
@export var name: String = ""
@export var power: int = 0
@export_enum("Enemy", "Friendly", "Self", "Other Friendly", "Any") var target_type: int = TargetType.ENEMY
@export_multiline var description: String = ""
@export_enum("Damage", "Healing", "Status", "Utility", "Multi-Effect", "MP") var effect_type: int = EffectType.DAMAGE
@export var custom_message: String = ""
@export var mp_cost: int = 0

# Use DamageTypeResource instead of string ID
@export var damage_type: Resource = null  # DamageTypeResource reference
# Keep for backward compatibility during transition
@export var damage_type_id: String = "physical"  # Used if damage_type is null

# Status effect properties
@export var status_effect: Resource # StatusEffectResource reference

# Multi-effect abilities
@export var additional_effects: Array[Resource] = [] # Can contain AbilityResource or StatusEffectResource
@export var apply_all_effects: bool = true

# Optional icon for UI display
@export var icon: Texture2D

# Creates an Ability instance from this resource
func create_ability_instance() -> Ability:
    var ability = Ability.new()
    ability.name = name
    ability.power = power
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = effect_type
    ability.custom_message = custom_message
    ability.mp_cost = mp_cost
    ability.source_resource = self
    
    # Set damage type - prefer the resource but fall back to ID
    ability.damage_type = damage_type
    if damage_type != null and damage_type is DamageTypeResource:
        ability.damage_type_id = damage_type.id
    else:
        ability.damage_type_id = damage_type_id
    
    # Handle status effects if present
    if status_effect != null and status_effect is StatusEffectResource:
        ability.status_effect = status_effect.create_status_effect_instance()
    
    # Handle additional effects
    ability.additional_effects = []
    ability.apply_all_effects = apply_all_effects
    
    for effect in additional_effects:
        if effect is AbilityResource:
            ability.additional_effects.append(effect.create_ability_instance())
        elif effect is StatusEffectResource:
            ability.additional_effects.append(effect.create_status_effect_instance())
    
    return ability