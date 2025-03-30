# AbilityResource.gd
class_name AbilityResource
extends Resource

# Enums (same as in Ability.gd for compatibility)
enum TargetType {ENEMY, FRIENDLY, SELF, OTHER_FRIENDLY, ANY}
enum EffectType {DAMAGE, HEALING, STATUS, UTILITY, MULTI}
enum DamageType {PHYSICAL, MAGICAL, PURE} # Pure damage bypasses defenses

# Core properties
@export var name: String = ""
@export var power: int = 0
@export_enum("Enemy", "Friendly", "Self", "Other Friendly", "Any") var target_type: int = TargetType.ENEMY
@export_multiline var description: String = ""
@export_enum("Damage", "Healing", "Status", "Utility", "Multi-Effect") var effect_type: int = EffectType.DAMAGE
@export var custom_message: String = ""
@export var mp_cost: int = 0
@export_enum("Physical", "Magical", "Pure") var damage_type: int = DamageType.PHYSICAL

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
    ability.damage_type = damage_type
    ability.source_resource = self
    
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