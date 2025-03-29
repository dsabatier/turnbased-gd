# CombatUI.gd
extends Control

@export var combat_system: CombatSystem
@export var log_container: RichTextLabel
@export var player_container: VBoxContainer
@export var enemy_container: VBoxContainer
@export var ability_container: HBoxContainer

var selected_ability: int = -1
var player_combatant_buttons: Array = []
var enemy_combatant_buttons: Array = []

func _ready():
	# Connect signals but don't set up the UI yet
	combat_system.combat_log_updated.connect(_on_combat_log_updated)
	combat_system.turn_started.connect(_on_turn_started)
	combat_system.combat_ended.connect(_on_combat_ended)
	combat_system.combat_started.connect(_on_combat_started)
	
	# Clear the UI containers to ensure they're empty
	for child in player_container.get_children():
		child.queue_free()
	
	for child in enemy_container.get_children():
		child.queue_free()
	
	for child in ability_container.get_children():
		child.queue_free()
	
	log_container.text = "Waiting for combat to start...\n"

# Called when the combat_started signal is emitted
func _on_combat_started():
	setup_combatant_ui()
	log_container.text = "Combat initialized. Prepare for battle!\n"

func setup_combatant_ui():
	# Create buttons for player combatants
	for combatant in combat_system.player_combatants:
		var button = Button.new()
		update_combatant_button_text(button, combatant)
		button.disabled = true
		player_container.add_child(button)
		player_combatant_buttons.append(button)
		
		# Connect signals
		combatant.hp_changed.connect(func(current, max_val): 
			update_combatant_button_text(button, combatant)
		)
		
		combatant.status_effect_added.connect(func(effect): 
			update_combatant_button_text(button, combatant)
		)
		
		combatant.status_effect_removed.connect(func(effect): 
			update_combatant_button_text(button, combatant)
		)
	
	# Create buttons for CPU combatants
	for combatant in combat_system.cpu_combatants:
		var button = Button.new()
		update_combatant_button_text(button, combatant)
		enemy_container.add_child(button)
		enemy_combatant_buttons.append(button)
		
		# Connect signals
		combatant.hp_changed.connect(func(current, max_val): 
			update_combatant_button_text(button, combatant)
		)
		
		combatant.status_effect_added.connect(func(effect): 
			update_combatant_button_text(button, combatant)
		)
		
		combatant.status_effect_removed.connect(func(effect): 
			update_combatant_button_text(button, combatant)
		)
		
		combatant.defeated.connect(func(): button.disabled = true)

# Helper function to update button text with status effects
func update_combatant_button_text(button: Button, combatant: Combatant):
	var text = combatant.name + " HP: " + str(combatant.current_hp) + "/" + str(combatant.max_hp)
	
	# Add status effect icons/names if any exist
	if combatant.status_effects.size() > 0:
		text += " ["
		for i in range(combatant.status_effects.size()):
			var effect = combatant.status_effects[i]
			text += effect.name + "(" + str(effect.remaining_turns) + ")"
			if i < combatant.status_effects.size() - 1:
				text += ", "
		text += "]"
	
	button.text = text

func setup_ability_ui():
	# This would be set up when a player's turn starts
	pass

func update_ability_ui(combatant: Combatant):
	# Clear previous abilities
	for child in ability_container.get_children():
		child.queue_free()
	
	# Add buttons for each ability
	for i in range(combatant.abilities.size()):
		var ability = combatant.abilities[i]
		var button = Button.new()
		button.text = ability.name
		button.tooltip_text = ability.description
		button.pressed.connect(func(): _on_ability_selected(i))
		ability_container.add_child(button)

func _on_ability_selected(index: int):
	selected_ability = index
	
	# Enable/disable valid targets based on the ability's target type
	var current_combatant = combat_system.turn_order[combat_system.current_turn_index]
	var ability = current_combatant.abilities[selected_ability]
	
	# If it's a self-targeting ability, execute it immediately
	if ability.target_type == Ability.TargetType.SELF:
		combat_system.process_turn(selected_ability, current_combatant)
		selected_ability = -1
		return
	
	# Handle enemy targeting
	for i in range(enemy_combatant_buttons.size()):
		var enemy = combat_system.cpu_combatants[i]
		var button = enemy_combatant_buttons[i]
		
		# Disconnect any existing connections
		if button.is_connected("pressed", Callable(self, "_on_enemy_selected")):
			button.disconnect("pressed", Callable(self, "_on_enemy_selected"))
		
		# Enable only for enemy-targeting abilities
		button.disabled = enemy.is_defeated or ability.target_type != Ability.TargetType.ENEMY
		
		# Connect signal if button is enabled
		if not button.disabled:
			button.pressed.connect(func(): _on_enemy_selected(enemy))
	
	# Handle friendly targeting
	for i in range(player_combatant_buttons.size()):
		var player = combat_system.player_combatants[i]
		var button = player_combatant_buttons[i]
		
		# Disconnect any existing connections
		if button.is_connected("pressed", Callable(self, "_on_friendly_selected")):
			button.disconnect("pressed", Callable(self, "_on_friendly_selected"))
		
		# For OTHER_FRIENDLY, disable the current combatant's button
		var is_self = (player == current_combatant)
		var can_target = false
		
		if ability.target_type == Ability.TargetType.FRIENDLY and not player.is_defeated:
			can_target = true
		elif ability.target_type == Ability.TargetType.OTHER_FRIENDLY and not player.is_defeated and not is_self:
			can_target = true
		
		button.disabled = !can_target
		
		# Connect signal if button is enabled
		if not button.disabled:
			button.pressed.connect(func(): _on_friendly_selected(player))

func _on_enemy_selected(enemy: Combatant):
	if selected_ability >= 0:
		combat_system.process_turn(selected_ability, enemy)
		selected_ability = -1

func _on_friendly_selected(friendly: Combatant):
	if selected_ability >= 0:
		combat_system.process_turn(selected_ability, friendly)
		selected_ability = -1

func _on_combat_log_updated(message: String):
	log_container.text += message + "\n"
	log_container.scroll_to_line(log_container.get_line_count())

func _on_turn_started(combatant: Combatant):
	if combatant.is_player:
		update_ability_ui(combatant)
		log_container.text += "It's " + combatant.name + "'s turn!\n"
	else:
		log_container.text += "It's " + combatant.name + "'s turn (CPU)!\n"
	
	# Disable all target selection until an ability is selected
	for button in enemy_combatant_buttons + player_combatant_buttons:
		button.disabled = true

func _on_combat_ended(winner: String):
	log_container.text += "Combat has ended! " + winner + " wins!\n"
	# Disable all combat UI elements
	for button in ability_container.get_children():
		button.disabled = true