# AbilityResource.gd
class_name AbilityResource
extends Resource

# Enums (same as in Ability.gd for compatibility)
enum TargetType {ENEMY, FRIENDLY, SELF, OTHER_FRIENDLY, ANY}
enum EffectType {DAMAGE, HEALING, STATUS, UTILITY, MULTI, MP_RESTORE}

# Core properties
@export var display_name: String = ""
@export_enum("Enemy", "Friendly", "Self", "Other Friendly", "Any") var target_type: int = TargetType.ENEMY
@export_multiline var description: String = ""

@export var custom_message: String = ""
@export var mp_cost: int = 0
