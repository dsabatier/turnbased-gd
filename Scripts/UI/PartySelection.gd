# PartySelection.gd
extends Control

signal party_selection_complete(player_team, enemy_team)

# References to UI elements
@onready var player_roster = $HBoxContainer/PlayerSection/RosterGrid
@onready var player_party = $HBoxContainer/PlayerSection/PartyContainer
@onready var enemy_roster = $HBoxContainer/EnemySection/RosterGrid
@onready var enemy_party = $HBoxContainer/EnemySection/PartyContainer
@onready var start_button = $StartButton
@onready var back_button = $BackButton

# Reference to the combatant card scene
var combatant_card_scene = preload("res://Scenes/roster_card.tscn")

# Selected combatants
var selected_player_combatants: Array[CombatantResource] = []
var selected_enemy_combatants: Array[CombatantResource] = []

# Maximum party size
const MAX_PARTY_SIZE = 4

func _ready() -> void:
	# Disable start button until valid selections are made
	start_button.disabled = true
	
	# Connect signals
	start_button.pressed.connect(_on_start_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Populate the roster grids
	_populate_player_roster()
	_populate_enemy_roster()

func _populate_player_roster() -> void:
	# Clear any existing children first
	for child in player_roster.get_children():
		child.queue_free()
	
	# Get player characters from database
	var combatants = CombatantDatabase.get_playable_combatants()
	
	# If no playable combatants, make sure demo ones are created
	if combatants.is_empty():
		CombatantDatabase._ensure_demo_combatants()
		combatants = CombatantDatabase.get_playable_combatants()
	
	for combatant in combatants:
		var card = combatant_card_scene.instantiate()
		card.initialize(combatant)
		card.pressed.connect(_on_player_card_selected.bind(card, combatant))
		player_roster.add_child(card)

func _populate_enemy_roster() -> void:
	# Clear any existing children first
	for child in enemy_roster.get_children():
		child.queue_free()
	
	# Get enemy characters from database
	var combatants = CombatantDatabase.get_enemy_combatants()
	
	# If no enemy combatants, make sure demo ones are created
	if combatants.is_empty():
		CombatantDatabase._ensure_demo_combatants()
		combatants = CombatantDatabase.get_enemy_combatants()
	
	for combatant in combatants:
		var card = combatant_card_scene.instantiate()
		card.initialize(combatant)
		card.pressed.connect(_on_enemy_card_selected.bind(card, combatant))
		enemy_roster.add_child(card)

func _on_player_card_selected(card, combatant: CombatantResource) -> void:
	if selected_player_combatants.size() >= MAX_PARTY_SIZE:
		return
	
	# Add to selected list
	selected_player_combatants.append(combatant)
	
	# Create visual representation in party container
	var party_card = combatant_card_scene.instantiate()
	party_card.initialize(combatant)
	party_card.pressed.connect(_on_player_party_card_removed.bind(party_card, combatant))
	player_party.add_child(party_card)
	
	# Disable roster card
	card.disabled = true
	
	# Update start button state
	_update_start_button()

func _on_player_party_card_removed(card, combatant: CombatantResource) -> void:
	# Remove from selected list
	var index = selected_player_combatants.find(combatant)
	if index != -1:
		selected_player_combatants.remove_at(index)
	
	# Remove card
	card.queue_free()
	
	# Re-enable roster card
	for roster_card in player_roster.get_children():
		if roster_card.combatant_resource == combatant:
			roster_card.disabled = false
			break
	
	# Update start button state
	_update_start_button()

func _on_enemy_card_selected(card, combatant: CombatantResource) -> void:
	if selected_enemy_combatants.size() >= MAX_PARTY_SIZE:
		return
	
	# Add to selected list
	selected_enemy_combatants.append(combatant)
	
	# Create visual representation in party container
	var party_card = combatant_card_scene.instantiate()
	party_card.initialize(combatant)
	party_card.pressed.connect(_on_enemy_party_card_removed.bind(party_card, combatant))
	enemy_party.add_child(party_card)
	
	# Disable roster card
	card.disabled = true
	
	# Update start button state
	_update_start_button()

func _on_enemy_party_card_removed(card, combatant: CombatantResource) -> void:
	# Remove from selected list
	var index = selected_enemy_combatants.find(combatant)
	if index != -1:
		selected_enemy_combatants.remove_at(index)
	
	# Remove card
	card.queue_free()
	
	# Re-enable roster card
	for roster_card in enemy_roster.get_children():
		if roster_card.combatant_resource == combatant:
			roster_card.disabled = false
			break
	
	# Update start button state
	_update_start_button()

func _update_start_button() -> void:
	# Enable start button only if at least one player and one enemy are selected
	start_button.disabled = selected_player_combatants.is_empty() or selected_enemy_combatants.is_empty()

func _on_start_button_pressed() -> void:
	# Save selected teams to the global TeamSelection singleton
	var team_selection = get_node("/root/TeamSelection")
	if team_selection:
		team_selection.player_team = selected_player_combatants
		team_selection.enemy_team = selected_enemy_combatants
	
	# Emit signal with selected teams
	emit_signal("party_selection_complete", selected_player_combatants, selected_enemy_combatants)
	
	# Load combat scene
	get_tree().change_scene_to_file("res://Scenes/combat.tscn")

func _on_back_button_pressed() -> void:
	# Return to main menu
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
