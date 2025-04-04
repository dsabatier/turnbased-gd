# StatusIcon.gd
extends Panel

var effect_name: String
var duration: int
var description: String

# Use @onready to ensure these are properly initialized after the scene is loaded
@onready var icon_label = $IconLabel
@onready var duration_label = $DurationLabel

func _ready():
	# Ensure all child nodes are properly loaded
	if !icon_label or !duration_label:
		push_error("StatusIcon: Required child nodes not found")
		return

func setup(effect: StatusEffect) -> void:
	# Wait for nodes to be ready if needed
	if !is_inside_tree():
		await ready
	
	if !icon_label or !duration_label:
		push_error("StatusIcon: Required child nodes not found")
		return
	
	effect_name = effect.display_name
	duration = effect.duration
	description = effect.description
	
	# Set a simple text representation (could be replaced with proper icons)
	if effect_name and effect_name.length() > 0:
		icon_label.text = effect_name.substr(0, 1)  # First letter as a placeholder
	else:
		icon_label.text = "?"
	
	# Show duration if applicable
	if duration > 0:
		duration_label.text = str(duration)
		duration_label.visible = true
	else:
		duration_label.visible = false
	
	# Set tooltip
	tooltip_text = effect_name + "\n" + description