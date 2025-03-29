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

func execute(user, target):
	match effect_type:
		EffectType.DAMAGE:
			var damage = power
			target.take_damage(damage)
			if custom_message != "":
				return custom_message.format({"user": user.name, "target": target.name, "power": damage, "effect": name})
			return "%s used %s on %s for %d damage!" % [user.name, name, target.name, damage]
			
		EffectType.HEALING:
			var healing = power
			target.heal(healing)
			if custom_message != "":
				return custom_message.format({"user": user.name, "target": target.name, "power": healing})
			return "%s used %s on %s for %d healing!" % [user.name, name, target.name, healing]
			
		EffectType.STATUS:
			if status_effect != null:
				# Clone the status effect to ensure each application is unique
				var effect_instance = status_effect.duplicate()
				var result = effect_instance.apply(target, user)
				
				if custom_message != "":
					var formatted_message = custom_message.format({
						"user": user.name, 
						"target": target.name, 
						"effect": status_effect.name,
						"duration": status_effect.duration
					})
					return formatted_message
				return "%s used %s on %s! %s" % [user.name, name, target.name, result]
			else:
				return "%s used %s but nothing happened!" % [user.name, name]
				
		EffectType.UTILITY:
			if custom_message != "":
				return custom_message.format({"user": user.name, "target": target.name})
			elif name.begins_with("Skip"):
				return "%s decided to %s!" % [user.name, name.to_lower()]
			return "%s used %s!" % [user.name, name]
				
	return ""