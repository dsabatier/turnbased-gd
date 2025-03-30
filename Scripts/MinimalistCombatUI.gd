# MinimalistCombatUI.gd
extends Control

@export var combat_system: CombatSystem

# Node references
@onready var combat_log_window = $CombatLogWindow
@onready var ability_popup = $AbilityPopup
@onready var ability_container = $AbilityPopup/AbilityContainer
@onready var ability_title = $AbilityPopup/TitleBar/TitleLabel
@onready var target_popup = $TargetPopup
@onready var target_container = $TargetPopup/TargetContainer
@onready var target_title = $TargetPopup/TitleBar/TitleLabel
@onready var log_text = $CombatLogWindow/LogText

# Player and enemy status elements
var player_status_elements = []
var enemy_status_elements = []

# Track current combat state
var selected_ability = -1
var current_combatant = null
var highlight_style = null

func _ready():
	# Connect signals from combat system
	combat_system.combat_log_updated.connect(_on_combat_log_updated)
	combat_system.turn_started.connect(_on_turn_started)
	combat_system.combat_ended.connect(_on_combat_ended)
	combat_system.combat_started.connect(_on_combat_started)
	
	# Set up log toggle button
	$LogToggleButton.pressed.connect(_toggle_combat_log)
	$CombatLogWindow/CloseButton.pressed.connect(_close_combat_log)
	
	# Create highlight style
	highlight_style = StyleBoxFlat.new()
	highlight_style.bg_color = Color(0, 0, 0, 0)  # Transparent background
	highlight_style.border_width_left = 2
	highlight_style.border_width_top = 2
	highlight_style.border_width_right = 2
	highlight_style.border_width_bottom = 2
	highlight_style.border_color = Color(1, 1, 0, 0.8)  # Yellow highlight
	
	# Initialize combatant status elements
	_initialize_status_elements()
	
	# Initialize with all popups hidden
	combat_log_window.visible = false
	ability_popup.visible = false
	target_popup.visible = false
	
	# Connect navigation buttons
	$ButtonContainer/BackToMenuButton.pressed.connect(return_to_menu)
	$ButtonContainer/BackToSelectionButton.pressed.connect(return_to_selection)
	
	log_text.text = "Waiting for combat to start...\n"

func _initialize_status_elements():
	# Initialize player status elements
	player_status_elements.clear()
	for i in range(4):  # Up to 4 players
		var element = _get_status_element("BattleArea/PlayerStatus/Player" + str(i+1))
		if element:
			player_status_elements.append(element)
	
	# Initialize enemy status elements
	enemy_status_elements.clear()
	for i in range(10):  # Up to 10 enemies
		var element = _get_status_element("BattleArea/EnemyStatus/Enemy" + str(i+1))
		if element:
			enemy_status_elements.append(element)

func _get_status_element(path):
	# Helper function to get status UI elements
	var node = get_node_or_null(path)
	if node:
		return {
			"container": node,
			"portrait": node.get_node_or_null("Portrait"),
			"name_label": node.get_node_or_null("NameLabel"),
			"hp_bar": node.get_node_or_null("HPBar"),
			"hp_label": node.get_node_or_null("HPBar/Label") if node.get_node_or_null("HPBar") else null,
			"mp_bar": node.get_node_or_null("MPBar"),
			"mp_label": node.get_node_or_null("MPBar/Label") if node.get_node_or_null("MPBar") else null,
			"status_effects": node.get_node_or_null("StatusEffects"),
			"highlight": node.get_node_or_null("Highlight"),
			"combatant": null
		}
	return null

func _on_combat_started():
	# Set up player UI
	for i in range(min(combat_system.player_combatants.size(), player_status_elements.size())):
		var element = player_status_elements[i]
		var combatant = combat_system.player_combatants[i]
		element.container.visible = true
		element.combatant = combatant
		element.name_label.text = combatant.display_name
		
		# Connect signals
		if not combatant.hp_changed.is_connected(_on_player_hp_changed):
			combatant.hp_changed.connect(_on_player_hp_changed.bind(i))
		if not combatant.mp_changed.is_connected(_on_player_mp_changed):
			combatant.mp_changed.connect(_on_player_mp_changed.bind(i))
		if not combatant.status_effect_added.is_connected(_on_player_status_changed):
			combatant.status_effect_added.connect(_on_player_status_changed.bind(i))
		if not combatant.status_effect_removed.is_connected(_on_player_status_changed):
			combatant.status_effect_removed.connect(_on_player_status_changed.bind(i))
		
		# Update display
		_update_player_status(i)
	
	# Hide unused player elements
	for i in range(combat_system.player_combatants.size(), player_status_elements.size()):
		player_status_elements[i].container.visible = false
	
	# Set up enemy UI
	for i in range(min(combat_system.cpu_combatants.size(), enemy_status_elements.size())):
		var element = enemy_status_elements[i]
		var combatant = combat_system.cpu_combatants[i]
		element.container.visible = true
		element.combatant = combatant
		element.name_label.text = combatant.display_name
		
		# Connect signals
		if not combatant.hp_changed.is_connected(_on_enemy_hp_changed):
			combatant.hp_changed.connect(_on_enemy_hp_changed.bind(i))
		if not combatant.mp_changed.is_connected(_on_enemy_mp_changed):
			combatant.mp_changed.connect(_on_enemy_mp_changed.bind(i))
		if not combatant.status_effect_added.is_connected(_on_enemy_status_changed):
			combatant.status_effect_added.connect(_on_enemy_status_changed.bind(i))
		if not combatant.status_effect_removed.is_connected(_on_enemy_status_changed):
			combatant.status_effect_removed.connect(_on_enemy_status_changed.bind(i))
		if not combatant.defeated.is_connected(_on_enemy_defeated):
			combatant.defeated.connect(_on_enemy_defeated.bind(i))
		
		# Update display
		_update_enemy_status(i)
	
	# Hide unused enemy elements
	for i in range(combat_system.cpu_combatants.size(), enemy_status_elements.size()):
		enemy_status_elements[i].container.visible = false
	
	log_text.text = "Combat started!\n"
	
	# Setup for first turn
	if combat_system.current_turn_index < combat_system.turn_order.size():
		var first_combatant = combat_system.turn_order[combat_system.current_turn_index]
		_highlight_active_combatant(first_combatant)
		
		if first_combatant.is_player:
			_show_abilities_for_combatant(first_combatant)

func _update_player_status(index):
	if index < 0 or index >= player_status_elements.size():
		return
		
	var element = player_status_elements[index]
	var combatant = element.combatant
	
	if not combatant:
		return
	
	# Update HP
	var hp_ratio = float(combatant.current_hp) / float(combatant.max_hp)
	element.hp_bar.value = hp_ratio * 100
	element.hp_label.text = str(combatant.current_hp) + "/" + str(combatant.max_hp)
	
	# Update MP
	var mp_ratio = float(combatant.current_mp) / float(combatant.max_mp) if combatant.max_mp > 0 else 0
	element.mp_bar.value = mp_ratio * 100
	element.mp_label.text = str(combatant.current_mp) + "/" + str(combatant.max_mp)
	
	# Update status effects
	_update_status_effects(combatant, element.status_effects)

func _update_enemy_status(index):
	if index < 0 or index >= enemy_status_elements.size():
		return
		
	var element = enemy_status_elements[index]
	var combatant = element.combatant
	
	if not combatant:
		return
	
	# Update HP
	var hp_ratio = float(combatant.current_hp) / float(combatant.max_hp)
	element.hp_bar.value = hp_ratio * 100
	element.hp_label.text = str(combatant.current_hp) + "/" + str(combatant.max_hp)
	
	# Update MP if exists
	if element.mp_bar and combatant.max_mp > 0:
		var mp_ratio = float(combatant.current_mp) / float(combatant.max_mp)
		element.mp_bar.value = mp_ratio * 100
		element.mp_label.text = str(combatant.current_mp) + "/" + str(combatant.max_mp)
	
	# Update status effects
	_update_status_effects(combatant, element.status_effects)

func _update_status_effects(combatant, status_container):
	# Clear existing status icons
	for child in status_container.get_children():
		child.queue_free()
	
	# Add icon for each status effect
	for effect in combatant.status_effects:
		# Determine color based on effect type
		var color = Color.WHITE
		
		match effect.trigger_type:
			StatusEffect.TriggerType.TURN_START:
				color = Color.GREEN
			StatusEffect.TriggerType.TURN_END:
				color = Color.RED
			StatusEffect.TriggerType.ON_DAMAGE_TAKEN:
				color = Color.BLUE
			StatusEffect.TriggerType.ON_HEALING_RECEIVED:
				color = Color.YELLOW
		
		# Create status effect icon
		var panel = Panel.new()
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = color
		style_box.corner_radius_top_left = 4
		style_box.corner_radius_top_right = 4
		style_box.corner_radius_bottom_left = 4
		style_box.corner_radius_bottom_right = 4
		
		panel.add_theme_stylebox_override("panel", style_box)
		panel.custom_minimum_size = Vector2(8, 8)
		panel.tooltip_text = effect.name + " (" + str(effect.remaining_turns) + " turns)"
		
		status_container.add_child(panel)

func _on_combat_log_updated(message: String):
	log_text.text += message + "\n"

func _on_turn_started(combatant: Combatant):
	current_combatant = combatant
	
	# Hide any open popups
	ability_popup.visible = false
	target_popup.visible = false
	
	# Highlight the active combatant
	_highlight_active_combatant(combatant)
	
	log_text.text += "It's " + combatant.display_name + "'s turn!\n"
	
	# If it's a player's turn, show abilities
	if combatant.is_player:
		_show_abilities_for_combatant(combatant)

func _highlight_active_combatant(combatant):
	# Clear all highlights first
	for element in player_status_elements + enemy_status_elements:
		if element.highlight:
			element.highlight.visible = false
	
	# Find and highlight the active combatant
	for i in range(player_status_elements.size()):
		if player_status_elements[i].combatant == combatant:
			var highlight = player_status_elements[i].highlight
			if highlight:
				highlight.add_theme_stylebox_override("panel", highlight_style)
				highlight.visible = true
			break
	
	for i in range(enemy_status_elements.size()):
		if enemy_status_elements[i].combatant == combatant:
			var highlight = enemy_status_elements[i].highlight
			if highlight:
				highlight.add_theme_stylebox_override("panel", highlight_style)
				highlight.visible = true
			break

func _show_abilities_for_combatant(combatant):
	# Clear existing abilities
	for child in ability_container.get_children():
		child.queue_free()
	
	# Set title
	ability_title.text = combatant.display_name + "'s Abilities"
	
	# Create button for each ability
	for i in range(combatant.abilities.size()):
		var ability = combatant.abilities[i]
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		
		# Create ability name text with MP cost if applicable
		var ability_text = ability.name
		if ability.has_method("get") and ability.get("mp_cost") != null and ability.mp_cost > 0:
			ability_text += " [MP: " + str(ability.mp_cost) + "]"
			
			# Disable button if not enough MP
			if combatant.current_mp < ability.mp_cost:
				button.disabled = true
		
		button.text = ability_text
		
		# Add description as tooltip
		button.tooltip_text = ability.description
		
		# Connect button signal
		button.pressed.connect(_on_ability_selected.bind(i))
		
		ability_container.add_child(button)
	
	# Show popup
	ability_popup.visible = true

func _on_ability_selected(index):
	selected_ability = index
	
	if current_combatant and selected_ability >= 0 and selected_ability < current_combatant.abilities.size():
		var ability = current_combatant.abilities[selected_ability]
		
		# If it's a self-targeting ability, use it immediately
		if ability.target_type == Ability.TargetType.SELF:
			combat_system.process_turn(selected_ability, current_combatant)
			ability_popup.visible = false
			selected_ability = -1
			return
		
		# Otherwise, show target selection popup
		_show_target_selection(ability)

func _show_target_selection(ability):
	# Clear existing targets
	for child in target_container.get_children():
		child.queue_free()
	
	# Build target list based on ability target type
	var targets = []
	
	match ability.target_type:
		Ability.TargetType.ENEMY:
			targets = combat_system.cpu_combatants
		Ability.TargetType.FRIENDLY:
			targets = combat_system.player_combatants
		Ability.TargetType.OTHER_FRIENDLY:
			targets = combat_system.player_combatants.filter(func(c): return c != current_combatant)
		Ability.TargetType.ANY:
			targets = combat_system.player_combatants + combat_system.cpu_combatants
	
	# Create button for each valid target
	for i in range(targets.size()):
		var target = targets[i]
		
		# Skip defeated targets
		if target.is_defeated:
			continue
		
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 40)
		button.text = target.display_name + " (" + str(target.current_hp) + "/" + str(target.max_hp) + ")"
		
		# Connect button signal
		button.pressed.connect(_on_target_selected.bind(target))
		
		target_container.add_child(button)
	
	# Show target popup only if there are valid targets
	if target_container.get_child_count() > 0:
		target_popup.visible = true
		ability_popup.visible = false
	else:
		# If no valid targets, show message
		var label = Label.new()
		label.text = "No valid targets available!"
		target_container.add_child(label)
		target_popup.visible = true
		ability_popup.visible = false

func _on_target_selected(target):
	if current_combatant and selected_ability >= 0:
		# Apply the ability to the target
		combat_system.process_turn(selected_ability, target)
		
		# Hide popups
		target_popup.visible = false
		ability_popup.visible = false
		selected_ability = -1

func _on_player_hp_changed(current_hp, max_hp, player_index):
	_update_player_status(player_index)

func _on_player_mp_changed(current_mp, max_mp, player_index):
	_update_player_status(player_index)

func _on_player_status_changed(effect, player_index):
	_update_player_status(player_index)

func _on_enemy_hp_changed(current_hp, max_hp, enemy_index):
	_update_enemy_status(enemy_index)

func _on_enemy_mp_changed(current_mp, max_mp, enemy_index):
	_update_enemy_status(enemy_index)

func _on_enemy_status_changed(effect, enemy_index):
	_update_enemy_status(enemy_index)

func _on_enemy_defeated(enemy_index):
	if enemy_index < enemy_status_elements.size():
		var element = enemy_status_elements[enemy_index]
		
		# Gray out the enemy display
		var portrait = element.portrait
		if portrait:
			portrait.modulate = Color(0.5, 0.5, 0.5, 0.7)
		
		var name_label = element.name_label
		if name_label:
			name_label.modulate = Color(0.5, 0.5, 0.5, 0.7)
		
		var hp_bar = element.hp_bar
		if hp_bar:
			hp_bar.modulate = Color(0.5, 0.5, 0.5, 0.7)

func _on_combat_ended(winner: String):
	# Hide all popups
	ability_popup.visible = false
	target_popup.visible = false
	
	# Show combat log if not visible
	combat_log_window.visible = true
	
	log_text.text += "Combat has ended! " + winner + " wins!\n"

func _toggle_combat_log():
	combat_log_window.visible = !combat_log_window.visible

func _close_combat_log():
	combat_log_window.visible = false

# Navigation functions
func return_to_menu():
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")

func return_to_selection():
	get_tree().change_scene_to_file("res://Scenes/character_selection.tscn")