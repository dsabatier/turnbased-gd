# CombatantResource.gd with damage resistances
class_name CombatantResource
extends Resource

# Basic combatant identification
@export var id : String = ""
@export var display_name: String = ""
@export var icon: Texture2D

# Core stats
@export_group("Base Stats")
@export var base_hp: int = 100
@export var base_mp: int = 50
@export var physical_attack: int = 10
@export var magic_attack: int = 10
@export var physical_defense: int = 10
@export var magic_defense: int = 10
@export var speed: int = 10

# Damage resistances 
@export_group("Resistances and Weaknesses")

@export var damage_resistances: Array[DamageTypeResource]

@export_group("Abilities")
@export var abilities: Array[AbilityResource] = []  # Can contain AbilityResource instances
