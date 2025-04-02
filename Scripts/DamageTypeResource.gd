# DamageTypeResource.gd
class_name DamageTypeResource
extends Resource

# Basic properties
@export var id: String = "physical"
@export var name: String = "Physical"
@export_multiline var description: String = "Raw physical damage from weapons and brute force"
@export_color var color: Color = Color(1.0, 0.47, 0.47)  # #FF7777

# Combat related properties
@export_enum("physical_defense", "magic_defense", "none") var defense_stat: String = "physical_defense"

# Optional icon for UI
@export var icon: Texture2D