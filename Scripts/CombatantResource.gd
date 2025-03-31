# CombatantResource.gd with damage resistances
class_name CombatantResource
extends Resource

# Basic combatant identification
@export var name: String = ""
@export var display_name: String = ""
@export var is_player: bool = true
@export var icon: Texture2D  # Optional icon for UI display

# Core stats
@export_group("Base Stats")
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var physical_attack: int = 10
@export var magic_attack: int = 10
@export var physical_defense: int = 10
@export var magic_defense: int = 10
@export var speed: int = 10

# Damage resistances 
@export_group("Resistances and Weaknesses")
# Values < 1.0 are resistances (0.5 = 50% less damage)
# Values > 1.0 are weaknesses (1.5 = 50% more damage)
# Value of 0 means immune
@export var damage_resistances: Dictionary = {
    # Example: "fire": 0.5, # Resistant to fire
    # Example: "ice": 1.5,  # Weak to ice
    # Example: "poison": 0, # Immune to poison
}

# Abilities
@export_group("Abilities")
@export var abilities: Array[Resource] = []  # Can contain AbilityResource instances

# Creates a Combatant instance from this resource
func create_combatant_instance() -> Combatant:
    var combatant : Combatant = Combatant.new()
    
    # Set basic properties
    combatant.name = name
    combatant.display_name = display_name if not display_name.is_empty() else name
    combatant.is_player = is_player
    
    # Set stats
    combatant.max_hp = max_hp
    combatant.current_hp = max_hp
    combatant.max_mp = max_mp
    combatant.current_mp = max_mp
    combatant.physical_attack = physical_attack
    combatant.magic_attack = magic_attack
    combatant.physical_defense = physical_defense
    combatant.magic_defense = magic_defense
    combatant.speed = speed
    
    # Set damage resistances
    combatant.damage_resistances = damage_resistances.duplicate()
    
    # Process abilities
    combatant.abilities = []
    for ability_resource in abilities:
        if ability_resource is AbilityResource:
            var ability = ability_resource.create_ability_instance()
            if ability:
                combatant.abilities.append(ability)
    
    # Store reference to this resource
    combatant.source_resource = self
    
    return combatant