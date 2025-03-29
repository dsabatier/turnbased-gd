# AbilityFactory.gd
class_name AbilityFactory
extends Node

# Create a basic damage ability
static func create_damage_ability(name: String, power: int, target_type: int, description: String, custom_message: String = "") -> Ability:
	var ability = Ability.new()
	ability.name = name
	ability.power = power
	ability.target_type = target_type
	ability.description = description
	ability.effect_type = Ability.EffectType.DAMAGE
	
	if custom_message != "":
		ability.custom_message = custom_message
		
	return ability

# Create a basic healing ability
static func create_healing_ability(name: String, power: int, target_type: int, description: String, custom_message: String = "") -> Ability:
	var ability = Ability.new()
	ability.name = name
	ability.power = power
	ability.target_type = target_type
	ability.description = description
	ability.effect_type = Ability.EffectType.HEALING
	
	if custom_message != "":
		ability.custom_message = custom_message
		
	return ability

# Create a skip turn ability
static func create_skip_turn_ability(name: String, description: String, custom_message: String = "") -> Ability:
	var ability = Ability.new()
	ability.name = name
	ability.power = 0  # No direct effect on HP
	ability.target_type = Ability.TargetType.SELF  # Only affects the caster
	ability.description = description
	ability.effect_type = Ability.EffectType.UTILITY
	
	if custom_message != "":
		ability.custom_message = custom_message
		
	return ability

# Create a damage over time ability
static func create_dot_ability(name: String, damage_per_tick: int, duration: int, target_type: int, description: String, custom_message: String = "") -> Ability:
	# First create the damage ability that will be applied on each tick
	var damage_ability = Ability.new()
	damage_ability.name = name + " (DoT)"
	damage_ability.power = damage_per_tick
	damage_ability.target_type = target_type
	damage_ability.effect_type = Ability.EffectType.DAMAGE
	damage_ability.custom_message = "{target} takes {power} damage from {effect}"
	
	# Create the status effect
	var status = StatusEffect.new()
	status.name = name + " Effect"
	status.description = "Taking %d damage at the end of each turn for %d turns" % [damage_per_tick, duration]
	status.duration = duration
	status.trigger_type = StatusEffect.TriggerType.TURN_END
	status.ability = damage_ability
	
	# Create the ability that applies the status effect
	var ability = Ability.new()
	ability.name = name
	ability.target_type = target_type
	ability.description = description
	ability.effect_type = Ability.EffectType.STATUS
	ability.status_effect = status
	
	# Set custom message if provided
	if custom_message != "":
		ability.custom_message = custom_message
	
	return ability

# Create a heal over time ability
static func create_hot_ability(name: String, healing_per_tick: int, duration: int, target_type: int, description: String, custom_message: String = "") -> Ability:
	# First create the healing ability that will be applied on each tick
	var healing_ability = Ability.new()
	healing_ability.name = name + " (HoT)"
	healing_ability.power = healing_per_tick
	healing_ability.target_type = target_type
	healing_ability.effect_type = Ability.EffectType.HEALING
	
	# Create the status effect
	var status = StatusEffect.new()
	status.name = name + " Effect"
	status.description = "Healing %d HP at the start of each turn for %d turns" % [healing_per_tick, duration]
	status.duration = duration
	status.trigger_type = StatusEffect.TriggerType.TURN_START
	status.ability = healing_ability
	
	# Create the ability that applies the status effect
	var ability = Ability.new()
	ability.name = name
	ability.target_type = target_type
	ability.description = description
	ability.effect_type = Ability.EffectType.STATUS
	ability.status_effect = status
	
	# Set custom message if provided
	if custom_message != "":
		ability.custom_message = custom_message
	
	return ability