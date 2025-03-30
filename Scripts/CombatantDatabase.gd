# CombatantDatabase.gd
extends Node

# Autoload singleton to manage combatants

# Strong typing for our arrays
var all_combatants: Array[Combatant] = []
var selected_party: Array[Combatant] = []
var selected_enemies: Array[Combatant] = []

func _ready() -> void:
	# Initialize the database with premade combatants
	create_default_combatants()

func load_ability_from_resource(path: String) -> Ability:
	var resource = load(path)
	if resource is AbilityResource:
		return resource.create_ability_instance()

	printerr("Failed to load ability from resource: " + path)
	return null

func create_default_combatants() -> void:
	# Try to load combatants from resources first
	var resource_path = "res://Resources/Combatants/"
	var dir = DirAccess.open(resource_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var combatant = load_combatant_from_resource(resource_path + file_name)
				if combatant:
					all_combatants.append(combatant)
					print("Loaded combatant from resource: " + file_name)
			file_name = dir.get_next()
	
	# If no resources were loaded or directory doesn't exist, fall back to code-created combatants
	if all_combatants.size() == 0:
		print("No combatant resources found. Creating default combatants in code.")
		
		# Create default warrior
		var warrior: Combatant = Combatant.new()
		warrior.name = "Warrior"
		warrior.max_hp = 120
		warrior.max_mp = 40
		warrior.physical_attack = 20
		warrior.magic_attack = 5
		warrior.physical_defense = 18
		warrior.magic_defense = 8
		warrior.speed = 8
		warrior.is_player = true
		warrior.abilities = [
			AbilityFactory.create_damage_ability("Slash", 15, Ability.TargetType.ENEMY, "A strong sword slash"),
			AbilityFactory.create_damage_ability("Heavy Strike", 25, Ability.TargetType.ENEMY, "A powerful but slower attack", "", 10),
			AbilityFactory.create_damage_reduction_ability("Defend", 30, 2, Ability.TargetType.SELF, "Prepare to block incoming attacks", "", 5)
		]
		all_combatants.append(warrior)
		
		# Create default wizard
		var wizard: Combatant = Combatant.new()
		wizard.name = "Wizard"
		wizard.max_hp = 70
		wizard.max_mp = 100
		wizard.physical_attack = 5
		wizard.magic_attack = 22
		wizard.physical_defense = 6
		wizard.magic_defense = 15
		wizard.speed = 10
		wizard.is_player = true
		wizard.abilities = [
			AbilityFactory.create_damage_ability(
				"Fireball", 
				20, 
				Ability.TargetType.ENEMY, 
				"A ball of fire", 
				"", 
				10, 
				Ability.DamageType.MAGICAL
			),
			AbilityFactory.create_dot_ability(
				"Poison", 
				8, 
				3, 
				Ability.TargetType.ENEMY, 
				"Poisons enemy for 3 turns", 
				"", 
				15, 
				Ability.DamageType.MAGICAL
			)
		]
		all_combatants.append(wizard)
		
		# Create default enemies
		var goblin: Combatant = Combatant.new()
		goblin.name = "Goblin"
		goblin.max_hp = 50
		goblin.max_mp = 20
		goblin.physical_attack = 8
		goblin.magic_attack = 3
		goblin.physical_defense = 5
		goblin.magic_defense = 5
		goblin.speed = 12
		goblin.is_player = false
		goblin.abilities = [
			AbilityFactory.create_damage_ability(
				"Stab", 
				8, 
				Ability.TargetType.ENEMY, 
				"A quick stab with a dagger"
			),
			AbilityFactory.create_skip_turn_ability("Retreat", "Temporary retreat to safety")
		]
		all_combatants.append(goblin)
		
		var orc: Combatant = Combatant.new()
		orc.name = "Orc"
		orc.max_hp = 100
		orc.max_mp = 30
		orc.physical_attack = 15
		orc.magic_attack = 2
		orc.physical_defense = 12
		orc.magic_defense = 5
		orc.speed = 6
		orc.is_player = false
		orc.abilities = [
			AbilityFactory.create_damage_ability(
				"Axe Swing", 
				15, 
				Ability.TargetType.ENEMY, 
				"A powerful axe swing"
			),
			AbilityFactory.create_damage_ability(
				"Battle Cry", 
				5, 
				Ability.TargetType.ENEMY, 
				"A terrifying shout",
				"",
				0,
				Ability.DamageType.MAGICAL
			)
		]
		all_combatants.append(orc)

func get_all_combatants() -> Array[Combatant]:
	# We need to do a proper deep copy of combatants
	var combatants_copy: Array[Combatant] = []
	
	for combatant in all_combatants:
		var new_combatant: Combatant = Combatant.new()
		new_combatant.name = combatant.name
		new_combatant.display_name = combatant.display_name if combatant.display_name else combatant.name
		
		# Copy all stats
		new_combatant.max_hp = combatant.max_hp
		new_combatant.max_mp = combatant.max_mp
		new_combatant.physical_attack = combatant.physical_attack
		new_combatant.magic_attack = combatant.magic_attack
		new_combatant.physical_defense = combatant.physical_defense
		new_combatant.magic_defense = combatant.magic_defense
		new_combatant.speed = combatant.speed
		
		new_combatant.current_hp = combatant.max_hp
		new_combatant.current_mp = combatant.max_mp
		new_combatant.is_player = combatant.is_player
		
		# Copy abilities
		new_combatant.abilities = []
		for ability in combatant.abilities:
			new_combatant.abilities.append(ability)
		
		combatants_copy.append(new_combatant)
	
	return combatants_copy

func set_selected_party(party: Array[Combatant]) -> void:
	selected_party = party

func set_selected_enemies(enemies: Array[Combatant]) -> void:
	selected_enemies = enemies

func get_selected_party() -> Array[Combatant]:
	return selected_party

func get_selected_enemies() -> Array[Combatant]:
	return selected_enemies

func load_combatant_from_resource(path: String) -> Combatant:
	var resource = load(path)
	if resource is CombatantResource:
		return resource.create_combatant_instance()

	printerr("Failed to load combatant from resource: " + path)
	return null