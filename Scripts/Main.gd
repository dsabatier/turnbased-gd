# GameSetup.gd
extends Node

@onready var combat_system: CombatSystem = $CombatSystem

func _ready() -> void:
	# Create combatants
	var combatants: Array[Combatant] = create_example_combatants()
	
	# Add all combatants as children (required for signals to work)
	for combatant in combatants:
		add_child(combatant)
	
	# Register combatants with the combat system
	combat_system.player_combatants = [combatants[0], combatants[1]]
	combat_system.cpu_combatants = [combatants[2], combatants[3]]
	
	# Start the combat
	combat_system.start()

# Example of creating combatants with special abilities
func create_example_combatants() -> Array[Combatant]:
	# Create abilities using the factory
	var fire_attack: Ability = AbilityFactory.create_damage_ability(
		"Fire Attack", 
		20, 
		Ability.TargetType.ENEMY, 
		"Deals 20 fire damage to an enemy",
		"{user} conjures a ball of fire that strikes {target} for {power} damage!"
	)
	
	var heal_spell: Ability = AbilityFactory.create_healing_ability(
		"Heal", 
		15, 
		Ability.TargetType.FRIENDLY, 
		"Heals an ally for 15 HP",
		"{user} channels healing energy to restore {power} HP to {target}!"
	)
	
	var poison_ability: Ability = AbilityFactory.create_dot_ability(
		"Poison", 
		8,  # 8 damage per tick
		3,  # lasts 3 turns
		Ability.TargetType.ENEMY, 
		"Poisons an enemy, causing 8 damage for 3 turns",
		"{user} injects {target} with toxic venom that will deal damage for {duration} turns!"
	)
	
	var regeneration_ability: Ability = AbilityFactory.create_hot_ability(
		"Regeneration", 
		6,  # 6 healing per tick
		4,  # lasts 4 turns
		Ability.TargetType.FRIENDLY, 
		"Regenerates 6 HP per turn for 4 turns",
		"{user} casts a regeneration spell on {target}, healing them for the next {duration} turns!"
	)
	
	var self_buff: Ability = AbilityFactory.create_healing_ability(
		"Focus", 
		10, 
		Ability.TargetType.SELF, 
		"Concentrate to recover 10 HP",
		"{user} focuses their mind, recovering {power} HP!"
	)
	
	var protect_ally: Ability = AbilityFactory.create_hot_ability(
		"Protect", 
		5, 
		3, 
		Ability.TargetType.OTHER_FRIENDLY, 
		"Cast a protection spell on an ally that heals 5 HP for 3 turns",
		"{user} surrounds {target} with a protective aura that will heal for {duration} turns!"
	)
	
	var skip_turn: Ability = AbilityFactory.create_skip_turn_ability(
		"Skip Turn",
		"Skip this turn to conserve energy",
		"{user} takes a moment to observe the battlefield..."
	)
	
	# Create a wizard with these abilities
	var wizard: Combatant = Combatant.new()
	wizard.name = "Wizard"
	wizard.max_hp = 75
	wizard.current_hp = 75
	wizard.speed = 10
	wizard.is_player = true
	wizard.abilities = [fire_attack, heal_spell, poison_ability, regeneration_ability, skip_turn]
	
	# Create a cleric with healing abilities
	var cleric: Combatant = Combatant.new()
	cleric.name = "Cleric"
	cleric.max_hp = 90
	cleric.current_hp = 90
	cleric.speed = 8
	cleric.is_player = true
	cleric.abilities = [
		AbilityFactory.create_damage_ability("Smite", 15, Ability.TargetType.ENEMY, "A holy attack"),
		heal_spell,
		protect_ally,
		regeneration_ability,
		skip_turn
	]
	
	# Create enemy goblin
	var goblin: Combatant = Combatant.new()
	goblin.name = "Goblin Scout"
	goblin.max_hp = 60
	goblin.current_hp = 60
	goblin.speed = 12
	goblin.is_player = false
	goblin.abilities = [
		AbilityFactory.create_damage_ability("Stab", 12, Ability.TargetType.ENEMY, "A quick stab attack"),
		AbilityFactory.create_dot_ability("Toxic Blade", 5, 2, Ability.TargetType.ENEMY, "Applies a weak poison")
	]
	
	# Create enemy orc
	var orc: Combatant = Combatant.new()
	orc.name = "Orc Bruiser"
	orc.max_hp = 85
	orc.current_hp = 85
	orc.speed = 6
	orc.is_player = false
	orc.abilities = [
		AbilityFactory.create_damage_ability("Club Smash", 20, Ability.TargetType.ENEMY, "A heavy club attack"),
		AbilityFactory.create_healing_ability("Crude Potion", 15, Ability.TargetType.SELF, "Drinks a healing potion"),
		self_buff
	]
	
	return [wizard, cleric, goblin, orc]

# For testing specific ability types
func create_test_ability() -> Ability:
	# Example of creating a complex multi-effect ability
	
	# Create a damage ability that applies a DoT effect
	var fire_dot: Ability = AbilityFactory.create_dot_ability(
		"Burning", 
		5, 
		3, 
		Ability.TargetType.ENEMY,
		"Burns the target for 5 damage over 3 turns"
	)
	
	# Create a stun ability (placeholder - would need additional status effect type)
	var stun_ability: Ability = Ability.new()
	stun_ability.name = "Stun"
	stun_ability.target_type = Ability.TargetType.ENEMY
	stun_ability.description = "Prevents the target from acting for 1 turn"
	stun_ability.effect_type = Ability.EffectType.STATUS
	
	# Example of loading from resources instead of creating in code
	# This would require saving ability resources first
	# var special_ability: Ability = load("res://resources/abilities/special_attack.tres")
	
	return fire_dot

# For initializing a predefined battle scenario
func setup_boss_battle() -> void:
	# Create boss enemy
	var boss: Combatant = Combatant.new()
	boss.name = "Dark Lord"
	boss.max_hp = 200
	boss.current_hp = 200
	boss.speed = 5
	boss.is_player = false
	
	# Create boss abilities
	var dark_blast: Ability = AbilityFactory.create_damage_ability(
		"Dark Blast",
		30,
		Ability.TargetType.ENEMY,
		"A powerful blast of dark energy"
	)
	
	var life_drain: Ability = AbilityFactory.create_damage_ability(
		"Life Drain",
		20,
		Ability.TargetType.ENEMY,
		"Drains life from the target to heal the caster"
	)
	
	# Add abilities to boss
	boss.abilities = [dark_blast, life_drain]
	
	# Create player party
	var player_party: Array[Combatant] = create_example_combatants()
	
	# Setup combat with boss
	for combatant in player_party:
		add_child(combatant)
	add_child(boss)
	
	combat_system.player_combatants = [player_party[0], player_party[1]]
	combat_system.cpu_combatants = [boss]
	
	combat_system.start()