# StatusIcon.gd
extends Panel

var effect_name: String
var duration: int
var description: String

@onready var icon_label = $IconLabel
@onready var duration_label = $DurationLabel

func setup(effect: StatusEffect) -> void:
	effect_name = effect.display_name
	duration = effect.duration
	description = effect.description
	
	# Set a simple text representation (could be replaced with proper icons)
	icon_label.text = effect_name.substr(0, 1)  # First letter as a placeholder
	
	# Show duration if applicable
	if duration > 0:
		duration_label.text = str(duration)
	else:
		duration_label.visible = false
	
	# Set tooltip
	tooltip_text = effect_name + "\n" + description
	
	# You could set a custom color based on effect type here
