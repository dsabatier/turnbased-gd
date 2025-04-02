# Ability.gd updated for resource-based damage types
class_name Ability
extends Resource

enum TargetType {ENEMY, FRIENDLY, SELF, OTHER_FRIENDLY, ANY}
enum EffectType {DAMAGE, HEALING, STATUS, UTILITY, MULTI, MP_RESTORE}

@export var name: String
@export var power: int
@export var target_type: TargetType
@export var description: String
@export var effect_type: EffectType = EffectType.DAMAGE
@export var custom_message: String = ""  # Custom message to display when used
@export var mp_cost: int = 0  # MP cost to use this ability

# Use DamageTypeResource instead of string ID
@export var damage_type: Resource = null  # DamageTypeResource reference
# Keep for backward compatibility and internal use
var damage_type_id: String = "physical"  # Will be set from damage_type.id

# For status effect abilities
@export var status_effect: StatusEffect = null

# For multi-effect abilities
@export var additional_effects: Array = [] # Can contain Abilities or StatusEffects
@export var apply_all_effects: bool = true # If false, apply effects randomly or conditionally

# Reference to source resource (if created from a resource)
var source_resource: Resource = null

# Get the defense stat to use based on the damage type
func get_defense_stat() -> String:
	if damage_type and damage_type is DamageTypeResource:
		return damage_type.defense_stat
	return "physical_defense" # Default fallback

# Returns the actual damage type ID, preferring DamageTypeResource if available
func get_damage_type_id() -> String:
	if damage_type and damage_type is DamageTypeResource:
		return damage_type.id
	return damage_type_id

# Updated execute method to use the damage type system - now accepts the damage manager
func execute(user, target, damage_manager = null):
	# Get display name with proper fallbacks
	var user_name = user.display_name if user.has_method("get") and user.get("display_name") != "" else user.name
	var target_name = target.display_name if target.has_method("get") and target.get("display_name") != "" else target.name
	
	var result = ""
	
	match effect_type:
		EffectType.DAMAGE:
			# Use the provided damage manager, or fall back to default behavior
			if damage_manager == null:
				# Fall back to simple damage calculation
				var damage = power
				if user.has_method("get") and target.has_method("get"):
						# Use defense_stat from the damage type resource
					var defense_stat = get_defense_stat()
					
					if defense_stat == "physical_defense":
						damage += int(power * (user.physical_attack / 100.0))
						# Reduce by physical defense
						var reduction = int(damage * (target.physical_defense / 100.0))
						damage = max(1, damage - reduction)
					elif defense_stat == "magic_defense":
						damage += int(power * (user.magic_attack / 100.0))
						# Reduce by magic defense
						var reduction = int(damage * (target.magic_defense / 100.0))
						damage = max(1, damage - reduction)
					else: # "none" or other special cases
						damage += int(power * (user.physical_attack / 100.0))
						# No reduction for pure damage
						
				var actual_damage = target.take_damage(damage, get_damage_type_id())
				
				if custom_message != "":
					result = custom_message.format({
						"user": user_name, 
						"target": target_name, 
						"power": actual_damage, 
						"effect": name
					})
				else:
					result = "%s used %s on %s for %d damage!" % [user_name, name, target_name, actual_damage]
			else:
				# Use the data-driven damage system
				var damage_result = damage_manager.calculate_damage(power, get_damage_type_id(), user, target)
				
				# Apply the damage
				var apply_result = damage_manager.apply_damage_result(damage_result, user, target)
				
				# Generate the result message
				if custom_message != "":
					result = custom_message.format({
						"user": user_name, 
						"target": target_name, 
						"power": apply_result.damage_dealt, 
						"effect": name
					})
				else:
					var type_name = "Physical"
					if damage_type and damage_type is DamageTypeResource:
						type_name = damage_type.name
					else:
						var damage_type_data = damage_manager.get_damage_type(get_damage_type_id())
						type_name = damage_type_data.get("name", get_damage_type_id().capitalize())
					
					# Build message based on results
					if damage_result.flags.weak:
						result = "%s used %s for %d %s damage to %s! It's super effective!" % [
							user_name, name, apply_result.damage_dealt, type_name, target_name
						]
					elif damage_result.flags.resisted:
						result = "%s used %s for %d %s damage to %s! It's not very effective..." % [
							user_name, name, apply_result.damage_dealt, type_name, target_name
						]
					elif damage_result.flags.immune:
						result = "%s used %s but %s is immune to %s damage!" % [
							user_name, name, target_name, type_name
						]
					else:
						result = "%s used %s for %d %s damage to %s!" % [
							user_name, name, apply_result.damage_dealt, type_name, target_name
						]
			
		EffectType.HEALING:
			var healing = power
			
			# Apply healing modifiers from status effects
			var healing_modifier = 1.0
			for effect in user.status_effects:
				if effect.has_method("get") and effect.get("healing_dealt_percent_mod") != null:
					healing_modifier += effect.healing_dealt_percent_mod / 100.0
			
			# Apply the modifier
			healing = int(healing * healing_modifier)
			
			target.heal(healing)
			if custom_message != "":
				result = custom_message.format({
					"user": user_name, 
					"target": target_name, 
					"power": healing
				})
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
			# Handle utility abilities
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
			
			# Apply the primary effect (damage)
			if power > 0:
				# Calculate damage using defense_stat from damage_type
				var damage = power
				if user.get("physical_attack") != null and target.get("physical_defense") != null:
					var defense_stat = get_defense_stat()
					
					if defense_stat == "physical_defense":
						damage += int(power * (user.get_effective_physical_attack() / 100.0))
						var reduction = int(damage * (target.get_effective_physical_defense() / 100.0))
						damage = max(1, damage - reduction)
					elif defense_stat == "magic_defense":
						damage += int(power * (user.get_effective_magic_attack() / 100.0))
						var reduction = int(damage * (target.get_effective_magic_defense() / 100.0))
						damage = max(1, damage - reduction)
					else: # "none" or other special cases
						damage += int(power * (user.get_effective_physical_attack() / 100.0))
						# No reduction for pure damage
				
				var actual_damage = target.take_damage(damage, get_damage_type_id())
				result += "\n%s deals %d damage to %s!" % [user_name, actual_damage, target_name]
			
			# Apply status effect if one is set
			if status_effect != null:
				# Clone the status effect to ensure each application is unique
				var effect_instance = status_effect.create_duplicate()
				print("Applying status effect from MULTI: " + effect_instance.name)
				var status_result = effect_instance.apply(target, user)
				if status_result != "":
					result += "\n" + status_result
			
			# Process additional effects
			for effect in additional_effects:
				if effect is Ability:
					# Execute the additional ability
					var ability_result = effect.execute(user, target, damage_manager)
					if ability_result != "":
						result += "\n" + ability_result
				elif effect is StatusEffect:
					# Apply the additional status effect
					var effect_instance = effect.create_duplicate()
					var status_result = effect_instance.apply(target, user)
					if status_result != "":
						result += "\n" + status_result
		EffectType.MP_RESTORE:
			# Handle MP restoration
			var mp_amount = power
			
			# Apply the MP restoration to the target
			target.restore_mp(mp_amount)
			
			if custom_message != "":
				result = custom_message.format({
					"user": user_name, 
					"target": target_name, 
					"power": mp_amount
				})
			else:
				result = "%s used %s to restore %d MP to %s!" % [user_name, name, mp_amount, target_name]
	print("Executed ability: " + name + " with result: " + result)
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
	new_ability.damage_type_id = damage_type_id
	new_ability.source_resource = source_resource
	return new_ability

# Static method to create an ability from a resource
static func from_resource(ability_resource: AbilityResource) -> Ability:
	if ability_resource == null:
		return null
	return ability_resource.create_ability_instance()

# Check if this ability was created from a resource
func is_from_resource() -> bool:
	return source_resource != null

# Load damage type ID when damage_type resource is set
func set_damage_type(new_damage_type):
	damage_type = new_damage_type
	if damage_type and damage_type is DamageTypeResource:
		damage_type_id = damage_type.id
	else:
		damage_type_id = "physical"  # Default

# Called when the node enters the scene tree for the first time.
func _init():
	# Initialize damage type ID if damage type resource is set
	if damage_type and damage_type is DamageTypeResource:
		damage_type_id = damage_type.id
