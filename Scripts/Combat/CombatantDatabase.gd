# CombatantDatabase.gd
extends Node

# Cache of all loaded combatants
var _combatants: Dictionary = {}

func _ready() -> void:
	# Load all combatant resources when the game starts
	_load_all_combatants()
	
	# If no combatants were loaded, create demo combatants
	if _combatants.size() == 0:
		_create_demo_combatants()

func _load_all_combatants() -> void:
	# Get all .tres files in the Resources/Combatants directory
	var dir = DirAccess.open("res://Resources/Combatants/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var resource_path = "res://Resources/Combatants/" + file_name
				var resource = load(resource_path)
				
				if resource is CombatantResource:
					_combatants[resource.id] = resource
			
			file_name = dir.get_next()

# Get a specific combatant by ID
func get_combatant(id: String) -> CombatantResource:
	if _combatants.has(id):
		return _combatants[id]
	
	return null

# Get all combatants
func get_all_combatants() -> Array:
	return _combatants.values()

# Get all player-usable combatants
func get_playable_combatants() -> Array[CombatantResource]:
	var result: Array[CombatantResource] = []
	
	for combatant in _combatants.values():
		if combatant is CombatantResource:
			if combatant.is_playable:
				result.append(combatant)
	
	return result

# Get all enemy combatants
func get_enemy_combatants() -> Array[CombatantResource]:
	var result: Array[CombatantResource] = []
	
	for combatant in _combatants.values():
		if combatant is CombatantResource:
			if not combatant.is_playable:
				result.append(combatant)
	
	return result

# For the purpose of this demonstration, if no combatants are loaded, provide some examples
func _ensure_demo_combatants() -> void:
	if _combatants.size() == 0:
		# Create some example combatants
		_create_demo_combatants()

func _create_demo_combatants() -> void:
	# Create abilities
	var abilities = AbilityCreator.create_basic_abilities()
	
	# Create a warrior combatant
	var warrior = CombatantResource.new()
	warrior.id = "warrior"
	warrior.display_name = "Warrior"
	warrior.base_hp = 120
	warrior.base_mp = 30
	warrior.physical_attack = 15
	warrior.magic_attack = 5
	warrior.physical_defense = 12
	warrior.magic_defense = 8
	warrior.speed = 7
	warrior.is_playable = true
	warrior.abilities = [abilities["power_strike"], abilities["shield"]] as Array[AbilityResource]
	
	# Create a mage combatant
	var mage = CombatantResource.new()
	mage.id = "mage"
	mage.display_name = "Mage"
	mage.base_hp = 70
	mage.base_mp = 100
	mage.physical_attack = 4
	mage.magic_attack = 18
	mage.physical_defense = 5
	mage.magic_defense = 15
	mage.speed = 9
	mage.is_playable = true
	mage.abilities = [abilities["fireball"], abilities["lightning_bolt"], abilities["ice_spike"]] as Array[AbilityResource]
	
	# Create a thief combatant
	var thief = CombatantResource.new()
	thief.id = "thief"
	thief.display_name = "Thief"
	thief.base_hp = 90
	thief.base_mp = 45
	thief.physical_attack = 12
	thief.magic_attack = 8
	thief.physical_defense = 8
	thief.magic_defense = 10
	thief.speed = 15
	thief.is_playable = true
	thief.abilities = [abilities["backstab"]] as Array[AbilityResource]
	
	# Create a healer combatant
	var healer = CombatantResource.new()
	healer.id = "healer"
	healer.display_name = "Healer"
	healer.base_hp = 85
	healer.base_mp = 120
	healer.physical_attack = 5
	healer.magic_attack = 14
	healer.physical_defense = 6
	healer.magic_defense = 12
	healer.speed = 8
	healer.is_playable = true
	healer.abilities = [abilities["heal"], abilities["cure"]] as Array[AbilityResource]
	
	# Create a goblin enemy
	var goblin = CombatantResource.new()
	goblin.id = "goblin"
	goblin.display_name = "Goblin"
	goblin.base_hp = 50
	goblin.base_mp = 20
	goblin.physical_attack = 10
	goblin.magic_attack = 3
	goblin.physical_defense = 7
	goblin.magic_defense = 5
	goblin.speed = 12
	goblin.is_playable = false
	goblin.abilities = [abilities["poison_bite"]] as Array[AbilityResource]
	
	# Create a skeleton enemy
	var skeleton = CombatantResource.new()
	skeleton.id = "skeleton"
	skeleton.display_name = "Skeleton"
	skeleton.base_hp = 70
	skeleton.base_mp = 10
	skeleton.physical_attack = 12
	skeleton.magic_attack = 2
	skeleton.physical_defense = 10
	skeleton.magic_defense = 3
	skeleton.speed = 8
	skeleton.is_playable = false
	
	# Create a troll enemy
	var troll = CombatantResource.new()
	troll.id = "troll"
	troll.display_name = "Troll"
	troll.base_hp = 150
	troll.base_mp = 15
	troll.physical_attack = 18
	troll.magic_attack = 5
	troll.physical_defense = 15
	troll.magic_defense = 8
	troll.speed = 5
	troll.is_playable = false
	troll.abilities = [abilities["crush"]] as Array[AbilityResource]
	
	# Create a dark mage enemy
	var dark_mage = CombatantResource.new()
	dark_mage.id = "dark_mage"
	dark_mage.display_name = "Dark Mage"
	dark_mage.base_hp = 65
	dark_mage.base_mp = 90
	dark_mage.physical_attack = 5
	dark_mage.magic_attack = 16
	dark_mage.physical_defense = 4
	dark_mage.magic_defense = 12
	dark_mage.speed = 10
	dark_mage.is_playable = false
	dark_mage.abilities = [abilities["shadow_blast"]] as Array[AbilityResource]
	
	# Add to dictionary
	_combatants[warrior.id] = warrior
	_combatants[mage.id] = mage
	_combatants[thief.id] = thief
	_combatants[healer.id] = healer
	_combatants[goblin.id] = goblin
	_combatants[skeleton.id] = skeleton
	_combatants[troll.id] = troll
	_combatants[dark_mage.id] = dark_mage
