# AbilityFactory.gd
class_name AbilityFactory
extends Node

# Create a basic damage ability
static func create_damage_ability(
    name: String, 
    power: int, 
    target_type: int, 
    description: String, 
    custom_message: String = "",
    mp_cost: int = 0,
    damage_type: int = Ability.DamageType.PHYSICAL
) -> Ability:
    var ability = Ability.new()
    ability.name = name
    ability.power = power
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.DAMAGE
    ability.mp_cost = mp_cost
    ability.damage_type = damage_type
    
    if custom_message != "":
        ability.custom_message = custom_message
        
    return ability

# Create a basic healing ability
static func create_healing_ability(
    name: String, 
    power: int, 
    target_type: int, 
    description: String, 
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    var ability = Ability.new()
    ability.name = name
    ability.power = power
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.HEALING
    ability.mp_cost = mp_cost
    
    if custom_message != "":
        ability.custom_message = custom_message
        
    return ability

# Create a skip turn ability
static func create_skip_turn_ability(
    name: String, 
    description: String, 
    custom_message: String = ""
) -> Ability:
    var ability = Ability.new()
    ability.name = name
    ability.power = 0  # No direct effect on HP
    ability.target_type = Ability.TargetType.SELF  # Only affects the caster
    ability.description = description
    ability.effect_type = Ability.EffectType.UTILITY
    ability.mp_cost = 0  # No MP cost for skipping
    
    if custom_message != "":
        ability.custom_message = custom_message
        
    return ability

# Create a damage over time ability
static func create_dot_ability(
    name: String, 
    damage_per_tick: int, 
    duration: int, 
    target_type: int, 
    description: String, 
    custom_message: String = "",
    mp_cost: int = 0,
    damage_type: int = Ability.DamageType.PHYSICAL
) -> Ability:
    # First create the damage ability that will be applied on each tick
    var damage_ability = Ability.new()
    damage_ability.name = name + " (DoT)"
    damage_ability.power = damage_per_tick
    damage_ability.target_type = target_type
    damage_ability.effect_type = Ability.EffectType.DAMAGE
    damage_ability.damage_type = damage_type
    damage_ability.custom_message = "{target} takes {power} damage from {effect}"
    
    # Create the status effect
    var status = StatusEffect.new()
    status.name = name + " Effect"
    status.description = "Taking %d damage at the end of each turn for %d turns" % [damage_per_tick, duration]
    status.duration = duration
    status.trigger_type = StatusEffect.TriggerType.TURN_END
    status.ability = damage_ability
    
    # Create the ability that applies the status effect
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.STATUS
    ability.status_effect = status
    ability.mp_cost = mp_cost
    
    # Set custom message if provided
    if custom_message != "":
        ability.custom_message = custom_message
    
    return ability

# Create a heal over time ability
static func create_hot_ability(
    name: String, 
    healing_per_tick: int, 
    duration: int, 
    target_type: int, 
    description: String, 
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    # First create the healing ability that will be applied on each tick
    var healing_ability = Ability.new()
    healing_ability.name = name + " (HoT)"
    healing_ability.power = healing_per_tick
    healing_ability.target_type = target_type
    healing_ability.effect_type = Ability.EffectType.HEALING
    
    # Create the status effect
    var status = StatusEffect.new()
    status.name = name + " Effect"
    status.description = "Healing %d HP at the start of each turn for %d turns" % [healing_per_tick, duration]
    status.duration = duration
    status.trigger_type = StatusEffect.TriggerType.TURN_START
    status.ability = healing_ability
    
    # Create the ability that applies the status effect
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.STATUS
    ability.status_effect = status
    ability.mp_cost = mp_cost
    
    # Set custom message if provided
    if custom_message != "":
        ability.custom_message = custom_message
    
    return ability

# Create a damage reduction ability
static func create_damage_reduction_ability(
    name: String, 
    reduction_percent: int, 
    duration: int, 
    target_type: int, 
    description: String, 
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    # Create the status effect for damage reduction
    var status = StatusEffect.new()
    status.name = name + " Effect"
    status.description = "Reduces incoming damage by %d%% for %d turns" % [reduction_percent, duration]
    status.duration = duration
    status.trigger_type = StatusEffect.TriggerType.ON_DAMAGE_TAKEN
    status.effect_behavior = StatusEffect.EffectBehavior.REDUCE_DAMAGE
    status.damage_reduction_percent = reduction_percent
    
    # Create the ability that applies the status effect
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.STATUS
    ability.status_effect = status
    ability.mp_cost = mp_cost
    
    # Set custom message if provided
    if custom_message != "":
        ability.custom_message = custom_message
    
    return ability

# Create a status effect ability with an expiry effect
static func create_status_effect_with_expiry(
    name: String, 
    duration: int,
    target_type: int, 
    description: String,
    trigger_type: int,
    apply_ability: Ability,
    expiry_ability: Ability,
    stacking_behavior: int = StatusEffect.StackingBehavior.REPLACE,
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    # Create the status effect
    var status = StatusEffect.new()
    status.name = name + " Effect"
    status.description = description
    status.duration = duration
    status.trigger_type = trigger_type
    status.ability = apply_ability
    status.effect_behavior = StatusEffect.EffectBehavior.APPLY_ABILITY
    status.expiry_behavior = StatusEffect.ExpiryBehavior.APPLY_ABILITY
    status.expiry_ability = expiry_ability
    status.stacking_behavior = stacking_behavior
    
    # Create the ability that applies the status effect
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.STATUS
    ability.status_effect = status
    ability.mp_cost = mp_cost
    
    # Set custom message if provided
    if custom_message != "":
        ability.custom_message = custom_message
    
    return ability

# Create a damage reduction ability with specific stacking behavior
static func create_advanced_damage_reduction(
    name: String, 
    reduction_percent: int, 
    duration: int, 
    target_type: int, 
    description: String,
    stacking_behavior: int = StatusEffect.StackingBehavior.REFRESH,
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    # Create the status effect for damage reduction
    var status = StatusEffect.new()
    status.name = name + " Effect"
    status.description = "Reduces incoming damage by %d%% for %d turns" % [reduction_percent, duration]
    status.duration = duration
    status.trigger_type = StatusEffect.TriggerType.ON_DAMAGE_TAKEN
    status.effect_behavior = StatusEffect.EffectBehavior.REDUCE_DAMAGE
    status.damage_reduction_percent = reduction_percent
    status.stacking_behavior = stacking_behavior
    
    # Create the ability that applies the status effect
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.STATUS
    ability.status_effect = status
    ability.mp_cost = mp_cost
    
    # Set custom message if provided
    if custom_message != "":
        ability.custom_message = custom_message
    
    return ability

# Create a multi-effect ability that applies multiple effects at once
static func create_multi_effect_ability(
    name: String,
    target_type: int,
    description: String,
    effects: Array,
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    # Create the multi-effect ability
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.MULTI
    ability.additional_effects = effects
    ability.mp_cost = mp_cost
    
    # Set custom message if provided
    if custom_message != "":
        ability.custom_message = custom_message
    
    return ability

# Create an MP restore ability
static func create_mp_restore_ability(
    name: String,
    mp_amount: int,
    target_type: int,
    description: String,
    custom_message: String = "",
    mp_cost: int = 0
) -> Ability:
    # Custom ability for MP restoration
    var ability = Ability.new()
    ability.name = name
    ability.target_type = target_type
    ability.description = description
    ability.effect_type = Ability.EffectType.UTILITY
    ability.mp_cost = mp_cost
    
    # Set custom message
    if custom_message != "":
        ability.custom_message = custom_message
    else:
        ability.custom_message = "{user} restores {power} MP to {target}!"
    
    # We'll handle the MP restoration in the CombatSystem when abilities are used
    # This is a placeholder for now
    
    return ability