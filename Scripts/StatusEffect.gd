# StatusEffect.gd
class_name StatusEffect
extends Resource

signal effect_expired(effect)

enum TriggerType {
	TURN_START,
	TURN_END,
	ON_DAMAGE_TAKEN,
	ON_HEALING_RECEIVED
}

@export var name: String
@export var description: String
@export var duration: int # Number of turns this effect lasts
@export var trigger_type: TriggerType
@export var ability: Ability # The ability to apply when triggered
var source_combatant: Combatant # Who applied this status effect

var remaining_turns: int
var target_combatant: Combatant # Who the effect is applied to

func _init():
	remaining_turns = duration

# Update the apply method in StatusEffect.gd to use display_name
func apply(target: Combatant, source: Combatant):
	target_combatant = target
	source_combatant = source
	remaining_turns = duration
	
	# Register this effect with the target
	target.add_status_effect(self)
	
	# Get display name with proper fallbacks
	var target_name = target.display_name
	
	return "%s was affected by %s for %d turns!" % [target_name, name, duration]

# Update the trigger method in StatusEffect.gd to use display_name
func trigger():
	if remaining_turns <= 0:
		return ""
	
	var result = ability.execute(source_combatant, target_combatant)
	
	# Decrement remaining duration
	remaining_turns -= 1
	
	# Check if effect has expired
	if remaining_turns <= 0:
		# Get display name with proper fallbacks
		var target_name = target_combatant.display_name
		var expiry_message = "%s has worn off from %s!" % [name, target_name]
		emit_signal("effect_expired", self)
		return result + "\n" + expiry_message
	
	return result
