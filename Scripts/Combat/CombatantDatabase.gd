# CombatantDatabase.gd
extends Node

# Cache of all loaded combatants
var _combatants: Dictionary = {}

func _ready() -> void:
	# Load all combatant resources when the game starts
	_load_all_combatants()

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
func get_playable_combatants() -> Array:
	var result = []
	
	for combatant in _combatants.values():
		if combatant.is_playable:  # You would need to add this flag to your CombatantResource
			result.append(combatant)
	
	return result

# Get all enemy combatants
func get_enemy_combatants() -> Array:
	var result = []
	
	for combatant in _combatants.values():
		if not combatant.is_playable:  # Using the inverse of the playable flag
			result.append(combatant)
	
	return result

# For the purpose of this demonstration, if no combatants are loaded, provide some examples
func _ensure_demo_combatants() -> void:
	if _combatants.size() == 0:
		# Create some example combatants
		_create_demo_combatants()

func _create_demo_combatants() -> void:
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
	
	# Add to dictionary
	_combatants[warrior.id] = warrior
	_combatants[mage.id] = mage
	_combatants[goblin.id] = goblin
