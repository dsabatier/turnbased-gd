# Combatant.gd
class_name Combatant
extends Node

signal defeated
signal hp_changed(current_hp, max_hp)
signal status_effect_added(effect)
signal status_effect_removed(effect)
signal status_effect_triggered(effect, result)

@export var display_name: String
@export var max_hp: int
@export var speed: int
@export var is_player: bool

var current_hp: int
var abilities: Array[Ability] = []
var is_defeated: bool = false
var status_effects: Array[StatusEffect] = []

func _ready():
	current_hp = max_hp

func take_damage(amount: int) -> void:
	current_hp = max(0, current_hp - amount)
	emit_signal("hp_changed", current_hp, max_hp)
	
	if current_hp == 0 and not is_defeated:
		is_defeated = true
		emit_signal("defeated")
	
	# Trigger ON_DAMAGE_TAKEN effects
	trigger_status_effects(StatusEffect.TriggerType.ON_DAMAGE_TAKEN)

func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp, max_hp)
	
	# Trigger ON_HEALING_RECEIVED effects
	trigger_status_effects(StatusEffect.TriggerType.ON_HEALING_RECEIVED)

func use_ability(ability_index: int, target = null) -> String:
	if is_defeated:
		return "%s is defeated and cannot act!" % display_name
	
	var ability = abilities[ability_index]
	
	# Handle SELF target type automatically
	if ability.target_type == Ability.TargetType.SELF:
		return ability.execute(self, self)
	
	# Ensure target is provided for non-SELF abilities
	if target == null:
		return "No target selected for %s!" % ability.name
	
	# Check if the ability can target the selected target
	if (ability.target_type == Ability.TargetType.ENEMY and target.is_player == is_player) or \
	   (ability.target_type == Ability.TargetType.FRIENDLY and target.is_player != is_player) or \
	   (ability.target_type == Ability.TargetType.OTHER_FRIENDLY and (target.is_player != is_player or target == self)):
		return "Invalid target for %s!" % ability.name
	
	return ability.execute(self, target)

# AI logic for CPU-controlled combatants
func choose_action(friendlies: Array, enemies: Array):
	if is_defeated:
		return null
	
	# Simple AI that randomly chooses an ability and a valid target
	var ability_index = randi() % abilities.size()
	var ability = abilities[ability_index]
	
	# Handle SELF target type immediately
	if ability.target_type == Ability.TargetType.SELF:
		return {
			"ability": ability_index,
			"target": self
		}
	
	var possible_targets = []
	if ability.target_type == Ability.TargetType.ENEMY:
		possible_targets = enemies.filter(func(enemy): return not enemy.is_defeated)
	elif ability.target_type == Ability.TargetType.FRIENDLY:
		possible_targets = friendlies.filter(func(friendly): return not friendly.is_defeated)
	elif ability.target_type == Ability.TargetType.OTHER_FRIENDLY:
		possible_targets = friendlies.filter(func(friendly): return not friendly.is_defeated and friendly != self)
	else:
		# For "any" target type
		possible_targets = friendlies + enemies
		possible_targets = possible_targets.filter(func(combatant): return not combatant.is_defeated)
	
	if possible_targets.size() == 0:
		return null
	
	var target_index = randi() % possible_targets.size()
	var target = possible_targets[target_index]
	
	return {
		"ability": ability_index,
		"target": target
	}

# Status effect management
func add_status_effect(effect: StatusEffect) -> void:
	status_effects.append(effect)
	effect.effect_expired.connect(_on_status_effect_expired)
	emit_signal("status_effect_added", effect)

func remove_status_effect(effect: StatusEffect) -> void:
	if effect in status_effects:
		status_effects.erase(effect)
		if effect.is_connected("effect_expired", _on_status_effect_expired):
			effect.disconnect("effect_expired", _on_status_effect_expired)
		emit_signal("status_effect_removed", effect)

func _on_status_effect_expired(effect: StatusEffect) -> void:
	remove_status_effect(effect)

func trigger_status_effects(trigger: int) -> Array[String]:
	var results: Array[String] = []
	
	# Create a copy of the array since effects might be removed during iteration
	var effects_to_trigger = status_effects.duplicate()
	
	for effect in effects_to_trigger:
		if effect.trigger_type == trigger:
			var result = effect.trigger()
			if result != "":
				results.append(result)
				emit_signal("status_effect_triggered", effect, result)
	
	return results