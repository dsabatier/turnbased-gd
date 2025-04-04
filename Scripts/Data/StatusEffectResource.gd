class_name StatusEffectResource
extends Resource

enum TriggerType {
	TURN_START,
	TURN_END,
	ON_DAMAGE_TAKEN,
	ON_HEALING_RECEIVED
}

enum StackingBehavior {
	REPLACE,        # New effect replaces the old one
	REFRESH,        # New effect refreshes the duration of existing effect
	ADD_DURATION,   # Add duration of new effect to existing effect
	STACK           # Allow multiple instances of the same effect
}

# Basic properties
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var duration: int = 1 # Number of turns this effect lasts
@export_enum("Turn Start", "Turn End", "On Damage Taken", "On Healing Received") var trigger_type: int = TriggerType.TURN_END


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

@export var critical_hit_chance: float = 0
@export var critical_hit_damage: float = 0
