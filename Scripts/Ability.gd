# Ability.gd
class_name Ability
extends Resource

enum TargetType {ENEMY, FRIENDLY, SELF, OTHER_FRIENDLY, ANY}
enum EffectType {DAMAGE, HEALING, STATUS, UTILITY}

@export var name: String
@export var power: int
@export var target_type: TargetType
@export var description: String
@export var effect_type: EffectType = EffectType.DAMAGE
@export var custom_message: String = ""  # Custom message to display when used

# For status effect abilities
@export var status_effect: StatusEffect = null

# This is the complete updated execute method for Ability.gd
func execute(user, target):
	# Get display name with proper fallbacks
	var user_name = user.display_name if user.has_method("get") and user.get("display_name") != "" else user.name
	var target_name = target.display_name if target.has_method("get") and target.get("display_name") != "" else target.name
	
	match effect_type:
		EffectType.DAMAGE:
			var damage = power
			target.take_damage(damage)
			if custom_message != "":
				return custom_message.format({"user": user_name, "target": target_name, "power": damage, "effect": name})
			return "%s used %s on %s for %d damage!" % [user_name, name, target_name, damage]
			
		EffectType.HEALING:
			var healing = power
			target.heal(healing)
			if custom_message != "":
				return custom_message.format({"user": user_name, "target": target_name, "power": healing})
			return "%s used %s on %s for %d healing!" % [user_name, name, target_name, healing]
			
		EffectType.STATUS:
			if status_effect != null:
				# Clone the status effect to ensure each application is unique
				var effect_instance = status_effect.duplicate()
				var result = effect_instance.apply(target, user)
				
				if custom_message != "":
					var formatted_message = custom_message.format({
						"user": user_name, 
						"target": target_name, 
						"effect": status_effect.name,
						"duration": status_effect.duration
					})
					return formatted_message
				return "%s used %s on %s! %s" % [user_name, name, target_name, result]
			else:
				return "%s used %s but nothing happened!" % [user_name, name]
				
		EffectType.UTILITY:
			if custom_message != "":
				return custom_message.format({"user": user_name, "target": target_name})
			elif name.begins_with("Skip"):
				return "%s decided to %s!" % [user_name, name.to_lower()]
			return "%s used %s!" % [user_name, name]
				
	return ""