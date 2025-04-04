# CombatUI.gd
extends Control

signal continue_combat

# References to UI elements
@onready var player_container = find_child("PlayerContainer", true, false)
@onready var enemy_container = find_child("EnemyContainer", true, false)
@onready var action_panel = find_child("ActionPanel", true, false) 
@onready var ability_list = find_child("AbilityList", true, false)
@onready var status_label = find_child("StatusLabel", true, false)
@onready var target_cursor = find_child("TargetCursor", true, false)
@onready var end_combat_dialog = find_child("EndCombatDialog", true, false)

# References to other scenes
var combatant_card_scene = preload("res://Scenes/combatant_card.tscn")

# References to the combat system
var combat_system: CombatSystem

# Current state tracking
var current_combatant: Combatant
var selected_action: int  # Using CombatSystem.ActionType enum
var selected_ability: AbilityResource
var potential_targets: Array[Combatant] = []
var selected_target_index: int = 0

func _ready() -> void:
	# Hide action panel and target cursor initially
	if action_panel:
		action_panel.visible = false
	if target_cursor:
		target_cursor.visible = false
	
	# Connect signals - find buttons by their names regardless of hierarchy
	var attack_button = find_child("AttackButton", true, false)
	var abilities_button = find_child("AbilitiesButton", true, false)
	var guard_button = find_child("GuardButton", true, false)
	var back_button = find_child("BackButton", true, false)
	
	if attack_button:
		attack_button.pressed.connect(_on_attack_button_pressed)
	if abilities_button:
		abilities_button.pressed.connect(_on_abilities_button_pressed)
	if guard_button:
		guard_button.pressed.connect(_on_guard_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	if ability_list:
		ability_list.item_selected.connect(_on_ability_selected)

func initialize(combat_sys: CombatSystem) -> void:
	combat_system = combat_sys
	
	# Connect combat system signals
	combat_system.turn_started.connect(_on_turn_started)
	combat_system.combat_ended.connect(_on_combat_ended)
	
	# Create UI cards for each combatant
	_create_combatant_cards()

func _create_combatant_cards() -> void:
	# Clear existing cards
	for child in player_container.get_children():
		child.queue_free()
	
	for child in enemy_container.get_children():
		child.queue_free()
	
	# Create player combatant cards
	for combatant in combat_system.player_combatants:
		var card = combatant_card_scene.instantiate()
		card.initialize(combatant)
		player_container.add_child(card)
	
	# Create enemy combatant cards
	for combatant in combat_system.enemy_combatants:
		var card = combatant_card_scene.instantiate()
		card.initialize(combatant)
		enemy_container.add_child(card)

func _on_turn_started(combatant: Combatant) -> void:
	current_combatant = combatant
	
	# Update status label
	status_label.text = combatant.display_name + "'s turn"
	
	if combatant.is_player:
		# Player's turn - show action panel
		_show_action_menu()
	else:
		# Enemy's turn - hide action panel
		action_panel.visible = false
		target_cursor.visible = false

func _show_action_menu() -> void:
	# Show main action buttons
	if action_panel:
		action_panel.visible = true
	
	# Show main buttons, hide ability list
	var main_buttons = find_child("MainButtons", true, false)
	if main_buttons:
		main_buttons.visible = true
	if ability_list:
		ability_list.visible = false
	
	var back_button = find_child("BackButton", true, false)
	if back_button:
		back_button.visible = false
	
	# Hide target cursor
	if target_cursor:
		target_cursor.visible = false
	
	# Update button states based on available actions
	var abilities_button = find_child("AbilitiesButton", true, false)
	if abilities_button and current_combatant:
		abilities_button.disabled = current_combatant.abilities.is_empty() or current_combatant.current_mp <= 0

func _on_attack_button_pressed() -> void:
	selected_action = CombatSystem.ActionType.BASIC_ATTACK
	_show_target_selection(true)  # true for enemies as targets

func _on_abilities_button_pressed() -> void:
	# Show ability list and back button
	var main_buttons = find_child("MainButtons", true, false)
	if main_buttons:
		main_buttons.visible = false
	if ability_list:
		ability_list.visible = true
	
	var back_button = find_child("BackButton", true, false)
	if back_button:
		back_button.visible = true
	
	# Populate ability list
	if ability_list and current_combatant:
		ability_list.clear()
		
		for ability in current_combatant.abilities:
			var mp_text = " (MP: " + str(ability.mp_cost) + ")"
			var disabled = ability.mp_cost > current_combatant.current_mp
			
			ability_list.add_item(ability.display_name + mp_text, null, disabled)

func _on_guard_button_pressed() -> void:
	selected_action = CombatSystem.ActionType.GUARD
	
	# Guard doesn't need a target
	combat_system.process_action(current_combatant, selected_action)
	
	# Hide action panel after action
	action_panel.visible = false

func _on_back_button_pressed() -> void:
	# Go back to main action menu
	_show_action_menu()

func _on_ability_selected(index: int) -> void:
	selected_action = CombatSystem.ActionType.ABILITY
	selected_ability = current_combatant.abilities[index]
	
	# Determine valid targets based on ability's target type
	var target_enemies = true
	
	match selected_ability.target_type:
		AbilityResource.TargetType.ENEMY:
			target_enemies = true
		AbilityResource.TargetType.FRIENDLY:
			target_enemies = false
		AbilityResource.TargetType.SELF:
			# No target selection needed for self-targeting
			combat_system.process_action(current_combatant, selected_action, selected_ability, current_combatant)
			action_panel.visible = false
			return
		AbilityResource.TargetType.OTHER_FRIENDLY:
			target_enemies = false
			# Filter out self from potential targets later
		AbilityResource.TargetType.ANY:
			# Will need special handling for this case
			target_enemies = true  # Default to enemies first
	
	_show_target_selection(target_enemies)

func _show_target_selection(target_enemies: bool) -> void:
	# Get valid targets
	potential_targets = combat_system.get_valid_targets(current_combatant, !target_enemies)
	
	# If no valid targets, show message and return to action menu
	if potential_targets.is_empty():
		status_label.text = "No valid targets!"
		_show_action_menu()
		return
	
	# Hide action panel and show target cursor
	action_panel.visible = false
	target_cursor.visible = true
	
	# Start with first target
	selected_target_index = 0
	_update_target_cursor()

func _update_target_cursor() -> void:
	# Position the cursor over the selected target
	var target = potential_targets[selected_target_index]
	
	# Find the card corresponding to this target
	var container = enemy_container if target in combat_system.enemy_combatants else player_container
	var target_card = null
	
	for card in container.get_children():
		if card.combatant == target:
			target_card = card
			break
	
	if target_card:
		# Position cursor above the card
		target_cursor.global_position = target_card.global_position + Vector2(target_card.size.x / 2, -20)
		
		# Update status text
		status_label.text = "Select target: " + target.display_name

func _input(event: InputEvent) -> void:
	# Only process input during target selection
	if !target_cursor.visible:
		return
	
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left"):
		# Change target
		selected_target_index = (selected_target_index + 1) % potential_targets.size()
		_update_target_cursor()
	
	elif event.is_action_pressed("ui_accept"):
		# Confirm target selection
		var target = potential_targets[selected_target_index]
		
		# Process the selected action
		match selected_action:
			CombatSystem.ActionType.BASIC_ATTACK:
				combat_system.process_action(current_combatant, selected_action, null, target)
			CombatSystem.ActionType.ABILITY:
				combat_system.process_action(current_combatant, selected_action, selected_ability, target)
		
		# Hide cursor after action
		target_cursor.visible = false
	
	elif event.is_action_pressed("ui_cancel"):
		# Cancel target selection and return to action menu
		target_cursor.visible = false
		_show_action_menu()

func _on_combat_ended(player_won: bool) -> void:
	# Hide action panel and target cursor
	action_panel.visible = false
	target_cursor.visible = false
	
	# Show result message
	if player_won:
		status_label.text = "Victory!"
	else:
		status_label.text = "Defeat!"
	
	# Show end combat dialog
	end_combat_dialog.dialog_title = "Combat Ended"
	end_combat_dialog.dialog_text = "You " + ("won" if player_won else "lost") + " the battle!"
	end_combat_dialog.visible = true
