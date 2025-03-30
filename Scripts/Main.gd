# GameSetup.gd
extends Node

@onready var combat_system: CombatSystem = $CombatSystem

func _ready() -> void:
	# Check if we're coming from the character selection screen
	if CombatantDatabase.get_selected_party().size() > 0 and CombatantDatabase.get_selected_enemies().size() > 0:
		# Use the selected combatants
		setup_selected_combatants()
	else:
		# Create default combatants for testing
		var combatants: Array[Combatant] = create_example_combatants()
		
		# Add all combatants as children (required for signals to work)
		for combatant in combatants:
			add_child(combatant)
		
		# Register combatants with the combat system
		combat_system.player_combatants = [combatants[0], combatants[1]]
		combat_system.cpu_combatants = [combatants[2], combatants[3]]
	
	# Start the combat
	combat_system.start()

func setup_selected_combatants() -> void:
	var player_combatants: Array[Combatant] = CombatantDatabase.get_selected_party()
	var enemy_combatants: Array[Combatant] = CombatantDatabase.get_selected_enemies()
	
	# Debug: Check abilities before initialization
	print("Checking abilities for player combatants:")
	for combatant in player_combatants:
		print(combatant.name + " has " + str(combatant.abilities.size()) + " abilities:")
		for ability in combatant.abilities:
			print("  - " + ability.name)
	
	print("Checking abilities for enemy combatants:")
	for combatant in enemy_combatants:
		print(combatant.name + " has " + str(combatant.abilities.size()) + " abilities:")
		for ability in combatant.abilities:
			print("  - " + ability.name)
	
	# Ensure all combatants have the correct is_player value
	for combatant in player_combatants:
		combatant.is_player = true
		print("Player combatant: " + combatant.name + " is_player=" + str(combatant.is_player))
	
	for combatant in enemy_combatants:
		combatant.is_player = false
		print("Enemy combatant: " + combatant.name + " is_player=" + str(combatant.is_player))
	
	# Add all combatants as children (required for signals to work)
	for combatant in player_combatants + enemy_combatants:
		# Initialize signals when adding as child
		combatant._ready()
		add_child(combatant)
	
	# Register combatants with the combat system
	combat_system.player_combatants = player_combatants
	combat_system.cpu_combatants = enemy_combatants

# Example of creating combatants with special abilities
func create_example_combatants() -> Array[Combatant]:
	# Create abilities using the factory
	var fire_attack: Ability = AbilityFactory.create_damage_ability(
		"Fire Attack", 
		15, 
		Ability.TargetType.ENEMY, 
		"Deals 15 fire damage to an enemy",
		"{user} conjures a ball of fire that strikes {target} for {power} damage!",
		10,
		Ability.DamageType.MAGICAL
	)
	
	var heal_spell: Ability = AbilityFactory.create_healing_ability(
		"Heal", 
		15, 
		Ability.TargetType.FRIENDLY, 
		"Heals an ally for 15 HP",
		"{user} channels healing energy to restore {power} HP to {target}!",
		15
	)
	
	var poison_ability: Ability = AbilityFactory.create_dot_ability(
		"Poison", 
		6,  # 6 damage per tick
		3,  # lasts 3 turns
		Ability.TargetType.ENEMY, 
		"Poisons an enemy, causing 6 damage for 3 turns",
		"{user} injects {target} with toxic venom that will deal damage for {duration} turns!",
		12,
		Ability.DamageType.MAGICAL
	)
	
	var regeneration_ability: Ability = AbilityFactory.create_hot_ability(
		"Regeneration", 
		5,  # 5 healing per tick
		4,  # lasts 4 turns
		Ability.TargetType.FRIENDLY, 
		"Regenerates 5 HP per turn for 4 turns",
		"{user} casts a regeneration spell on {target}, healing them for the next {duration} turns!",
		18
	)
	
	var self_buff: Ability = AbilityFactory.create_healing_ability(
		"Focus", 
		10, 
		Ability.TargetType.SELF, 
		"Concentrate to recover 10 HP",
		"{user} focuses their mind, recovering {power} HP!",
		5
	)
	
	var protect_ally: Ability = AbilityFactory.create_hot_ability(
		"Protect", 
		5, 
		3, 
		Ability.TargetType.OTHER_FRIENDLY, 
		"Cast a protection spell on an ally that heals 5 HP for 3 turns",
		"{user} surrounds {target} with a protective aura that will heal for {duration} turns!",
		15
	)
	
	var skip_turn: Ability = AbilityFactory.create_skip_turn_ability(
		"Skip Turn",
		"Skip this turn to conserve energy",
		"{user} takes a moment to observe the battlefield..."
	)
	
	# Create a wizard with these abilities
	var wizard: Combatant = Combatant.new()
	wizard.name = "Wizard"
	wizard.display_name = "Wizard"
	wizard.max_hp = 75
	wizard.current_hp = 75
	wizard.max_mp = 100
	wizard.current_mp = 100
	wizard.physical_attack = 5
	wizard.magic_attack = 20
	wizard.physical_defense = 6
	wizard.magic_defense = 15
	wizard.speed = 10
	wizard.is_player = true
	wizard.abilities = [fire_attack, heal_spell, poison_ability, regeneration_ability, skip_turn]
	
	# Create a cleric with healing abilities
	var cleric: Combatant = Combatant.new()
	cleric.name = "Cleric"
	cleric.display_name = "Cleric"
	cleric.max_hp = 90
	cleric.current_hp = 90
	cleric.max_mp = 85
	cleric.current_mp = 85
	cleric.physical_attack = 8
	cleric.magic_attack = 15
	cleric.physical_defense = 12
	cleric.magic_defense = 18
	cleric.speed = 7
	cleric.is_player = true
	cleric.abilities = [
		AbilityFactory.create_damage_ability(
			"Smite", 
			12, 
			Ability.TargetType.ENEMY, 
			"A holy attack", 
			"", 
			5, 
			Ability.DamageType.MAGICAL
		),
		heal_spell,
		protect_ally,
		regeneration_ability,
		skip_turn
	]
	
	# Create enemy goblin
	var goblin: Combatant = Combatant.new()
	goblin.name = "Goblin Scout"
	goblin.display_name = "Goblin Scout"
	goblin.max_hp = 60
	goblin.current_hp = 60
	goblin.max_mp = 20
	goblin.current_mp = 20
	goblin.physical_attack = 12
	goblin.magic_attack = 3
	goblin.physical_defense = 6
	goblin.magic_defense = 4
	goblin.speed = 12
	goblin.is_player = false
	goblin.abilities = [
		AbilityFactory.create_damage_ability(
			"Stab", 
			10, 
			Ability.TargetType.ENEMY, 
			"A quick stab attack"
		),
		AbilityFactory.create_dot_ability(
			"Toxic Blade", 
			4, 
			2, 
			Ability.TargetType.ENEMY, 
			"Applies a weak poison",
			"",
			5,
			Ability.DamageType.PHYSICAL
		)
	]
	
	# Create enemy orc
	var orc: Combatant = Combatant.new()
	orc.name = "Orc Bruiser"
	orc.display_name = "Orc Bruiser"
	orc.max_hp = 95
	orc.current_hp = 95
	orc.max_mp = 30
	orc.current_mp = 30
	orc.physical_attack = 18
	orc.magic_attack = 2
	orc.physical_defense = 12
	orc.magic_defense = 5
	orc.speed = 6
	orc.is_player = false
	orc.abilities = [
		AbilityFactory.create_damage_ability(
			"Club Smash", 
			18, 
			Ability.TargetType.ENEMY, 
			"A heavy club attack"
		),
		AbilityFactory.create_healing_ability(
			"Crude Potion", 
			12, 
			Ability.TargetType.SELF, 
			"Drinks a healing potion",
			"",
			8
		),
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
		"Burns the target for 5 damage over 3 turns",
		"",
		10,
		Ability.DamageType.MAGICAL
	)
	
	return fire_dot

# Return to character selection screen
func return_to_selection() -> void:
	get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")