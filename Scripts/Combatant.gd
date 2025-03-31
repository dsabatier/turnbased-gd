# Combatant.gd updated with damage resistances
class_name Combatant
extends Node

signal defeated
signal hp_changed(current_hp, max_hp)
signal mp_changed(current_mp, max_mp)
signal status_effect_added(effect)
signal status_effect_removed(effect)
signal status_effect_triggered(effect, result)
signal damage_taken(amount, damage_type_id, flags)

# Basic combatant identification
@export var display_name: String
@export var is_player: bool

# Core stats
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var physical_attack: int = 10
@export var magic_attack: int = 10
@export var physical_defense: int = 10
@export var magic_defense: int = 10
@export var speed: int = 10

# Damage resistances and weaknesses
# Values < 1.0 are resistances (0.5 = 50% less damage)
# Values > 1.0 are weaknesses (1.5 = 50% more damage)
# Value of 0 means immune
@export var damage_resistances: Dictionary = {
    # Example: "fire": 0.5, # Resistant to fire
    # Example: "ice": 1.5,  # Weak to ice
    # Example: "poison": 0, # Immune to poison
}

# Current values
var current_hp: int
var current_mp: int
var abilities: Array[Ability] = []
var is_defeated: bool = false
var status_effects: Array[StatusEffect] = []

var source_resource: Resource = null

func _ready():
    current_hp = max_hp
    current_mp = max_mp
    
    # Initialize display_name if not set
    if display_name == null or display_name.is_empty():
        display_name = name

# Get a combatant's resistance to a specific damage type
func get_damage_resistance(damage_type_id: String) -> float:
    if damage_resistances.has(damage_type_id):
        return damage_resistances[damage_type_id]
    # Default is 1.0 (normal damage)
    return 1.0

# Take damage with an optional damage type
func take_damage(amount: int, damage_type_id: String = "physical") -> int:
    # Apply damage
    current_hp = max(0, current_hp - amount)
    emit_signal("hp_changed", current_hp, max_hp)
    emit_signal("damage_taken", amount, damage_type_id, {})
    
    if current_hp == 0 and not is_defeated:
        is_defeated = true
        emit_signal("defeated")
    
    # Trigger ON_DAMAGE_TAKEN effects 
    var effect_results = trigger_status_effects(StatusEffect.TriggerType.ON_DAMAGE_TAKEN)
    
    # Return the actual damage dealt
    return amount

func heal(amount: int, source = null) -> void:
    var old_hp = current_hp
    current_hp = min(max_hp, current_hp + amount)
    emit_signal("hp_changed", current_hp, max_hp)
    
    # Trigger ON_HEALING_RECEIVED effects
    trigger_status_effects(StatusEffect.TriggerType.ON_HEALING_RECEIVED)

func use_mp(amount: int) -> bool:
    if current_mp >= amount:
        current_mp -= amount
        emit_signal("mp_changed", current_mp, max_mp)
        return true
    return false
    
func restore_mp(amount: int) -> void:
    current_mp = min(max_mp, current_mp + amount)
    emit_signal("mp_changed", current_mp, max_mp)

# Use an ability
func use_ability(ability_index: int, target = null) -> String:
    if is_defeated:
        return "%s is defeated and cannot act!" % display_name
        
    # Validate ability index
    if ability_index < 0 or ability_index >= abilities.size():
        return "%s tried to use an invalid ability!" % display_name
    
    var ability = abilities[ability_index]
    
    # Check for null ability
    if ability == null:
        return "%s tried to use a null ability!" % display_name
    
    # Check if we have enough MP to use this ability
    var mp_cost = 0
    if ability.has_method("get") and ability.get("mp_cost") != null:
        mp_cost = ability.mp_cost
        
    if mp_cost > 0 and current_mp < mp_cost:
        return "%s doesn't have enough MP to use %s!" % [display_name, ability.name]
    
    # Handle SELF target type automatically
    if ability.target_type == Ability.TargetType.SELF:
        # Consume MP if needed
        if mp_cost > 0:
            use_mp(mp_cost)
            
        # Try to get the damage manager from the scene
        var damage_manager = null
        if Engine.has_singleton("DamageTypeManager"):
            damage_manager = Engine.get_singleton("DamageTypeManager")
            
        return ability.execute(self, self, damage_manager)
    
    # Ensure target is provided for non-SELF abilities
    if target == null:
        return "No target selected for %s!" % ability.name
    
    # Check if the ability can target the selected target
    if (ability.target_type == Ability.TargetType.ENEMY and target.is_player == is_player) or \
       (ability.target_type == Ability.TargetType.FRIENDLY and target.is_player != is_player) or \
       (ability.target_type == Ability.TargetType.OTHER_FRIENDLY and (target.is_player != is_player or target == self)):
        return "Invalid target for %s!" % ability.name
    
    # Consume MP if needed
    if mp_cost > 0:
        use_mp(mp_cost)
    
    # Try to get the damage manager from the scene
    var damage_manager = null
    if Engine.has_singleton("DamageTypeManager"):
        damage_manager = Engine.get_singleton("DamageTypeManager")
        
    return ability.execute(self, target, damage_manager)

# AI logic for CPU-controlled combatants
func choose_action(friendlies: Array, enemies: Array):
    if is_defeated:
        return null
    
    # Simple AI that randomly chooses an ability and a valid target
    var valid_abilities = []
    for i in range(abilities.size()):
        var ability = abilities[i]
        
        # Skip null abilities
        if ability == null:
            continue
            
        # Check MP cost safely
        var mp_cost = 0
        if ability.has_method("get") and ability.get("mp_cost") != null:
            mp_cost = ability.mp_cost
            
        if mp_cost <= current_mp:
            valid_abilities.append(i)
    
    if valid_abilities.size() == 0:
        print("No valid abilities found for " + name)
        return null
        
    var ability_index = valid_abilities[randi() % valid_abilities.size()]
    
    # Double-check that the ability exists (belt and suspenders approach)
    if ability_index >= abilities.size():
        print("Invalid ability index: " + str(ability_index))
        return null
        
    var ability = abilities[ability_index]
    
    # Another null check for safety
    if ability == null:
        print("Null ability at index: " + str(ability_index))
        return null
    
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
        print("No valid targets found for ability: " + ability.name)
        return null
    
    var target_index = randi() % possible_targets.size()
    var target = possible_targets[target_index]
    
    return {
        "ability": ability_index,
        "target": target
    }

# Status effect management
func add_status_effect(effect: StatusEffect) -> void:
    # The effect's apply method now handles stacking behavior
    status_effects.append(effect)
    effect.effect_expired.connect(_on_status_effect_expired)
    emit_signal("status_effect_added", effect)

func remove_status_effect(effect: StatusEffect) -> void:
    if effect in status_effects:
        # Make sure to remove stat modifiers before removing the effect
        effect.remove_stat_modifiers()
        
        status_effects.erase(effect)
        if effect.is_connected("effect_expired", _on_status_effect_expired):
            effect.disconnect("effect_expired", _on_status_effect_expired)
        emit_signal("status_effect_removed", effect)

# Handle status effect expiration with possible additional effects
func _on_status_effect_expired(effect: StatusEffect) -> void:
    remove_status_effect(effect)

func trigger_status_effects(trigger: int) -> Array[String]:
    var results : Array[String] = []
    
    # Create a copy of the array since effects might be removed during iteration
    var effects_to_trigger = status_effects.duplicate()
    
    for effect in effects_to_trigger:
        if effect.trigger_type == trigger:
            var result = effect.trigger()
            if result != "":
                results.append(result)
                emit_signal("status_effect_triggered", effect, result)
    
    return results
	