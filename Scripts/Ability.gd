# Ability.gd
class_name Ability
extends Resource

enum TargetType {ENEMY, FRIENDLY, SELF, OTHER_FRIENDLY, ANY}
enum EffectType {DAMAGE, HEALING, STATUS, UTILITY, MULTI}
enum DamageType {PHYSICAL, MAGICAL, PURE} # Pure damage bypasses defenses

@export var name: String
@export var power: int
@export var target_type: TargetType
@export var description: String
@export var effect_type: EffectType = EffectType.DAMAGE
@export var custom_message: String = ""  # Custom message to display when used
@export var mp_cost: int = 0  # MP cost to use this ability
@export var damage_type: DamageType = DamageType.PHYSICAL # Only relevant for damage abilities

# For status effect abilities
@export var status_effect: StatusEffect = null

# New properties for multi-effect abilities
@export var additional_effects: Array = [] # Can contain Abilities or StatusEffects
@export var apply_all_effects: bool = true # If false, apply effects randomly or conditionally

# This is the updated execute method for Ability.gd
func execute(user, target):
    # Get display name with proper fallbacks
    var user_name = user.display_name if user.has_method("get") and user.get("display_name") != "" else user.name
    var target_name = target.display_name if target.has_method("get") and target.get("display_name") != "" else target.name
    
    var result = ""
    
    match effect_type:
        EffectType.DAMAGE:
            var damage = power
            
            # Apply stat scaling
            if damage_type == DamageType.PHYSICAL:
                # Physical attacks scale with physical_attack (each point adds 1% to base damage)
                damage += int(power * (user.physical_attack / 100.0))
                var actual_damage = target.take_damage(damage, false)  # false = physical damage
                
                if custom_message != "":
                    result = custom_message.format({"user": user_name, "target": target_name, "power": actual_damage, "effect": name})
                # If damage was reduced, mention it
                elif actual_damage < damage:
                    result = "%s used %s on %s for %d damage (reduced from %d)!" % [user_name, name, target_name, actual_damage, damage]
                else:
                    result = "%s used %s on %s for %d damage!" % [user_name, name, target_name, actual_damage]
            
            elif damage_type == DamageType.MAGICAL:
                # Magical attacks scale with magic_attack (each point adds 1% to base damage)
                damage += int(power * (user.magic_attack / 100.0))
                var actual_damage = target.take_damage(damage, true)  # true = magical damage
                
                if custom_message != "":
                    result = custom_message.format({"user": user_name, "target": target_name, "power": actual_damage, "effect": name})
                # If damage was reduced, mention it
                elif actual_damage < damage:
                    result = "%s used %s on %s for %d magical damage (reduced from %d)!" % [user_name, name, target_name, actual_damage, damage]
                else:
                    result = "%s used %s on %s for %d magical damage!" % [user_name, name, target_name, actual_damage]
            
            else: # PURE damage
                # Pure damage bypasses defense calculations
                var actual_damage = target.take_damage(damage)
                
                if custom_message != "":
                    result = custom_message.format({"user": user_name, "target": target_name, "power": actual_damage, "effect": name})
                else:
                    result = "%s used %s on %s for %d pure damage!" % [user_name, name, target_name, actual_damage]
            
        EffectType.HEALING:
            var healing = power
            target.heal(healing)
            if custom_message != "":
                result = custom_message.format({"user": user_name, "target": target_name, "power": healing})
            else:
                result = "%s used %s on %s for %d healing!" % [user_name, name, target_name, healing]
            
        EffectType.STATUS:
            if status_effect != null:
                # Clone the status effect to ensure each application is unique
                var effect_instance = status_effect.create_duplicate()
                var status_result = effect_instance.apply(target, user)
                
                if custom_message != "":
                    result = custom_message.format({
                        "user": user_name, 
                        "target": target_name, 
                        "effect": status_effect.name,
                        "duration": status_effect.duration
                    })
                else:
                    result = "%s used %s on %s! %s" % [user_name, name, target_name, status_result]
            else:
                result = "%s used %s but nothing happened!" % [user_name, name]
                
        EffectType.UTILITY:
            if custom_message != "":
                result = custom_message.format({"user": user_name, "target": target_name})
            elif name.begins_with("Skip"):
                result = "%s decided to %s!" % [user_name, name.to_lower()]
            else:
                result = "%s used %s!" % [user_name, name]
                
        EffectType.MULTI:
            # Create a basic message about using the ability
            if custom_message != "":
                result = custom_message.format({"user": user_name, "target": target_name})
            else:
                result = "%s used %s on %s!" % [user_name, name, target_name]
            
            # Process the main effect if there is one (damage, healing, etc.)
            var main_result = ""
            if effect_type != EffectType.MULTI:
                # Create a copy of this ability without additional effects to avoid recursion
                var main_ability = create_copy()
                main_ability.additional_effects = []
                main_ability.effect_type = effect_type
                main_result = main_ability.execute(user, target)
                if main_result != "":
                    result += "\n" + main_result
            
            # Process additional effects
            for effect in additional_effects:
                if effect is Ability:
                    # Execute the additional ability
                    var ability_result = effect.execute(user, target)
                    if ability_result != "":
                        result += "\n" + ability_result
                elif effect is StatusEffect:
                    # Apply the additional status effect
                    var effect_instance = effect.create_duplicate()
                    var status_result = effect_instance.apply(target, user)
                    if status_result != "":
                        result += "\n" + status_result
    
    # Process additional effects for non-MULTI type abilities
    if effect_type != EffectType.MULTI and additional_effects.size() > 0:
        for effect in additional_effects:
            if effect is Ability:
                # Execute the additional ability
                var ability_result = effect.execute(user, target)
                if ability_result != "":
                    result += "\n" + ability_result
            elif effect is StatusEffect:
                # Apply the additional status effect
                var effect_instance = effect.create_duplicate()
                var status_result = effect_instance.apply(target, user)
                if status_result != "":
                    result += "\n" + status_result
    
    return result
    
# Create a copy with all properties preserved
func create_copy():
    var new_ability = Ability.new()
    new_ability.name = name
    new_ability.power = power
    new_ability.target_type = target_type
    new_ability.description = description
    new_ability.effect_type = effect_type
    new_ability.custom_message = custom_message
    new_ability.status_effect = status_effect
    new_ability.additional_effects = additional_effects.duplicate()
    new_ability.apply_all_effects = apply_all_effects
    new_ability.mp_cost = mp_cost
    new_ability.damage_type = damage_type
    return new_ability