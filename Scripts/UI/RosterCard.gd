# RosterCard.gd
extends Button

# References to UI elements
@onready var name_label = $VBoxContainer/NameLabel
@onready var portrait = $VBoxContainer/Portrait
@onready var stats_label = $VBoxContainer/StatsLabel

# Stored combatant resource
var combatant_resource: CombatantResource

func initialize(resource: CombatantResource) -> void:
	combatant_resource = resource
	
	# Set basic info
	name_label.text = resource.display_name
	
	# Set portrait if available
	if resource.icon:
		portrait.texture = resource.icon
	
	# Set stats summary
	stats_label.text = "HP: " + str(resource.base_hp) + " | MP: " + str(resource.base_mp)
	
	# Set tooltip with more detailed stats
	tooltip_text = _create_tooltip(resource)

func _create_tooltip(resource: CombatantResource) -> String:
	var tooltip = resource.display_name + "\n"
	tooltip += "HP: " + str(resource.base_hp) + "\n"
	tooltip += "MP: " + str(resource.base_mp) + "\n"
	tooltip += "Physical Attack: " + str(resource.physical_attack) + "\n"
	tooltip += "Magic Attack: " + str(resource.magic_attack) + "\n"
	tooltip += "Physical Defense: " + str(resource.physical_defense) + "\n"
	tooltip += "Magic Defense: " + str(resource.magic_defense) + "\n"
	tooltip += "Speed: " + str(resource.speed) + "\n"
	
	# Add abilities if any
	if resource.abilities.size() > 0:
		tooltip += "\nAbilities:\n"
		for ability in resource.abilities:
			tooltip += "- " + ability.display_name + "\n"
	
	return tooltip
