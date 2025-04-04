# RosterCard.gd
extends Button

# References to UI elements
var name_label: Label
var portrait: TextureRect
var stats_label: Label

func _ready() -> void:
	# Get node references
	name_label = get_node_or_null("VBoxContainer/NameLabel")
	portrait = get_node_or_null("VBoxContainer/Portrait")
	stats_label = get_node_or_null("VBoxContainer/StatsLabel")

# Stored combatant resource
var combatant_resource: CombatantResource

func initialize(resource: CombatantResource) -> void:
	# Wait until ready if needed
	if not is_inside_tree():
		await ready
	
	# Ensure we have valid node references
	if name_label == null:
		name_label = get_node_or_null("VBoxContainer/NameLabel")
	if portrait == null:
		portrait = get_node_or_null("VBoxContainer/Portrait")
	if stats_label == null:
		stats_label = get_node_or_null("VBoxContainer/StatsLabel")
	
	combatant_resource = resource
	
	# Set basic info
	if name_label:
		name_label.text = resource.display_name
	
	# Set portrait if available
	if portrait:
		if resource.icon:
			portrait.texture = resource.icon
		else:
			# Set a default texture or placeholder
			portrait.modulate = Color(0.9, 0.9, 0.9) # Light gray for placeholder
	
	# Set stats summary
	if stats_label:
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
	if resource.abilities and resource.abilities.size() > 0:
		tooltip += "\nAbilities:\n"
		for ability in resource.abilities:
			if ability:
				tooltip += "- " + ability.display_name + "\n"
	
	return tooltip
