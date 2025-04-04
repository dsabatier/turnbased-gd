# CombatSystem.gd
class_name CombatSystem
extends Node

signal round_started
signal round_ended
signal combat_ended(player_won)
signal turn_started(combatant)
signal turn_ended(combatant)

enum CombatState { SETUP, COMBAT_STARTING, TURN_ACTIVE, COMBAT_ENDED }
enum ActionType { BASIC_ATTACK, ABILITY, GUARD }

var player_combatants: Array[Combatant] = []
var enemy_combatants: Array[Combatant] = []
var turn_order: Array[Combatant] = []
var current_combatant_index: int = 0
var current_state: CombatState = CombatState.SETUP
var round_count: int = 0

func _ready() -> void:
	# Make sure we process turns properly
	set_process(false)

# Called when entering combat scene
func initialize_combat(player_team: Array[CombatantResource], enemy_team: Array[CombatantResource]) -> void:
	# Clear any existing combatants
	player_combatants.clear()
	enemy_combatants.clear()
	turn_order.clear()
	
	# Instantiate player combatants
	for resource in player_team:
		var combatant = Combatant.new()
		combatant.initialize(resource, true)
		player_combatants.append(combatant)
	
	# Instantiate enemy combatants
	for resource in enemy_team:
		var combatant = Combatant.new()
		combatant.initialize(resource, false)
		enemy_combatants.append(combatant)
	
	current_state = CombatState.COMBAT_STARTING
	round_count = 0
	
	# Defer starting combat to avoid issues with signal connections
	call_deferred("start_combat")

# Start the combat sequence
func start_combat() -> void:
	round_count += 1
	determine_turn_order()
	current_combatant_index = 0
	current_state = CombatState.TURN_ACTIVE
	emit_signal("round_started")
	start_next_turn()

# Calculate turn order based on speed
func determine_turn_order() -> void:
	turn_order.clear()
	
	# Add all active combatants to the order list
	for combatant in player_combatants:
		if combatant.current_hp > 0:
			turn_order.append(combatant)
	
	for combatant in enemy_combatants:
		if combatant.current_hp > 0:
			turn_order.append(combatant)
	
	# Sort by speed (higher goes first)
	turn_order.sort_custom(func(a, b): return a.get_modified_stat("speed") > b.get_modified_stat("speed"))

# Start the next combatant's turn
func start_next_turn() -> void:
	if current_state == CombatState.COMBAT_ENDED:
		return
		
	if current_combatant_index >= turn_order.size():
		end_round()
		return
		
	var current_combatant = turn_order[current_combatant_index]
	
	# Skip dead combatants
	if current_combatant.current_hp <= 0:
		current_combatant_index += 1
		start_next_turn()
		return
	
	# Process turn start effects
	current_combatant.process_status_effects(StatusEffectResource.TriggerType.TURN_START)
	
	# Check if combatant died from status effects
	if current_combatant.current_hp <= 0:
		current_combatant_index += 1
		start_next_turn()
		return
	
	# Signal turn started
	emit_signal("turn_started", current_combatant)
	
	# If it's an enemy, we'll need to handle AI decision making
	if !current_combatant.is_player:
		# Add a small delay to make enemy turns visible to the player
		await get_tree().create_timer(0.5).timeout
		perform_enemy_action(current_combatant)

# Process an action from a combatant
func process_action(combatant: Combatant, action_type: ActionType, ability: AbilityResource = null, target: Combatant = null) -> void:
	if combatant != turn_order[current_combatant_index]:
		print("Error: It's not this combatant's turn!")
		return
	
	match action_type:
		ActionType.BASIC_ATTACK:
			process_basic_attack(combatant, target)
		ActionType.ABILITY:
			if ability:
				process_ability(combatant, ability, target)
		ActionType.GUARD:
			process_guard(combatant)
	
	# Process turn end effects
	combatant.process_status_effects(StatusEffectResource.TriggerType.TURN_END)
	
	# End the turn
	emit_signal("turn_ended", combatant)
	current_combatant_index += 1
	
	# Check if combat should end
	if check_combat_end():
		return
		
	# Start the next turn
	start_next_turn()

# Process a basic attack
func process_basic_attack(attacker: Combatant, target: Combatant) -> void:
	# Basic attack logic
	var base_damage = attacker.get_modified_stat("physical_attack")
	var defense = target.get_modified_stat("physical_defense")
	var damage = max(1, base_damage - defense/2)
	
	# Apply damage with physical damage type
	apply_damage(attacker, target, damage, "physical")

# Process an ability
func process_ability(user: Combatant, ability: AbilityResource, target: Combatant) -> void:
	# Check if user has enough MP
	if user.current_mp < ability.mp_cost:
		print("Not enough MP to use this ability!")
		return
	
	# Deduct MP
	user.current_mp -= ability.mp_cost
	user.emit_signal("mp_changed", user.current_mp, user.get_modified_stat("max_mp"))
	
	# Process ability effects based on its type
	# This would need to be expanded based on your ability implementation
	print(user.display_name + " used " + ability.display_name + " on " + target.display_name)
	
	# Apply a basic damage effect for demo purposes
	var damage = user.get_modified_stat("magic_attack") * 1.5
	apply_damage(user, target, int(damage), "magical")

# Process guard action
func process_guard(combatant: Combatant) -> void:
	# Apply a guard status effect
	var guard_effect = StatusEffect.new()
	guard_effect.initialize_basic("Guard", "Increases defense until next turn", 1)
	guard_effect.modify_physical_defense = 5
	guard_effect.modify_magic_defense = 5
	combatant.add_status_effect(guard_effect)

# Apply damage to a target
func apply_damage(attacker: Combatant, target: Combatant, amount: int, damage_type: String) -> void:
	# Check for resistances
	var final_damage = calculate_damage_with_resistances(target, amount, damage_type)
	
	# Apply damage
	target.take_damage(final_damage)
	
	# Trigger on damage effects
	target.process_status_effects(StatusEffectResource.TriggerType.ON_DAMAGE_TAKEN)
	
	# Check if target is defeated
	if target.current_hp <= 0:
		print(target.display_name + " has been defeated!")

# Calculate damage with resistances
func calculate_damage_with_resistances(target: Combatant, base_damage: int, damage_type: String) -> int:
	var resistance_multiplier = 1.0
	
	# Check if target has resistance to this damage type
	for resistance in target.damage_resistances:
		if resistance and resistance.id == damage_type:
			resistance_multiplier = 0.5
			break
	
	return int(base_damage * resistance_multiplier)

# Perform an automated action for enemy combatants
func perform_enemy_action(enemy: Combatant) -> void:
	# Simple AI: randomly choose between basic attack or an ability
	var action_choice = randi() % 10  # 0-9
	var targets = get_valid_targets(enemy, true)  # Target player combatants
	
	if targets.is_empty():
		end_combat(false)  # No valid targets, player lost
		return
	
	# Select a random target from valid targets
	var target = targets[randi() % targets.size()]
	
	if action_choice < 7:  # 70% chance for basic attack
		process_action(enemy, ActionType.BASIC_ATTACK, null, target)
	elif action_choice < 9:  # 20% chance for ability (if available)
		if enemy.abilities.size() > 0 and enemy.current_mp > 0:
			var ability_index = randi() % enemy.abilities.size()
			if ability_index < enemy.abilities.size():
				var ability = enemy.abilities[ability_index]
				if ability and enemy.current_mp >= ability.mp_cost:
					process_action(enemy, ActionType.ABILITY, ability, target)
				else:
					process_action(enemy, ActionType.BASIC_ATTACK, null, target)
			else:
				process_action(enemy, ActionType.BASIC_ATTACK, null, target)
		else:
			process_action(enemy, ActionType.BASIC_ATTACK, null, target)
	else:  # 10% chance for guard
		process_action(enemy, ActionType.GUARD)

# Get valid targets based on if we want player or enemy targets
func get_valid_targets(combatant: Combatant, target_enemies: bool) -> Array[Combatant]:
	var valid_targets: Array[Combatant] = []
	
	if target_enemies:
		# Targeting enemies (for either player or enemy)
		if combatant.is_player:
			# Player targeting enemies
			for target in enemy_combatants:
				if target.current_hp > 0:
					valid_targets.append(target)
		else:
			# Enemy targeting players
			for target in player_combatants:
				if target.current_hp > 0:
					valid_targets.append(target)
	else:
		# Targeting allies
		if combatant.is_player:
			# Player targeting players
			for target in player_combatants:
				if target.current_hp > 0:
					valid_targets.append(target)
		else:
			# Enemy targeting enemies
			for target in enemy_combatants:
				if target.current_hp > 0:
					valid_targets.append(target)
				
	return valid_targets

# End the current round
func end_round() -> void:
	emit_signal("round_ended")
	
	# Check if combat should end
	if check_combat_end():
		return
	
	# Start the next round
	start_combat()

# Check if combat should end
func check_combat_end() -> bool:
	var player_alive = false
	var enemy_alive = false
	
	# Check if any player combatants are still alive
	for combatant in player_combatants:
		if combatant.current_hp > 0:
			player_alive = true
			break
	
	# Check if any enemy combatants are still alive
	for combatant in enemy_combatants:
		if combatant.current_hp > 0:
			enemy_alive = true
			break
	
	# If one side has been defeated, end combat
	if !player_alive or !enemy_alive:
		end_combat(enemy_alive == false)
		return true
	
	return false

# End combat with result
func end_combat(player_won: bool) -> void:
	current_state = CombatState.COMBAT_ENDED
	
	# If player won, heal combatants by 50%
	if player_won:
		for combatant in player_combatants:
			if combatant.current_hp > 0:
				# Regenerate 50% of max HP and MP
				var hp_regen = int(combatant.max_hp * 0.5)
				var mp_regen = int(combatant.max_mp * 0.5)
				
				combatant.current_hp = min(combatant.current_hp + hp_regen, combatant.max_hp)
				combatant.current_mp = min(combatant.current_mp + mp_regen, combatant.max_mp)
				
				# Make sure signals are emitted for UI updates
				combatant.emit_signal("hp_changed", combatant.current_hp, combatant.get_modified_stat("max_hp"))
				combatant.emit_signal("mp_changed", combatant.current_mp, combatant.get_modified_stat("max_mp"))
	
	emit_signal("combat_ended", player_won)

# Generate a random enemy team for the next battle
func generate_random_enemy_team() -> Array[CombatantResource]:
	var enemy_resources: Array[CombatantResource] = []
	var all_enemies = CombatantDatabase.get_enemy_combatants()
	
	# If no enemies in pool, return empty array
	if all_enemies.is_empty():
		return enemy_resources
	
	# Choose 1-4 random enemies
	var enemy_count = 1 + randi() % 4  # 1 to 4 enemies
	
	# Make a copy to avoid modifying the original array
	var enemy_pool = all_enemies.duplicate()
	
	for i in range(enemy_count):
		if enemy_pool.is_empty():
			break
			
		var random_index = randi() % enemy_pool.size()
		enemy_resources.append(enemy_pool[random_index])
		
		# Remove to avoid duplicates
		enemy_pool.remove_at(random_index)
	
	return enemy_resources