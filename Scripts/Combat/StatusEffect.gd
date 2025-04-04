# StatusEffect.gd
class_name StatusEffect
extends RefCounted

# Basic properties
var display_name: String = ""
var description: String = ""
var duration: int = 1 # Number of turns this effect lasts
var trigger_type: int = StatusEffectResource.TriggerType.TURN_END
var stacking_behavior: int = StatusEffectResource.StackingBehavior.REPLACE
var expiry_ability = null # Reference to ability that triggers when effect expires

# Stat modification properties
var modify_physical_attack: int = 0
var modify_magic_attack: int = 0
var modify_physical_defense: int = 0
var modify_magic_defense: int = 0
var modify_speed: int = 0
var modify_max_hp: int = 0
var modify_max_mp: int = 0

# Additional modifiers
var critical_hit_chance: float = 0
var critical_hit_damage: float = 0

# Recurring effect properties (for DoT/HoT)
var recurring_effect_type: int = -1  # -1 for none, otherwise use EffectType enum
var recurring_effect_power: int = 0
var recurring_effect_damage_type: String = "physical"

# Initialize from a resource
func initialize_from_resource(resource: StatusEffectResource) -> void:
	display_name = resource.display_name
	description = resource.description
	duration = resource.duration
	trigger_type = resource.trigger_type
	stacking_behavior = resource.stacking_behavior
	expiry_ability = resource.expiry_ability
	
	# Copy stat modifiers
	modify_physical_attack = resource.modify_physical_attack
	modify_magic_attack = resource.modify_magic_attack
	modify_physical_defense = resource.modify_physical_defense
	modify_magic_defense = resource.modify_magic_defense
	modify_speed = resource.modify_speed
	modify_max_hp = resource.modify_max_hp
	modify_max_mp = resource.modify_max_mp
	
	critical_hit_chance = resource.critical_hit_chance
	critical_hit_damage = resource.critical_hit_damage

# Initialize a basic effect manually
func initialize_basic(name: String, desc: String, turns: int) -> void:
	display_name = name
	description = desc
	duration = turns

# Create a copy of this effect
func duplicate() -> StatusEffect:
	var copy = StatusEffect.new()
	
	copy.display_name = display_name
	copy.description = description
	copy.duration = duration
	copy.trigger_type = trigger_type
	copy.stacking_behavior = stacking_behavior
	copy.expiry_ability = expiry_ability
	
	copy.modify_physical_attack = modify_physical_attack
	copy.modify_magic_attack = modify_magic_attack
	copy.modify_physical_defense = modify_physical_defense
	copy.modify_magic_defense = modify_magic_defense
	copy.modify_speed = modify_speed
	copy.modify_max_hp = modify_max_hp
	copy.modify_max_mp = modify_max_mp
	
	copy.critical_hit_chance = critical_hit_chance
	copy.critical_hit_damage = critical_hit_damage
	
	copy.recurring_effect_type = recurring_effect_type
	copy.recurring_effect_power = recurring_effect_power
	copy.recurring_effect_damage_type = recurring_effect_damage_type
	
	return copy

# Set this as a damage over time effect
func set_as_dot(damage_per_turn: int, damage_type: String = "physical") -> void:
	recurring_effect_type = EffectResource.EffectType.Damage
	recurring_effect_power = damage_per_turn
	recurring_effect_damage_type = damage_type

# Set this as a healing over time effect
func set_as_hot(healing_per_turn: int) -> void:
	recurring_effect_type = EffectResource.EffectType.Healing
	recurring_effect_power = healing_per_turn
