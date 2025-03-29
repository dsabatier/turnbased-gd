# CombatSystem.gd
class_name CombatSystem
extends Node

signal combat_log_updated(message)
signal turn_started(combatant)
signal round_started(round_number)
signal combat_ended(winner)
signal combat_started()

var player_combatants: Array[Combatant] = []
var cpu_combatants: Array[Combatant] = []
var turn_order: Array[Combatant] = []
var current_turn_index: int = 0
var round_number: int = 1
var logs: Array[String] = []
var is_over: bool = false
var winner: String = ""

func _ready():
	# Connect signals from all combatants
	for combatant in player_combatants + cpu_combatants:
		combatant.defeated.connect(_on_combatant_defeated)

func start():
	determine_turn_order()
	round_number = 1
	current_turn_index = 0
	is_over = false
	winner = ""
	
	add_log("Combat started! Round %d" % round_number)
	
	# Emit the combat_started signal before anything else
	emit_signal("combat_started")
	
	# Then emit round started
	emit_signal("round_started", round_number)
	
	# Start the first turn
	process_next_turn()

func determine_turn_order():
	# Combine all combatants and sort by speed (highest first)
	turn_order = player_combatants + cpu_combatants
	turn_order.sort_custom(func(a, b): return a.speed > b.speed)

# Check if combat is over
func check_combat_status() -> bool:
	var all_player_defeated = player_combatants.all(func(combatant): return combatant.is_defeated)
	var all_cpu_defeated = cpu_combatants.all(func(combatant): return combatant.is_defeated)
	
	if all_player_defeated:
		is_over = true
		winner = "CPU"
		add_log("All player combatants are defeated! CPU wins!")
		emit_signal("combat_ended", winner)
	elif all_cpu_defeated:
		is_over = true
		winner = "Player"
		add_log("All CPU combatants are defeated! Player wins!")
		emit_signal("combat_ended", winner)
	
	return is_over

# Process a turn for the current combatant
func process_turn(ability_index: int, target_combatant: Combatant = null) -> void:
	var current_combatant = turn_order[current_turn_index]
	
	# Process start-of-turn status effects
	process_status_effects(current_combatant, StatusEffect.TriggerType.TURN_START)
	
	if current_combatant.is_defeated:
		add_log("%s is defeated and cannot act!" % current_combatant.name)
	else:
		# If the ability is SELF-targeting and no target is provided, target self
		var ability = current_combatant.abilities[ability_index]
		if ability.target_type == Ability.TargetType.SELF and target_combatant == null:
			target_combatant = current_combatant
			
		var result = current_combatant.use_ability(ability_index, target_combatant)
		add_log(result)
	
	# Process end-of-turn status effects
	process_status_effects(current_combatant, StatusEffect.TriggerType.TURN_END)
	
	# Check if combat has ended after status effects
	if not check_combat_status():
		process_next_turn()

# Process a CPU turn automatically
func process_cpu_turn() -> void:
	var current_combatant = turn_order[current_turn_index]
	
	if current_combatant.is_defeated:
		add_log("%s is defeated and cannot act!" % current_combatant.name)
		process_next_turn()
		return

	process_status_effects(current_combatant, StatusEffect.TriggerType.TURN_START)
	
	var friendlies = cpu_combatants if current_combatant.is_player == false else player_combatants
	var enemies = player_combatants if current_combatant.is_player == false else cpu_combatants
	
	var action = current_combatant.choose_action(friendlies, enemies)
	
	if action == null:
		add_log("%s couldn't find a valid action!" % current_combatant.name)
	else:
		var result = current_combatant.use_ability(action.ability, action.target)
		add_log(result)
	
	process_status_effects(current_combatant, StatusEffect.TriggerType.TURN_END)

	if not check_combat_status():
		process_next_turn()

# Process status effects of a specific trigger type
func process_status_effects(combatant: Combatant, trigger_type: int) -> void:
	if combatant.is_defeated:
		return
		
	var results = combatant.trigger_status_effects(trigger_type)
	for result in results:
		add_log(result)
		
	# Check combat status after each effect in case they cause defeat
	check_combat_status()

# Move to the next turn in order
func process_next_turn() -> void:
	current_turn_index = (current_turn_index + 1) % turn_order.size()
	
	# If we've gone through all combatants, start a new round
	if current_turn_index == 0:
		round_number += 1
		add_log("Round %d started!" % round_number)
		emit_signal("round_started", round_number)
	
	var current_combatant = turn_order[current_turn_index]
	emit_signal("turn_started", current_combatant)
	
	# If it's a CPU turn, automatically process it
	if not current_combatant.is_player:
		# Add a small delay before CPU acts for better visual flow
		await get_tree().create_timer(0.5).timeout
		process_cpu_turn()

func add_log(message: String) -> void:
	logs.append(message)
	emit_signal("combat_log_updated", message)

func _on_combatant_defeated(combatant: Combatant) -> void:
	add_log("%s has been defeated!" % combatant.name)
	check_combat_status()