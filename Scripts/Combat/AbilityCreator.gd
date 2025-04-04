# AbilityCreator.gd
class_name AbilityCreator
extends Node

# This utility class creates basic abilities for demo combatants
# Could be integrated with CombatantDatabase._create_demo_combatants to assign abilities

static func create_basic_abilities() -> Dictionary:
	var abilities = {}
	
	# Player abilities
	abilities["fireball"] = create_fireball()
	abilities["heal"] = create_heal()
	abilities["power_strike"] = create_power_strike()
	abilities["shield"] = create_shield()
	abilities["lightning_bolt"] = create_lightning_bolt()
	abilities["ice_spike"] = create_ice_spike()
	abilities["backstab"] = create_backstab()
	abilities["cure"] = create_cure()
	
	# Enemy abilities
	abilities["poison_bite"] = create_poison_bite()
	abilities["shadow_blast"] = create_shadow_blast()
	abilities["crush"] = create_crush()
	
	return abilities

static func create_fireball() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Fireball"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "Launches a ball of fire dealing damage to an enemy."
	ability.custom_message = "{user} launches a fireball at {target}!"
	ability.mp_cost = 15
	return ability
	
static func create_heal() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Heal"
	ability.target_type = AbilityResource.TargetType.FRIENDLY
	ability.description = "Restores HP to an ally."
	ability.custom_message = "{user} heals {target}!"
	ability.mp_cost = 20
	return ability

static func create_power_strike() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Power Strike"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "A powerful attack that deals extra physical damage."
	ability.custom_message = "{user} unleashes a powerful strike on {target}!"
	ability.mp_cost = 10
	return ability

static func create_shield() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Shield"
	ability.target_type = AbilityResource.TargetType.FRIENDLY
	ability.description = "Increases the target's defense for 3 turns."
	ability.custom_message = "{user} grants a protective shield to {target}!"
	ability.mp_cost = 12
	return ability

static func create_lightning_bolt() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Lightning Bolt"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "Strikes an enemy with lightning dealing magic damage."
	ability.custom_message = "{user} calls down lightning on {target}!"
	ability.mp_cost = 18
	return ability

static func create_ice_spike() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Ice Spike"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "Impales an enemy with ice, dealing damage and reducing speed."
	ability.custom_message = "{user} launches an ice spike at {target}!"
	ability.mp_cost = 16
	return ability

static func create_backstab() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Backstab"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "A surprise attack with a high chance to critically hit."
	ability.custom_message = "{user} backstabs {target}!"
	ability.mp_cost = 12
	return ability

static func create_cure() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Cure"
	ability.target_type = AbilityResource.TargetType.FRIENDLY
	ability.description = "Removes negative status effects from an ally."
	ability.custom_message = "{user} cures {target} of ailments!"
	ability.mp_cost = 14
	return ability

static func create_poison_bite() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Poison Bite"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "A venomous bite that deals damage and poisons the target."
	ability.custom_message = "{user} delivers a venomous bite to {target}!"
	ability.mp_cost = 8
	return ability

static func create_shadow_blast() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Shadow Blast"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "Dark energy that deals magic damage."
	ability.custom_message = "{user} unleashes dark energy at {target}!"
	ability.mp_cost = 12
	return ability

static func create_crush() -> AbilityResource:
	var ability = AbilityResource.new()
	ability.display_name = "Crush"
	ability.target_type = AbilityResource.TargetType.ENEMY
	ability.description = "A devastating blow that reduces the target's defense."
	ability.custom_message = "{user} crushes {target}!"
	ability.mp_cost = 15
	return ability
