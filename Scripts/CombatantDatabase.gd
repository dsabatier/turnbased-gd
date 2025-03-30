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

func create_default_combatants() -> void:
	# PLAYER CHARACTER OPTIONS
	
	# Warrior - High physical attack and defense, low magic, average speed
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
	
	# Wizard - High magic attack, low physical defense, good speed
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

	var explosion_damage = AbilityFactory.create_damage_ability(
		"Explosion", 
		20, 
		Ability.TargetType.ENEMY, 
		"An explosion of fire",
		"{target} is engulfed in a fiery explosion for {power} damage!",
		0,  # No extra MP cost because this is triggered by another spell
		Ability.DamageType.MAGICAL
	)

	# Now create a status effect that applies this damage when it expires
	var fire_trap = AbilityFactory.create_status_effect_with_expiry(
		"Fire Trap",
		3,  # Duration of 3 turns
		Ability.TargetType.ENEMY,
		"Target is surrounded by magical fire that will explode after 3 turns",
		StatusEffect.TriggerType.TURN_END,  # Trigger at end of turn
		AbilityFactory.create_dot_ability(
			"Burning", 
			5, 
			1, 
			Ability.TargetType.ENEMY, 
			"Burns for 5 damage",
			"",
			0,
			Ability.DamageType.MAGICAL
		),  # Applied each turn
		explosion_damage,  # Applied when effect expires
		StatusEffect.StackingBehavior.REPLACE,  # Replace if already applied
		"{user} surrounds {target} with a ring of fire that will explode in {duration} turns!",
		15  # MP cost for the main ability
	)

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
		),
		fire_trap,
		AbilityFactory.create_skip_turn_ability("Meditate", "Restore 15 MP")
	]
	all_combatants.append(wizard)
	
	# Cleric - Balanced stats with focus on healing and magic defense
	var cleric: Combatant = Combatant.new()
	cleric.name = "Cleric"
	cleric.max_hp = 90
	cleric.max_mp = 85
	cleric.physical_attack = 8
	cleric.magic_attack = 15
	cleric.physical_defense = 12
	cleric.magic_defense = 18
	cleric.speed = 7
	cleric.is_player = true
	cleric.abilities = [
		AbilityFactory.create_damage_ability(
			"Smite", 
			15, 
			Ability.TargetType.ENEMY, 
			"A holy attack", 
			"", 
			5, 
			Ability.DamageType.MAGICAL
		),
		AbilityFactory.create_healing_ability(
			"Heal", 
			20, 
			Ability.TargetType.FRIENDLY, 
			"Heals an ally", 
			"", 
			10
		),
		AbilityFactory.create_hot_ability(
			"Regeneration", 
			8, 
			3, 
			Ability.TargetType.FRIENDLY, 
			"Healing over time", 
			"", 
			15
		),
		AbilityFactory.create_damage_reduction_ability(
			"Protect", 
			25, 
			3, 
			Ability.TargetType.FRIENDLY, 
			"Reduces damage taken by 25%", 
			"", 
			20
		)
	]
	all_combatants.append(cleric)
	
	# Rogue - High speed, good physical attack, low defenses
	var rogue: Combatant = Combatant.new()
	rogue.name = "Rogue"
	rogue.max_hp = 75
	rogue.max_mp = 60
	rogue.physical_attack = 18
	rogue.magic_attack = 6
	rogue.physical_defense = 10
	rogue.magic_defense = 10
	rogue.speed = 20
	rogue.is_player = true
	rogue.abilities = [
		AbilityFactory.create_damage_ability(
			"Backstab", 
			22, 
			Ability.TargetType.ENEMY, 
			"A surprise attack from behind", 
			"", 
			8, 
			Ability.DamageType.PHYSICAL
		),
		AbilityFactory.create_dot_ability(
			"Bleed", 
			7, 
			4, 
			Ability.TargetType.ENEMY, 
			"Causes bleeding for 4 turns", 
			"", 
			12, 
			Ability.DamageType.PHYSICAL
		),
		AbilityFactory.create_damage_ability(
			"Kidney Shot", 
			15, 
			Ability.TargetType.ENEMY, 
			"A critical strike to a vital area", 
			"{user} strikes {target}'s weak point for {power} damage!", 
			15, 
			Ability.DamageType.PURE
		),
		AbilityFactory.create_skip_turn_ability("Hide", "Hide in the shadows")
	]
	all_combatants.append(rogue)
	
	# Ranger - Balanced physical stats with good speed
	var ranger: Combatant = Combatant.new()
	ranger.name = "Ranger"
	ranger.max_hp = 85
	ranger.max_mp = 70
	ranger.physical_attack = 16
	ranger.magic_attack = 10
	ranger.physical_defense = 12
	ranger.magic_defense = 12
	ranger.speed = 15
	ranger.is_player = true
	ranger.abilities = [
		AbilityFactory.create_damage_ability(
			"Precise Shot", 
			18, 
			Ability.TargetType.ENEMY, 
			"A precisely aimed arrow", 
			"", 
			5, 
			Ability.DamageType.PHYSICAL
		),
		AbilityFactory.create_damage_ability(
			"Quick Shot", 
			12, 
			Ability.TargetType.ENEMY, 
			"A rapid arrow shot"
		),
		AbilityFactory.create_multi_effect_ability(
			"Poison Arrow",
			Ability.TargetType.ENEMY,
			"An arrow coated with poison that deals damage and applies a poison effect",
			[
				AbilityFactory.create_damage_ability(
					"Arrow Strike", 
					10, 
					Ability.TargetType.ENEMY, 
					"Initial arrow damage",
					"",
					0,
					Ability.DamageType.PHYSICAL
				),
				AbilityFactory.create_dot_ability(
					"Arrow Poison", 
					5, 
					3, 
					Ability.TargetType.ENEMY, 
					"Poison applied by the arrow",
					"",
					0,
					Ability.DamageType.MAGICAL
				)
			],
			"{user} shoots a poison-tipped arrow at {target}!",
			12
		),
		AbilityFactory.create_skip_turn_ability("Aim", "Carefully aim your next shot")
	]
	all_combatants.append(ranger)
	
	# ENEMY OPTIONS
	
	# Goblin - Fast but weak
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
	
	# Orc - Strong physical attacker with low speed
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
	
	# Wolf - Very fast with decent physical attack
	var wolf: Combatant = Combatant.new()
	wolf.name = "Wolf"
	wolf.max_hp = 60
	wolf.max_mp = 0
	wolf.physical_attack = 12
	wolf.magic_attack = 0
	wolf.physical_defense = 8
	wolf.magic_defense = 8
	wolf.speed = 18
	wolf.is_player = false
	wolf.abilities = [
		AbilityFactory.create_damage_ability(
			"Bite", 
			12, 
			Ability.TargetType.ENEMY, 
			"A vicious bite"
		),
		AbilityFactory.create_dot_ability(
			"Maul", 
			4, 
			3, 
			Ability.TargetType.ENEMY, 
			"Causes bleeding for 3 turns"
		)
	]
	all_combatants.append(wolf)
	
	# Skeleton - Balanced stats, resistant to physical damage
	var skeleton: Combatant = Combatant.new()
	skeleton.name = "Skeleton"
	skeleton.max_hp = 70
	skeleton.max_mp = 0
	skeleton.physical_attack = 10
	skeleton.magic_attack = 0
	skeleton.physical_defense = 15
	skeleton.magic_defense = 5
	skeleton.speed = 7
	skeleton.is_player = false
	skeleton.abilities = [
		AbilityFactory.create_damage_ability(
			"Bone Strike", 
			10, 
			Ability.TargetType.ENEMY, 
			"A strike with a bone club"
		),
		AbilityFactory.create_damage_ability(
			"Bone Throw", 
			8, 
			Ability.TargetType.ENEMY, 
			"Throws a bone"
		)
	]
	all_combatants.append(skeleton)
	
	# Dark Mage - High magic attacker
	var dark_mage: Combatant = Combatant.new()
	dark_mage.name = "Dark Mage"
	dark_mage.max_hp = 65
	dark_mage.max_mp = 80
	dark_mage.physical_attack = 3
	dark_mage.magic_attack = 18
	dark_mage.physical_defense = 5
	dark_mage.magic_defense = 15
	dark_mage.speed = 8
	dark_mage.is_player = false
	dark_mage.abilities = [
		AbilityFactory.create_damage_ability(
			"Shadow Bolt", 
			14, 
			Ability.TargetType.ENEMY, 
			"A bolt of dark energy",
			"",
			5,
			Ability.DamageType.MAGICAL
		),
		AbilityFactory.create_dot_ability(
			"Curse", 
			6, 
			3, 
			Ability.TargetType.ENEMY, 
			"A curse that deals damage over time",
			"",
			10,
			Ability.DamageType.MAGICAL
		)
	]
	all_combatants.append(dark_mage)
	
	# Giant Spider - Fast with poison attacks
	var spider: Combatant = Combatant.new()
	spider.name = "Giant Spider"
	spider.max_hp = 75
	spider.max_mp = 40
	spider.physical_attack = 12
	spider.magic_attack = 8
	spider.physical_defense = 10
	spider.magic_defense = 10
	spider.speed = 14
	spider.is_player = false
	spider.abilities = [
		AbilityFactory.create_damage_ability(
			"Bite", 
			10, 
			Ability.TargetType.ENEMY, 
			"A venomous bite"
		),
		AbilityFactory.create_dot_ability(
			"Web", 
			5, 
			4, 
			Ability.TargetType.ENEMY, 
			"Ensnares target in sticky web",
			"",
			8,
			Ability.DamageType.MAGICAL
		)
	]
	all_combatants.append(spider)
	
	# Troll - High HP and physical attack, slow
	var troll: Combatant = Combatant.new()
	troll.name = "Troll"
	troll.max_hp = 150
	troll.max_mp = 30
	troll.physical_attack = 18
	troll.magic_attack = 0
	troll.physical_defense = 15
	troll.magic_defense = 5
	troll.speed = 5
	troll.is_player = false
	troll.abilities = [
		AbilityFactory.create_damage_ability(
			"Club Smash", 
			20, 
			Ability.TargetType.ENEMY, 
			"A devastating club strike"
		),
		AbilityFactory.create_healing_ability(
			"Regenerate", 
			15, 
			Ability.TargetType.SELF, 
			"Regenerates some health",
			"",
			10
		)
	]
	all_combatants.append(troll)
	
	# Dragon - Strong in all stats with powerful abilities
	var dragon: Combatant = Combatant.new()
	dragon.name = "Dragon"
	dragon.max_hp = 200
	dragon.max_mp = 100
	dragon.physical_attack = 20
	dragon.magic_attack = 20
	dragon.physical_defense = 20
	dragon.magic_defense = 20
	dragon.speed = 10
	dragon.is_player = false
	dragon.abilities = [
		AbilityFactory.create_damage_ability(
			"Fire Breath", 
			25, 
			Ability.TargetType.ENEMY, 
			"A blast of fire",
			"",
			15,
			Ability.DamageType.MAGICAL
		),
		AbilityFactory.create_damage_ability(
			"Tail Swipe", 
			18, 
			Ability.TargetType.ENEMY, 
			"A powerful tail swipe",
			"",
			0,
			Ability.DamageType.PHYSICAL
		),
		AbilityFactory.create_dot_ability(
			"Inferno", 
			10, 
			3, 
			Ability.TargetType.ENEMY, 
			"Sets target on fire",
			"",
			20,
			Ability.DamageType.MAGICAL
		)
	]
	all_combatants.append(dragon)

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