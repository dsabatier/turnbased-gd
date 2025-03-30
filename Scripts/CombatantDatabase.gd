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
	
	# Warrior
	var warrior: Combatant = Combatant.new()
	warrior.name = "Warrior"
	warrior.max_hp = 100
	warrior.current_hp = 100
	warrior.speed = 8
	warrior.is_player = true
	warrior.abilities = [
		AbilityFactory.create_damage_ability("Slash", 15, Ability.TargetType.ENEMY, "A strong sword slash"),
		AbilityFactory.create_damage_ability("Heavy Strike", 25, Ability.TargetType.ENEMY, "A powerful but slower attack"),
		AbilityFactory.create_skip_turn_ability("Defend", "Prepare to block incoming attacks")
	]
	all_combatants.append(warrior)
	
	# Wizard
	var wizard: Combatant = Combatant.new()
	wizard.name = "Wizard"
	wizard.max_hp = 70
	wizard.current_hp = 70
	wizard.speed = 10
	wizard.is_player = true

	var explosion_damage = AbilityFactory.create_damage_ability(
    "Explosion", 
    15, 
    Ability.TargetType.ENEMY, 
    "An explosion of fire",
    "{target} is engulfed in a fiery explosion for {power} damage!")

	# Now create a status effect that applies this damage when it expires
	var fire_trap = AbilityFactory.create_status_effect_with_expiry(
		"Fire Trap",
		3,  # Duration of 3 turns
		Ability.TargetType.ENEMY,
		"Target is surrounded by magical fire that will explode after 3 turns",
		StatusEffect.TriggerType.TURN_END,  # Trigger at end of turn
		AbilityFactory.create_dot_ability("Burning", 5, 1, Ability.TargetType.ENEMY, "Burns for 5 damage"),  # Applied each turn
		explosion_damage,  # Applied when effect expires
		StatusEffect.StackingBehavior.REPLACE,  # Replace if already applied
		"{user} surrounds {target} with a ring of fire that will explode in {duration} turns!"
	)

	# Add this ability to the Wizard
	wizard.abilities.append(fire_trap)

	wizard.abilities = [
		AbilityFactory.create_damage_ability("Fireball", 20, Ability.TargetType.ENEMY, "A ball of fire"),
		AbilityFactory.create_dot_ability("Poison", 8, 3, Ability.TargetType.ENEMY, "Poisons enemy for 3 turns"),
		AbilityFactory.create_skip_turn_ability("Meditate", "Prepare for your next spell")
	]
	all_combatants.append(wizard)
	
	# Cleric
	var cleric: Combatant = Combatant.new()
	cleric.name = "Cleric"
	cleric.max_hp = 85
	cleric.current_hp = 85
	cleric.speed = 7
	cleric.is_player = true
	cleric.abilities = [
		AbilityFactory.create_damage_ability("Smite", 12, Ability.TargetType.ENEMY, "A holy attack"),
		AbilityFactory.create_healing_ability("Heal", 20, Ability.TargetType.FRIENDLY, "Heals an ally"),
		AbilityFactory.create_hot_ability("Regeneration", 5, 3, Ability.TargetType.FRIENDLY, "Healing over time")
	]
	all_combatants.append(cleric)
	
	# Rogue
	var rogue: Combatant = Combatant.new()
	rogue.name = "Rogue"
	rogue.max_hp = 75
	rogue.current_hp = 75
	rogue.speed = 12
	rogue.is_player = true
	rogue.abilities = [
		AbilityFactory.create_damage_ability("Backstab", 18, Ability.TargetType.ENEMY, "A surprise attack from behind"),
		AbilityFactory.create_dot_ability("Bleed", 6, 4, Ability.TargetType.ENEMY, "Causes bleeding for 4 turns"),
		AbilityFactory.create_skip_turn_ability("Hide", "Hide in the shadows")
	]
	all_combatants.append(rogue)
	
	# Ranger
	var ranger: Combatant = Combatant.new()
	ranger.name = "Ranger"
	ranger.max_hp = 80
	ranger.current_hp = 80
	ranger.speed = 11
	ranger.is_player = true
	ranger.abilities = [
		AbilityFactory.create_damage_ability("Precise Shot", 16, Ability.TargetType.ENEMY, "A precisely aimed arrow"),
		AbilityFactory.create_damage_ability("Quick Shot", 10, Ability.TargetType.ENEMY, "A rapid arrow shot"),
		AbilityFactory.create_skip_turn_ability("Aim", "Carefully aim your next shot")
	]
	all_combatants.append(ranger)
	
	# ENEMY OPTIONS
	
	# Goblin
	var goblin: Combatant = Combatant.new()
	goblin.name = "Goblin"
	goblin.max_hp = 50
	goblin.current_hp = 50
	goblin.speed = 9
	goblin.is_player = false
	goblin.abilities = [
		AbilityFactory.create_damage_ability("Stab", 8, Ability.TargetType.ENEMY, "A quick stab with a dagger"),
		AbilityFactory.create_skip_turn_ability("Retreat", "Temporary retreat to safety")
	]
	all_combatants.append(goblin)
	
	# Orc
	var orc: Combatant = Combatant.new()
	orc.name = "Orc"
	orc.max_hp = 90
	orc.current_hp = 90
	orc.speed = 6
	orc.is_player = false
	orc.abilities = [
		AbilityFactory.create_damage_ability("Axe Swing", 15, Ability.TargetType.ENEMY, "A powerful axe swing"),
		AbilityFactory.create_damage_ability("Battle Cry", 5, Ability.TargetType.ENEMY, "A terrifying shout")
	]
	all_combatants.append(orc)
	
	# Wolf
	var wolf: Combatant = Combatant.new()
	wolf.name = "Wolf"
	wolf.max_hp = 60
	wolf.current_hp = 60
	wolf.speed = 13
	wolf.is_player = false
	wolf.abilities = [
		AbilityFactory.create_damage_ability("Bite", 12, Ability.TargetType.ENEMY, "A vicious bite"),
		AbilityFactory.create_dot_ability("Maul", 4, 3, Ability.TargetType.ENEMY, "Causes bleeding for 3 turns")
	]
	all_combatants.append(wolf)
	
	# Skeleton
	var skeleton: Combatant = Combatant.new()
	skeleton.name = "Skeleton"
	skeleton.max_hp = 70
	skeleton.current_hp = 70
	skeleton.speed = 7
	skeleton.is_player = false
	skeleton.abilities = [
		AbilityFactory.create_damage_ability("Bone Strike", 10, Ability.TargetType.ENEMY, "A strike with a bone club"),
		AbilityFactory.create_damage_ability("Bone Throw", 8, Ability.TargetType.ENEMY, "Throws a bone")
	]
	all_combatants.append(skeleton)
	
	# Dark Mage
	var dark_mage: Combatant = Combatant.new()
	dark_mage.name = "Dark Mage"
	dark_mage.max_hp = 65
	dark_mage.current_hp = 65
	dark_mage.speed = 8
	dark_mage.is_player = false
	dark_mage.abilities = [
		AbilityFactory.create_damage_ability("Shadow Bolt", 14, Ability.TargetType.ENEMY, "A bolt of dark energy"),
		AbilityFactory.create_dot_ability("Curse", 6, 3, Ability.TargetType.ENEMY, "A curse that deals damage over time")
	]
	all_combatants.append(dark_mage)
	
	# Giant Spider
	var spider: Combatant = Combatant.new()
	spider.name = "Giant Spider"
	spider.max_hp = 75
	spider.current_hp = 75
	spider.speed = 10
	spider.is_player = false
	spider.abilities = [
		AbilityFactory.create_damage_ability("Bite", 10, Ability.TargetType.ENEMY, "A venomous bite"),
		AbilityFactory.create_dot_ability("Web", 5, 4, Ability.TargetType.ENEMY, "Ensnares target in sticky web")
	]
	all_combatants.append(spider)
	
	# Troll
	var troll: Combatant = Combatant.new()
	troll.name = "Troll"
	troll.max_hp = 120
	troll.current_hp = 120
	troll.speed = 5
	troll.is_player = false
	troll.abilities = [
		AbilityFactory.create_damage_ability("Club Smash", 20, Ability.TargetType.ENEMY, "A devastating club strike"),
		AbilityFactory.create_healing_ability("Regenerate", 10, Ability.TargetType.SELF, "Regenerates some health")
	]
	all_combatants.append(troll)
	
	# Dragon
	var dragon: Combatant = Combatant.new()
	dragon.name = "Dragon"
	dragon.max_hp = 150
	dragon.current_hp = 150
	dragon.speed = 7
	dragon.is_player = false
	dragon.abilities = [
		AbilityFactory.create_damage_ability("Fire Breath", 25, Ability.TargetType.ENEMY, "A blast of fire"),
		AbilityFactory.create_damage_ability("Tail Swipe", 15, Ability.TargetType.ENEMY, "A powerful tail swipe"),
		AbilityFactory.create_dot_ability("Inferno", 10, 3, Ability.TargetType.ENEMY, "Sets target on fire")
	]
	all_combatants.append(dragon)

func get_all_combatants() -> Array[Combatant]:
	# We need to do a proper deep copy of combatants
	var combatants_copy: Array[Combatant] = []
	
	for combatant in all_combatants:
		var new_combatant: Combatant = Combatant.new()
		new_combatant.name = combatant.name
		new_combatant.max_hp = combatant.max_hp
		new_combatant.current_hp = combatant.current_hp
		new_combatant.speed = combatant.speed
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